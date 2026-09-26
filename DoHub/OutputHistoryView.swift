import SwiftData
import SwiftUI

/// Every saved shortcut output, newest first. One output at a time expands into a card.
struct OutputHistoryView: View {
    var namespace: Namespace.ID
    /// Draws rows on Liquid Glass. Turn off when the history already sits on a glass panel.
    var usesGlass = true

    @Environment(ShortcutRunner.self) private var runner
    @Query(sort: \ShortcutRunRecord.date, order: .reverse) private var records: [ShortcutRunRecord]

    var body: some View {
        if records.isEmpty {
            ContentUnavailableView {
                Label("No Outputs Yet", systemImage: "tray.fill")
            } description: {
                Text("Run a shortcut and its output appears here. To send back an image or PDF, end your shortcut with Base64 Encode.")
            }
        } else {
            list
        }
    }

    private var list: some View {
        ScrollViewReader { proxy in
            ScrollView {
                HubGlassContainer(spacing: 10) {
                    LazyVStack(spacing: 10) {
                        ForEach(records) { record in
                            item(for: record)
                                .id(record.runID)
                        }
                    }
                    .padding()
                }
            }
            .swipeActionsContainer()
            .onAppear {
                if let expandedID = runner.expandedRecordID {
                    proxy.scrollTo(expandedID, anchor: .top)
                }
            }
            .onChange(of: runner.expandedRecordID) { _, expandedID in
                guard let expandedID else { return }
                withAnimation(.smooth) {
                    proxy.scrollTo(expandedID, anchor: .top)
                }
            }
        }
    }

    @ViewBuilder
    private func item(for record: ShortcutRunRecord) -> some View {
        if record.runID == runner.expandedRecordID {
            OutputCard(record: record) {
                withAnimation(.smooth) { runner.collapse() }
            }
            .historySurface(usesGlass, in: .rect(cornerRadius: 28))
            .outputMorph(id: record.runID, in: namespace)
            .contextMenu {
                deleteButton(for: record)
            }
        } else {
            Button {
                withAnimation(.smooth) { runner.toggleExpansion(of: record) }
            } label: {
                OutputHistoryRow(record: record)
            }
            .buttonStyle(.plain)
            .accessibilityHint("Shows the full output")
            .historySurface(usesGlass, in: .rect(cornerRadius: 20), isInteractive: true)
            .outputMorph(id: record.runID, in: namespace)
            .swipeActions {
                deleteButton(for: record)
            }
            .contextMenu {
                deleteButton(for: record)
            }
        }
    }

    private func deleteButton(for record: ShortcutRunRecord) -> some View {
        Button("Delete", systemImage: "trash", role: .destructive) {
            withAnimation(.smooth) { runner.delete(record) }
        }
    }
}

private extension View {
    /// Liquid Glass, or a subtle fill when the history is already on a glass panel.
    @ViewBuilder
    func historySurface(_ usesGlass: Bool, in shape: some Shape, isInteractive: Bool = false) -> some View {
        if usesGlass {
            hubGlass(in: shape, isInteractive: isInteractive)
        } else {
            background(.fill.quaternary, in: shape)
        }
    }
}
