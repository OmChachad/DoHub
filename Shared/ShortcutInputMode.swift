import Foundation

/// What a tile sends to its shortcut as input when it runs.
nonisolated enum ShortcutInputMode: String, Codable, CaseIterable, Identifiable, Sendable {
    case none
    case clipboard
    case text
    case askEachTime
    case parameters

    var id: Self { self }

    var title: LocalizedStringResource {
        switch self {
        case .none: "None"
        case .clipboard: "Clipboard"
        case .text: "Text"
        case .askEachTime: "Ask Each Time"
        case .parameters: "Parameters"
        }
    }

    var footer: LocalizedStringResource {
        switch self {
        case .none: "The shortcut runs without any input."
        case .clipboard: "The shortcut receives whatever is on the clipboard."
        case .text: "This text is sent as the shortcut’s input."
        case .askEachTime: "DoHub asks for the input each time you tap the tile. The prompt appears in that alert."
        case .parameters: "Sent as a dictionary. In your shortcut, use Get Dictionary from Input to read each value by its key."
        }
    }
}
