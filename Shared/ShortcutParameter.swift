import Foundation

/// A named value sent to a shortcut as part of a JSON dictionary input.
nonisolated struct ShortcutParameter: Codable, Hashable, Identifiable, Sendable {
    var id = UUID()
    var key = ""
    var value = ""
}
