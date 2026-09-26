import SwiftUI

/// Lays out deck tiles in a grid of square cells, row by row in their stored order.
/// Wide tiles span two cells and wrap to the next row when they don't fit.
struct DeckLayout: Layout {
    /// The number of columns each subview spans, in subview order. Passed explicitly
    /// because layout values don't survive the wrapping `reorderable()` applies.
    var spans: [Int]
    var minimumCellSize: CGFloat = 76
    var spacing: CGFloat = 12

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.replacingUnspecifiedDimensions().width
        return CGSize(width: width, height: frames(count: subviews.count, width: width).height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let frames = frames(count: subviews.count, width: bounds.width).frames
        for (subview, frame) in zip(subviews, frames) {
            subview.place(
                at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY),
                anchor: .topLeading,
                proposal: ProposedViewSize(frame.size)
            )
        }
    }

    /// How many single-cell placeholders fill out the last row and the rest of the visible
    /// area after tiles with `tileSpans`, always leaving at least one empty row.
    func placeholderCount(after tileSpans: [Int], width: CGFloat, visibleHeight: CGFloat) -> Int {
        guard width > 0 else { return 0 }
        let columns = columnCount(for: width)
        let cell = cellSize(for: width, columns: columns)
        let (rowsUsed, nextColumn) = packing(of: tileSpans, columns: columns)
        let openCellsInLastRow = nextColumn == 0 ? 0 : columns - nextColumn
        let visibleRows = max(1, Int((visibleHeight + spacing) / (cell + spacing)))
        let emptyRows = max(openCellsInLastRow == 0 ? 1 : 0, visibleRows - rowsUsed)
        return openCellsInLastRow + emptyRows * columns
    }

    /// An even number of columns, so the grid divides cleanly around the fold.
    private func columnCount(for width: CGFloat) -> Int {
        let fitting = Int((width + spacing) / (minimumCellSize + spacing))
        return max(4, fitting - fitting % 2)
    }

    private func cellSize(for width: CGFloat, columns: Int) -> CGFloat {
        max(0, (width - spacing * CGFloat(columns - 1)) / CGFloat(columns))
    }

    private func span(at index: Int, columns: Int) -> Int {
        let requested = spans.indices.contains(index) ? spans[index] : 1
        return min(max(requested, 1), columns)
    }

    /// The rows `spans` occupy and the column the next cell would start at.
    private func packing(of spans: [Int], columns: Int) -> (rows: Int, nextColumn: Int) {
        guard !spans.isEmpty else { return (0, 0) }
        var column = 0
        var row = 0
        for requested in spans {
            let span = min(max(requested, 1), columns)
            if column + span > columns {
                column = 0
                row += 1
            }
            column += span
        }
        return (row + 1, column == columns ? 0 : column)
    }

    private func frames(count: Int, width: CGFloat) -> (frames: [CGRect], height: CGFloat) {
        guard count > 0 else { return ([], 0) }
        let columns = columnCount(for: width)
        let cell = cellSize(for: width, columns: columns)

        var frames: [CGRect] = []
        var column = 0
        var row = 0
        for index in 0..<count {
            let span = span(at: index, columns: columns)
            if column + span > columns {
                column = 0
                row += 1
            }
            frames.append(CGRect(
                x: CGFloat(column) * (cell + spacing),
                y: CGFloat(row) * (cell + spacing),
                width: CGFloat(span) * cell + CGFloat(span - 1) * spacing,
                height: cell
            ))
            column += span
        }
        let rows = CGFloat(row + 1)
        return (frames, rows * cell + (rows - 1) * spacing)
    }
}
