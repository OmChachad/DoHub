import SwiftData
import SwiftUI

/// The grid of shortcut tiles. Tap a tile to run it; drag to reorder. While editing, or
/// when the deck is empty, gray placeholder tiles fill the empty slots for adding shortcuts.
struct ShortcutDeckView: View {
    var isEditing: Bool
    var onAdd: () -> Void
    var onEdit: (ShortcutTile) -> Void

    @Environment(ShortcutRunner.self) private var runner
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openURL) private var openURL
    @Query(sort: \ShortcutTile.sortIndex) private var tiles: [ShortcutTile]

    @State private var runCount = 0
    @State private var visibleSize: CGSize = .zero

    private static let padding: CGFloat = 16

    var body: some View {
        let tileSpans = tiles.map(\.size.columnSpan)
        let placeholders = placeholderCount(after: tileSpans)
        ScrollView {
            DeckLayout(spans: tileSpans + Array(repeating: 1, count: placeholders)) {
                ForEach(tiles) { tile in
                    DeckTileCell(
                        tile: tile,
                        isEditing: isEditing,
                        onRun: { run(tile) },
                        onEdit: { onEdit(tile) },
                        onDelete: { delete(tile) }
                    )
                    .jiggle(isEditing)
                }
                .reorderable()

                ForEach(0..<placeholders, id: \.self) { _ in
                    DeckPlaceholderTile(action: onAdd)
                        .transition(.scale(scale: 0.8).combined(with: .opacity))
                }
            }
            .reorderContainer(for: ShortcutTile.self) { difference in
                reorder(difference)
            }
            .animation(.smooth, value: isEditing)
            .animation(.smooth, value: placeholders)
            .padding(Self.padding)
        }
        .onGeometryChange(for: CGSize.self) { $0.size } action: { visibleSize = $0 }
        .sensoryFeedback(.impact(weight: .medium), trigger: runCount)
    }

    private func placeholderCount(after tileSpans: [Int]) -> Int {
        guard isEditing || tiles.isEmpty else { return 0 }
        return DeckLayout(spans: tileSpans).placeholderCount(
            after: tileSpans,
            width: visibleSize.width - Self.padding * 2,
            visibleHeight: visibleSize.height - Self.padding * 2
        )
    }

    private func run(_ tile: ShortcutTile) {
        if tile.inputMode == .askEachTime {
            withAnimation(.smooth) { runner.requestInput(for: tile) }
            return
        }
        runCount += 1
        runner.run(tile, openURL: openURL)
    }

    private func delete(_ tile: ShortcutTile) {
        withAnimation(.smooth) {
            if runner.pendingInputTile == tile {
                runner.cancelInput()
            }
            modelContext.delete(tile)
        }
    }

    private func reorder(_ difference: ReorderDifference<ShortcutTile.ID, ReorderableSingleCollectionIdentifier>) {
        let moving = Set(difference.sources)
        var ordered = tiles.filter { !moving.contains($0.id) }
        let moved = tiles.filter { moving.contains($0.id) }
        let index = switch difference.destination.position {
        case .before(let id): ordered.firstIndex { $0.id == id } ?? ordered.endIndex
        case .end: ordered.endIndex
        }
        ordered.insert(contentsOf: moved, at: index)
        for (position, tile) in ordered.enumerated() where tile.sortIndex != position {
            tile.sortIndex = position
        }
    }
}
