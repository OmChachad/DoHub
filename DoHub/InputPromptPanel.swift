import SwiftUI

/// Collects input for a tile set to ask each time, typed or dictated, then runs the shortcut.
struct InputPromptPanel: View {
    var tile: ShortcutTile

    @Environment(ShortcutRunner.self) private var runner
    @Environment(\.openURL) private var openURL
    @State private var answer = ""
    @State private var textBeforeDictation = ""
    @State private var dictation = DictationRecorder()
    @FocusState private var isFieldFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            if !tile.inputText.isEmpty {
                Text(tile.inputText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            HStack(alignment: .bottom, spacing: 8) {
                TextField("Input", text: $answer, axis: .vertical)
                    .lineLimit(1...5)
                    .focused($isFieldFocused)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(.fill.tertiary, in: .rect(cornerRadius: 16))
                dictationButton
            }
            if let errorMessage = dictation.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Button(action: run) {
                Label("Run Shortcut", systemImage: "play.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(16)
        .hubGlass(in: .rect(cornerRadius: 28))
        .onAppear { isFieldFocused = true }
        .onChange(of: dictation.transcript) { _, transcript in
            guard !transcript.isEmpty else { return }
            let separator = textBeforeDictation.isEmpty || textBeforeDictation.hasSuffix(" ") ? "" : " "
            answer = textBeforeDictation + separator + transcript
        }
        .onDisappear {
            Task { await dictation.stop() }
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            TileIconBadge(symbolName: tile.symbolName, tint: tile.tint, dimension: 36)
            VStack(alignment: .leading, spacing: 0) {
                Text("Input for")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(tile.name)
                    .font(.headline)
                    .lineLimit(2)
            }
            Spacer(minLength: 8)
            Button("Cancel", systemImage: "xmark") {
                withAnimation(.smooth) { runner.cancelInput() }
            }
            .labelStyle(.iconOnly)
            .font(.body.weight(.semibold))
            .buttonStyle(.bordered)
            .buttonBorderShape(.circle)
        }
    }

    @ViewBuilder
    private var dictationButton: some View {
        switch dictation.phase {
        case .preparing:
            ProgressView()
                .frame(width: 44, height: 44)
                .accessibilityLabel("Preparing dictation")
        case .idle, .listening:
            let isListening = dictation.phase == .listening
            Button(isListening ? "Stop Dictation" : "Dictate", systemImage: isListening ? "stop.fill" : "microphone.fill") {
                toggleDictation()
            }
            .labelStyle(.iconOnly)
            .font(.body.weight(.semibold))
            .symbolEffect(.pulse, isActive: isListening)
            .frame(width: 44, height: 44)
            .buttonStyle(.bordered)
            .buttonBorderShape(.circle)
            .tint(isListening ? .red : nil)
            .contentTransition(.symbolEffect(.replace))
        }
    }

    private func toggleDictation() {
        if dictation.phase == .listening {
            Task { await dictation.stop() }
        } else {
            textBeforeDictation = answer
            Task { await dictation.start() }
        }
    }

    private func run() {
        Task {
            await dictation.stop()
            withAnimation(.smooth) {
                runner.submitInput(answer, openURL: openURL)
            }
        }
    }
}
