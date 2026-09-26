import Foundation

/// Hands tiles from the Share Extension to the app through the App Group container.
/// The extension writes one file per import; the app drains them when it becomes active.
nonisolated enum TileImportQueue {
    private static var directory: URL? {
        AppGroup.containerURL?.appending(path: "PendingImports", directoryHint: .isDirectory)
    }

    static func enqueue(_ tileImport: TileImport) throws {
        guard let directory else { throw CocoaError(.fileNoSuchFile) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let data = try JSONEncoder().encode(tileImport)
        let name = "\(Date.now.timeIntervalSince1970)-\(UUID().uuidString).json"
        try data.write(to: directory.appending(path: name), options: .atomic)
    }

    /// Removes and returns every pending import, oldest first.
    static func drain() -> [TileImport] {
        guard let directory,
              let urls = try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
        else { return [] }

        let decoder = JSONDecoder()
        return urls
            .filter { $0.pathExtension == "json" }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
            .compactMap { url in
                defer { try? FileManager.default.removeItem(at: url) }
                guard let data = try? Data(contentsOf: url) else { return nil }
                return try? decoder.decode(TileImport.self, from: data)
            }
    }
}
