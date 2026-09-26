import SwiftUI

/// An empty deck slot. Tapping it adds a shortcut.
struct DeckPlaceholderTile: View {
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.fill.tertiary, in: .rect(cornerRadius: ShortcutTileView.cornerRadius))
                .contentShape(.rect(cornerRadius: ShortcutTileView.cornerRadius))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Add Shortcut")
    }
}
