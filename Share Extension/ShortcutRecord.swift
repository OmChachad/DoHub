import Foundation

/// The name, color, and glyph of a shared shortcut, from the public iCloud Shortcuts API.
nonisolated struct ShortcutRecord: Sendable {
    var id: String
    var name: String
    var iconColor: Int64
    var iconGlyph: Int64

    static func fetch(link: String) async throws -> ShortcutRecord {
        guard let linkURL = URL(string: link),
              let apiURL = URL(string: "https://www.icloud.com/shortcuts/api/records/\(linkURL.lastPathComponent)")
        else { throw URLError(.badURL) }

        let (data, response) = try await URLSession.shared.data(from: apiURL)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        let decoded = try JSONDecoder().decode(Response.self, from: data)
        return ShortcutRecord(
            id: decoded.recordName,
            name: decoded.fields.name.value,
            iconColor: decoded.fields.icon_color.value,
            iconGlyph: decoded.fields.icon_glyph.value
        )
    }

    private struct Response: Decodable {
        var recordName: String
        var fields: Fields

        struct Fields: Decodable {
            var name: Value<String>
            var icon_color: Value<Int64>
            var icon_glyph: Value<Int64>
        }

        struct Value<T: Decodable>: Decodable {
            var value: T
        }
    }
}
