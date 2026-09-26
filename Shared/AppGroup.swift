import Foundation

/// The App Group shared by DoHub and its Share Extension.
nonisolated enum AppGroup {
    static let id = "group.devplaceholder.GZILA0VI.DoHub"

    static var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: id)
    }
}
