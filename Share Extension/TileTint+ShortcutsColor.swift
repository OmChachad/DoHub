import Foundation

extension TileTint {
    /// The closest tint to a Shortcuts app icon color, as stored in a shortcut's `icon_color`.
    nonisolated init(shortcutsIconColor rawColor: Int64) {
        // Colors can arrive as signed 32-bit values; normalize them to unsigned.
        let color = rawColor < 0 ? Int64(UInt32(bitPattern: Int32(truncatingIfNeeded: rawColor))) : rawColor
        self = switch color {
        case 4282601983, 12365313: .red
        case 43634177, 4251333119, 4271458815, 23508481: .orange
        case 4274264319, 20702977: .yellow
        case 4292093695, 2873601: .green
        case 431817727: .teal
        case 1440408063: .cyan
        case 463140863: .blue
        case 946986751: .indigo
        case 2071128575, 3679049983, 61591313: .purple
        case 314141441, 3980825855: .pink
        case 3031607807: .mint
        case 1448498689, 2846468607: .brown
        default: .gray
        }
    }
}
