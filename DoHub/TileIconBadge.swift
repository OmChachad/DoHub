import SwiftUI

/// A tile's symbol on its tint, used to identify a shortcut in the output history.
struct TileIconBadge: View {
    var symbolName: String
    var tint: TileTint
    var dimension: CGFloat = 32

    var body: some View {
        Image(systemName: symbolName)
            .font(.system(size: dimension * 0.48, weight: .semibold))
            .foregroundStyle(tint.foregroundColor)
            .frame(width: dimension, height: dimension)
            .background(tint.color.gradient, in: .rect(cornerRadius: dimension * 0.28))
            .accessibilityHidden(true)
    }
}
