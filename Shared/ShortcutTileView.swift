import SwiftUI

/// The face of a deck tile. Wide tiles follow the Shortcuts app: symbol at the top
/// leading corner and the name along the bottom. Compact tiles show only the symbol.
struct ShortcutTileView: View {
    var name: String
    var symbolName: String
    var tint: TileTint
    var size: TileSize

    static let cornerRadius: CGFloat = 22

    init(name: String, symbolName: String, tint: TileTint, size: TileSize) {
        self.name = name
        self.symbolName = symbolName
        self.tint = tint
        self.size = size
    }

    var body: some View {
        content
            .foregroundStyle(tint.foregroundColor)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(tint.color.gradient, in: .rect(cornerRadius: Self.cornerRadius))
            .contentShape(.rect(cornerRadius: Self.cornerRadius))
    }

    @ViewBuilder
    private var content: some View {
        switch size {
        case .wide:
            VStack(alignment: .leading, spacing: 0) {
                Image(systemName: symbolName)
                    .font(.title2.weight(.semibold))
                    .frame(height: 28, alignment: .leading)
                Spacer(minLength: 6)
                Text(name)
                    .font(.headline)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .minimumScaleFactor(0.75)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        case .compact:
            Image(systemName: symbolName)
                .font(.title.weight(.semibold))
                .accessibilityLabel(name)
        }
    }
}
