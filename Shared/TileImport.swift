import Foundation

/// A tile prepared by the Share Extension, waiting for DoHub to add it to the deck.
nonisolated struct TileImport: Codable, Sendable {
    var name = ""
    var symbolName = "bolt.fill"
    var tint: TileTint = .blue
    var size: TileSize = .wide
    var inputMode: ShortcutInputMode = .none
    var inputText = ""
    var parameters: [ShortcutParameter] = []
}
