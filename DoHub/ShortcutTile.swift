import Foundation
import SwiftData

/// A shortcut pinned to the deck, with its appearance and input configuration.
@Model
final class ShortcutTile {
    /// The shortcut's name, exactly as it appears in the Shortcuts app.
    var name: String
    var symbolName: String
    var tint: TileTint
    var size: TileSize
    var inputMode: ShortcutInputMode
    /// The fixed input for `.text`, or the prompt shown for `.askEachTime`.
    var inputText: String
    var parameters: [ShortcutParameter]
    /// The hand gesture that runs this tile. Each gesture belongs to at most one tile.
    var gesture: HandGesture?
    var sortIndex: Int
    var createdAt: Date

    init(
        name: String,
        symbolName: String = "bolt.fill",
        tint: TileTint = .blue,
        size: TileSize = .wide,
        inputMode: ShortcutInputMode = .none,
        inputText: String = "",
        parameters: [ShortcutParameter] = [],
        gesture: HandGesture? = nil,
        sortIndex: Int = 0
    ) {
        self.name = name
        self.symbolName = symbolName
        self.tint = tint
        self.size = size
        self.inputMode = inputMode
        self.inputText = inputText
        self.parameters = parameters
        self.gesture = gesture
        self.sortIndex = sortIndex
        self.createdAt = .now
    }

    /// The input to send when running this tile. `answer` is the text entered for `.askEachTime`.
    func runInput(answer: String? = nil) -> ShortcutURLBuilder.Input {
        switch inputMode {
        case .none: .none
        case .clipboard: .clipboard
        case .text: inputText.isEmpty ? .none : .text(inputText)
        case .askEachTime: .text(answer ?? "")
        case .parameters: .text(ShortcutURLBuilder.parametersJSON(parameters))
        }
    }

    /// Gives `gesture` to `tile`, taking it from any other tile so each gesture runs one shortcut.
    static func assign(_ gesture: HandGesture?, to tile: ShortcutTile, in context: ModelContext) {
        if let gesture {
            let descriptor = FetchDescriptor<ShortcutTile>()
            for other in (try? context.fetch(descriptor)) ?? [] where other !== tile && other.gesture == gesture {
                other.gesture = nil
            }
        }
        tile.gesture = gesture
    }

    /// Adds tiles imported by the Share Extension to the end of the deck.
    static func insertPendingImports(into context: ModelContext) {
        let imports = TileImportQueue.drain()
        guard !imports.isEmpty else { return }
        var sortIndex = nextSortIndex(in: context)
        for tileImport in imports {
            context.insert(ShortcutTile(
                name: tileImport.name,
                symbolName: tileImport.symbolName,
                tint: tileImport.tint,
                size: tileImport.size,
                inputMode: tileImport.inputMode,
                inputText: tileImport.inputText,
                parameters: tileImport.parameters,
                sortIndex: sortIndex
            ))
            sortIndex += 1
        }
        try? context.save()
    }

    /// The sort index that places a new tile at the end of the deck.
    static func nextSortIndex(in context: ModelContext) -> Int {
        var descriptor = FetchDescriptor<ShortcutTile>(sortBy: [SortDescriptor(\.sortIndex, order: .reverse)])
        descriptor.fetchLimit = 1
        let lastIndex = (try? context.fetch(descriptor))?.first?.sortIndex ?? -1
        return lastIndex + 1
    }
}

extension ShortcutTileView {
    init(tile: ShortcutTile) {
        self.init(name: tile.name, symbolName: tile.symbolName, tint: tile.tint, size: tile.size)
    }
}
