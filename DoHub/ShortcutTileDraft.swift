import Foundation

/// An editable copy of a tile's settings, so cancelling the editor leaves the store untouched.
struct ShortcutTileDraft {
    var name = ""
    var symbolName = "bolt.fill"
    var tint: TileTint = .blue
    var size: TileSize = .wide
    var inputMode: ShortcutInputMode = .none
    var inputText = ""
    var parameters: [ShortcutParameter] = []
    var gesture: HandGesture?

    init() {}

    init(tile: ShortcutTile) {
        name = tile.name
        symbolName = tile.symbolName
        tint = tile.tint
        size = tile.size
        inputMode = tile.inputMode
        inputText = tile.inputText
        parameters = tile.parameters
        gesture = tile.gesture
    }

    var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var isValid: Bool {
        !trimmedName.isEmpty
    }

    func apply(to tile: ShortcutTile) {
        tile.name = trimmedName
        tile.symbolName = symbolName
        tile.tint = tint
        tile.size = size
        tile.inputMode = inputMode
        tile.inputText = inputText
        tile.parameters = parameters
    }

    func makeTile(sortIndex: Int) -> ShortcutTile {
        let tile = ShortcutTile(name: trimmedName, sortIndex: sortIndex)
        apply(to: tile)
        return tile
    }
}
