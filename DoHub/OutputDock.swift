import SwiftData
import SwiftUI

/// Shows a new output for a few seconds, then morphs it into the output history button.
/// On the top screen, the button also expands into the history itself.
struct OutputDock: View {
    /// The zoom transition source for presenting the full output history.
    static let historyTransitionID = "output-history"
    private static let morphID = "output-dock"

    var namespace: Namespace.ID
    /// Whether the history is expanded in place, in the space this dock occupies.
    var isHistoryExpandedInline: Bool
    var onOpenHistory: () -> Void
    var onCloseHistory: () -> Void

    @Environment(ShortcutRunner.self) private var runner
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOverEnabled
    @Environment(\.scenePhase) private var scenePhase
    @Query(ShortcutRunRecord.latestDescriptor) private var latestRecords: [ShortcutRunRecord]

    var body: some View {
        HubGlassContainer(spacing: 24) {
            if isHistoryExpandedInline {
                OutputHistoryPanel(onClose: onCloseHistory)
                    .hubGlass(in: .rect(cornerRadius: 32))
                    .outputMorph(id: Self.morphID, in: namespace)
            } else if let latest = latestRecords.first {
                if runner.newOutputID == latest.runID {
                    OutputCard(record: latest, isCompact: true) {
                        minimize()
                    }
                    .hubGlass(in: .rect(cornerRadius: 28), isInteractive: true)
                    .outputMorph(id: Self.morphID, in: namespace)
                    .onTapGesture {
                        open(latest)
                    }
                    .accessibilityAction(named: "Show in Output History") {
                        open(latest)
                    }
                } else {
                    HStack {
                        Spacer(minLength: 0)
                        historyButton
                    }
                }
            }
        }
        // Start the countdown only once DoHub is back in front after running the shortcut.
        .task(id: ToastTimerID(outputID: runner.newOutputID, isActive: scenePhase == .active)) {
            guard runner.newOutputID != nil, scenePhase == .active else { return }
            if let latest = latestRecords.first {
                AccessibilityNotification.Announcement("\(latest.shortcutName): \(latest.previewText)").post()
            }
            try? await Task.sleep(for: .seconds(voiceOverEnabled ? 10 : 3))
            guard !Task.isCancelled else { return }
            minimize()
        }
    }

    private var historyButton: some View {
        Button(action: onOpenHistory) {
            Label("Output History", systemImage: "clock.arrow.trianglehead.counterclockwise.rotate.90")
                .labelStyle(.iconOnly)
                .font(.title3.weight(.semibold))
                .frame(width: 48, height: 48)
                .contentShape(.circle)
        }
        .buttonStyle(.plain)
        .hubGlass(in: .circle, isInteractive: true)
        .outputMorph(id: Self.morphID, in: namespace)
        .matchedTransitionSource(id: Self.historyTransitionID, in: namespace)
    }

    private func minimize() {
        withAnimation(.smooth) { runner.dismissNewOutput() }
    }

    private func open(_ record: ShortcutRunRecord) {
        runner.expandedRecordID = record.runID
        minimize()
        onOpenHistory()
    }
}

/// Restarts the new-output countdown when the output changes or the scene becomes active.
private struct ToastTimerID: Hashable {
    var outputID: UUID?
    var isActive: Bool
}
