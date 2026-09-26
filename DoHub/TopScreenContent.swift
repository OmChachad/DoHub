import SwiftData
import SwiftUI

/// What appears above the deck: new outputs and the history button, plus the input panel
/// for tiles that ask each time. On the inner display this is the top screen, which is
/// otherwise left empty for the music and camera views to come.
struct TopScreenContent: View {
    var namespace: Namespace.ID
    var isHistoryExpandedInline: Bool
    var onOpenHistory: () -> Void
    var onCloseHistory: () -> Void

    @Environment(ShortcutRunner.self) private var runner

    var body: some View {
        VStack(spacing: 12) {
            if let tile = runner.gestureTriggeredTile {
                GestureTriggerFlash(tile: tile)
                    .transition(AnyTransition(.blurReplace).combined(with: .scale(scale: 0.9)))
            }
            OutputDock(
                namespace: namespace,
                isHistoryExpandedInline: isHistoryExpandedInline,
                onOpenHistory: onOpenHistory,
                onCloseHistory: onCloseHistory
            )
            if let tile = runner.pendingInputTile {
                InputPromptPanel(tile: tile)
                    .id(tile.persistentModelID)
                    .transition(.blurReplace.combined(with: .move(edge: .top)))
            }
        }
    }
}
