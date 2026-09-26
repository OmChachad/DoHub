import SwiftData

/// What the shortcut editor sheet is editing.
enum ShortcutEditorTarget: Identifiable {
    case new
    case edit(ShortcutTile)

    var id: AnyHashable {
        switch self {
        case .new: AnyHashable("new")
        case .edit(let tile): AnyHashable(tile.persistentModelID)
        }
    }
}
