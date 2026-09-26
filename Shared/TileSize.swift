import Foundation

/// The footprint of a tile in the Shortcuts deck.
nonisolated enum TileSize: String, Codable, CaseIterable, Identifiable, Sendable {
    /// Two cells wide, like a tile in the Shortcuts app.
    case wide
    /// A single square cell.
    case compact

    var id: Self { self }

    var title: LocalizedStringResource {
        switch self {
        case .wide: "Wide"
        case .compact: "Compact"
        }
    }

    /// The number of deck columns the tile spans.
    var columnSpan: Int {
        switch self {
        case .wide: 2
        case .compact: 1
        }
    }
}
