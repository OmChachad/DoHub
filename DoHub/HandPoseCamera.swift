#if os(iOS)
import AVFoundation
import Vision

/// Runs the front camera without a preview and reports hand-pose features about five
/// times a second. Capture and Vision work happen on background queues.
nonisolated final class HandPoseCamera: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, @unchecked Sendable {
    /// Called on the main actor with each analyzed frame's features, or `nil` when no hand is visible.
    var onFeatures: (@MainActor ([Double]?) -> Void)?

    private let session = AVCaptureSession()
    private let output = AVCaptureVideoDataOutput()
    private let sessionQueue = DispatchQueue(label: "DoHub.camera-session")
    private let analysisQueue = DispatchQueue(label: "DoHub.hand-analysis")
    private let handPoseRequest: VNDetectHumanHandPoseRequest = {
        let request = VNDetectHumanHandPoseRequest()
        request.maximumHandCount = 1
        return request
    }()
    private var isConfigured = false
    private var lastAnalysis = 0.0

    /// Starts the camera. Returns `false` if camera access isn't allowed or there's no front camera.
    func start() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            break
        case .notDetermined:
            guard await AVCaptureDevice.requestAccess(for: .video) else { return false }
        default:
            return false
        }
        guard AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) != nil else {
            return false
        }
        sessionQueue.async { [self] in
            configureIfNeeded()
            if isConfigured, !session.isRunning {
                session.startRunning()
            }
        }
        return true
    }

    func stop() {
        sessionQueue.async { [self] in
            if session.isRunning {
                session.stopRunning()
            }
        }
    }

    private func configureIfNeeded() {
        guard !isConfigured,
              let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let input = try? AVCaptureDeviceInput(device: device)
        else { return }

        session.beginConfiguration()
        defer { session.commitConfiguration() }
        session.sessionPreset = .medium
        guard session.canAddInput(input) else { return }
        session.addInput(input)

        output.alwaysDiscardsLateVideoFrames = true
        output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        output.setSampleBufferDelegate(self, queue: analysisQueue)
        guard session.canAddOutput(output) else { return }
        session.addOutput(output)
        isConfigured = true
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let now = ProcessInfo.processInfo.systemUptime
        guard now - lastAnalysis >= 0.2 else { return }
        lastAnalysis = now

        var features: [Double]?
        let handler = VNImageRequestHandler(cmSampleBuffer: sampleBuffer, orientation: .up)
        if (try? handler.perform([handPoseRequest])) != nil, let observation = handPoseRequest.results?.first {
            features = HandPoseFeatures.vector(from: observation)
        }
        let result = features
        Task { @MainActor [onFeatures] in
            onFeatures?(result)
        }
    }
}
#endif
