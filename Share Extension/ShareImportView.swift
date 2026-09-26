import SwiftShortcuts
import SwiftUI

/// Previews a shared shortcut and asks how it should run from the deck before adding it.
struct ShareImportView: View {
    @Bindable var model: ShareImportModel

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Add to DoHub")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(role: .cancel) {
                            model.cancel()
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Add", systemImage: "plus") {
                            model.add()
                        }
                        .disabled(!isReady)
                    }
                }
        }
    }

    private var isReady: Bool {
        if case .ready = model.phase { true } else { false }
    }

    @ViewBuilder
    private var content: some View {
        switch model.phase {
        case .loading:
            ProgressView("Loading Shortcut…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .failed(let message):
            ContentUnavailableView {
                Label("Can’t Add Shortcut", systemImage: "exclamationmark.triangle.fill")
            } description: {
                Text(message)
            }
        case .ready(let link):
            Form {
                Section {
                    VStack(spacing: 12) {
                        ShortcutTileView(
                            name: model.draft.name,
                            symbolName: model.draft.symbolName,
                            tint: model.draft.tint,
                            size: model.draft.size
                        )
                        .frame(width: model.draft.size == .wide ? 200 : 92, height: 92)
                        .shadow(color: model.draft.tint.color.opacity(0.45), radius: 10, y: 4)
                        .animation(.smooth, value: model.draft.size)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("Tile preview for \(model.draft.name)")

                        Picker("Size", selection: $model.draft.size) {
                            ForEach(TileSize.allCases) { size in
                                Text(size.title).tag(size)
                            }
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                } footer: {
                    Text("DoHub uses this shortcut’s name, color, and icon. You can change them later.")
                }

                InputConfigurationSection(
                    mode: $model.draft.inputMode,
                    text: $model.draft.inputText,
                    parameters: $model.draft.parameters
                )

                Section("Actions") {
                    ShortcutActionsView(url: link)
                        .listRowInsets(EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12))
                }
            }
        }
    }
}
