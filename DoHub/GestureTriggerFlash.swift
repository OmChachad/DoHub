import SwiftData
import SwiftUI

/// Briefly shows the tile a gesture is about to run, with a soft pulse.
struct GestureTriggerFlash: View {
    var tile: ShortcutTile

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 10) {
            ShortcutTileView(name: tile.name, symbolName: tile.symbolName, tint: tile.tint, size: .wide)
                .frame(width: 200, height: 92)
                .phaseAnimator([false, true]) { content, isPulsed in
                    content
                        .scaleEffect(isPulsed && !reduceMotion ? 1.05 : 1)
                        .shadow(color: tile.tint.color.opacity(isPulsed ? 0.6 : 0.2), radius: isPulsed ? 18 : 6)
                } animation: { _ in
                    .smooth(duration: 0.5)
                }

            if let gesture = tile.gesture {
                Label {
                    Text(gesture.title)
                } icon: {
                    Image(systemName: gesture.symbolName)
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .sensoryFeedback(.impact(weight: .medium), trigger: tile.persistentModelID)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Running \(tile.name)")
        .onAppear {
            AccessibilityNotification.Announcement("Running \(tile.name)").post()
        }
    }
}
