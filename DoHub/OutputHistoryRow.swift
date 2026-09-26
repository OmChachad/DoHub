import SwiftUI

/// A collapsed output in the history: which shortcut ran, a one-line preview, and when.
struct OutputHistoryRow: View {
    var record: ShortcutRunRecord

    var body: some View {
        HStack(spacing: 12) {
            TileIconBadge(symbolName: record.symbolName, tint: record.tint)
            VStack(alignment: .leading, spacing: 2) {
                Text(record.shortcutName)
                    .font(.subheadline.weight(.semibold))
                Text(record.previewText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .lineLimit(1)
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 2) {
                Image(systemName: record.outcome.symbolName)
                    .foregroundStyle(record.outcome.color)
                    .accessibilityLabel(Text(record.outcome.title))
                Text(record.date, format: .relative(presentation: .named, unitsStyle: .abbreviated))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(.rect(cornerRadius: 20))
    }
}
