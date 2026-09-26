import AVFoundation
import OSLog
import Speech

/// Live, on-device dictation with SpeechAnalyzer. Uses `SpeechTranscriber` where the device
/// supports it and falls back to `DictationTranscriber`, the model behind keyboard dictation.
@Observable
final class DictationRecorder {
    enum Phase: Equatable {
        case idle
        case preparing
        case listening
    }

    private(set) var phase: Phase = .idle
    private(set) var finalizedText = ""
    private(set) var volatileText = ""
    private(set) var errorMessage: String?

    /// Everything heard so far, including words that may still be revised.
    var transcript: String { finalizedText + volatileText }

    private static let logger = Logger(subsystem: "DoHub", category: "Dictation")

    @ObservationIgnored private let audioEngine = AVAudioEngine()
    @ObservationIgnored private var analyzer: SpeechAnalyzer?
    @ObservationIgnored private var inputContinuation: AsyncStream<AnalyzerInput>.Continuation?
    @ObservationIgnored private var resultsTask: Task<Void, Never>?

    func start() async {
        guard phase == .idle else { return }
        phase = .preparing
        finalizedText = ""
        volatileText = ""
        errorMessage = nil

        do {
            guard await AVAudioApplication.requestRecordPermission() else {
                throw DictationError.microphoneDenied
            }
            let module = try await makeTranscriber()
            let modules: [any SpeechModule] = [module]
            if let request = try await AssetInventory.assetInstallationRequest(supporting: modules) {
                try await request.downloadAndInstall()
            }
            guard let format = await SpeechAnalyzer.bestAvailableAudioFormat(compatibleWith: modules) else {
                Self.logger.error("No audio format is compatible with the transcriber.")
                throw DictationError.unavailable
            }

            let (stream, continuation) = AsyncStream.makeStream(of: AnalyzerInput.self)
            inputContinuation = continuation
            let analyzer = SpeechAnalyzer(modules: modules)
            self.analyzer = analyzer
            try await analyzer.start(inputSequence: stream)
            try startAudio(convertingTo: format, continuation: continuation)
            phase = .listening
        } catch {
            Self.logger.error("Dictation couldn’t start: \(String(describing: error), privacy: .public)")
            errorMessage = (error as? DictationError)?.message
                ?? String(localized: "Dictation isn’t available right now. Use the dictation key on the keyboard instead.")
            await tearDown()
        }
    }

    /// Stops listening and waits for the last words to be finalized.
    func stop() async {
        guard phase != .idle else { return }
        stopAudio()
        inputContinuation?.finish()
        inputContinuation = nil
        try? await analyzer?.finalizeAndFinishThroughEndOfInput()
        await resultsTask?.value
        finalizedText += volatileText
        volatileText = ""
        await tearDown()
    }

    private func makeTranscriber() async throws -> any SpeechModule {
        if SpeechTranscriber.isAvailable,
           let locale = await SpeechTranscriber.supportedLocale(equivalentTo: .current) {
            let transcriber = SpeechTranscriber(locale: locale, preset: .progressiveTranscription)
            resultsTask = Task { [weak self] in
                do {
                    for try await result in transcriber.results {
                        self?.receive(result.text, isFinal: result.isFinal)
                    }
                } catch {}
            }
            return transcriber
        }

        guard let locale = await DictationTranscriber.supportedLocale(equivalentTo: .current) else {
            throw DictationError.unsupportedLanguage
        }
        let transcriber = DictationTranscriber(locale: locale, preset: .progressiveShortDictation)
        resultsTask = Task { [weak self] in
            do {
                for try await result in transcriber.results {
                    self?.receive(result.text, isFinal: result.isFinal)
                }
            } catch {}
        }
        return transcriber
    }

    private func receive(_ text: AttributedString, isFinal: Bool) {
        let string = String(text.characters)
        if isFinal {
            finalizedText += string
            volatileText = ""
        } else {
            volatileText = string
        }
    }

    private func startAudio(convertingTo format: AVAudioFormat, continuation: AsyncStream<AnalyzerInput>.Continuation) throws {
        #if os(iOS) || os(visionOS)
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .spokenAudio, options: [.duckOthers, .defaultToSpeaker])
        try session.setActive(true, options: .notifyOthersOnDeactivation)
        #endif
        let input = audioEngine.inputNode
        let inputFormat = input.outputFormat(forBus: 0)
        guard let converter = AVAudioConverter(from: inputFormat, to: format) else {
            Self.logger.error("Can’t convert microphone audio from \(inputFormat, privacy: .public) to \(format, privacy: .public).")
            throw DictationError.unavailable
        }
        Self.installTap(on: input, format: inputFormat, converter: converter, outputFormat: format, continuation: continuation)
        audioEngine.prepare()
        try audioEngine.start()
    }

    /// Installs the microphone tap outside the main actor, since audio arrives on a real-time thread.
    private nonisolated static func installTap(
        on input: AVAudioInputNode,
        format: AVAudioFormat,
        converter: AVAudioConverter,
        outputFormat: AVAudioFormat,
        continuation: AsyncStream<AnalyzerInput>.Continuation
    ) {
        converter.primeMethod = .none
        input.installTap(onBus: 0, bufferSize: 4096, format: format) { buffer, _ in
            guard let converted = convert(buffer, using: converter, to: outputFormat) else { return }
            continuation.yield(AnalyzerInput(buffer: converted))
        }
    }

    private nonisolated static func convert(_ buffer: AVAudioPCMBuffer, using converter: AVAudioConverter, to format: AVAudioFormat) -> AVAudioPCMBuffer? {
        if buffer.format == format {
            return buffer
        }
        let ratio = format.sampleRate / buffer.format.sampleRate
        let capacity = AVAudioFrameCount((Double(buffer.frameLength) * ratio).rounded(.up))
        guard let output = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: capacity) else { return nil }
        let source = ConversionSource(buffer: buffer)
        var error: NSError?
        converter.convert(to: output, error: &error) { _, status in
            source.next(status: status)
        }
        return error == nil ? output : nil
    }

    private func stopAudio() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
    }

    private func tearDown() async {
        stopAudio()
        inputContinuation?.finish()
        inputContinuation = nil
        await analyzer?.cancelAndFinishNow()
        analyzer = nil
        resultsTask = nil
        #if os(iOS) || os(visionOS)
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        #endif
        phase = .idle
    }
}

/// Hands a single buffer to an `AVAudioConverter`, then reports that no more data is available.
private nonisolated final class ConversionSource: @unchecked Sendable {
    private var buffer: AVAudioPCMBuffer?

    init(buffer: AVAudioPCMBuffer) {
        self.buffer = buffer
    }

    func next(status: UnsafeMutablePointer<AVAudioConverterInputStatus>) -> AVAudioBuffer? {
        guard let buffer else {
            status.pointee = .noDataNow
            return nil
        }
        self.buffer = nil
        status.pointee = .haveData
        return buffer
    }
}

private enum DictationError: Error {
    case microphoneDenied
    case unsupportedLanguage
    case unavailable

    var message: String {
        switch self {
        case .microphoneDenied:
            String(localized: "DoHub needs microphone access to dictate. You can allow it in Settings.")
        case .unsupportedLanguage:
            String(localized: "Dictation doesn’t support your language yet. Use the dictation key on the keyboard instead.")
        case .unavailable:
            String(localized: "Dictation isn’t available on this device. Use the dictation key on the keyboard instead.")
        }
    }
}
