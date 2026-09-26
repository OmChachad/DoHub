import SwiftData
import SwiftUI

/// Adds a shortcut to the deck or edits an existing tile.
struct ShortcutEditorView: View {
    var target: ShortcutEditorTarget

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var tiles: [ShortcutTile]
    @State private var draft: ShortcutTileDraft
    @State private var symbolCategory: ShortcutSymbolCategory

    private static let symbolRows = Array(repeating: GridItem(.fixed(40), spacing: 8), count: 3)

    init(target: ShortcutEditorTarget) {
        self.target = target
        let draft = switch target {
        case .new: ShortcutTileDraft()
        case .edit(let tile): ShortcutTileDraft(tile: tile)
        }
        self.draft = draft
        symbolCategory = ShortcutSymbolCategory.category(containing: draft.symbolName) ?? .objects
    }

    var body: some View {
        NavigationStack {
            Form {
                headerSection
                sizeSection
                colorSection
                iconSection
                gestureSection
                InputConfigurationSection(mode: $draft.inputMode, text: $draft.inputText, parameters: $draft.parameters)
            }
            .navigationTitle(isNew ? "New Shortcut" : "Edit Shortcut")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .cancel) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(role: .confirm) {
                        save()
                    }
                    .disabled(!draft.isValid)
                }
            }
        }
    }

    private var isNew: Bool {
        if case .new = target { true } else { false }
    }

    private var headerSection: some View {
        Section {
            VStack(spacing: 20) {
                ShortcutTileView(
                    name: draft.trimmedName.isEmpty ? String(localized: "Shortcut") : draft.trimmedName,
                    symbolName: draft.symbolName,
                    tint: draft.tint,
                    size: draft.size
                )
                .frame(width: draft.size == .wide ? 200 : 92, height: 92)
                .shadow(color: draft.tint.color.opacity(0.45), radius: 10, y: 4)
                .animation(.smooth, value: draft.size)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Tile preview")

                TextField("Shortcut Name", text: $draft.name)
                    .autocorrectionDisabled()
                    .font(.headline)
                    .foregroundStyle(draft.tint.color)
                    .multilineTextAlignment(.center)
                    .submitLabel(.done)
                    .padding()
                    .background(.fill.tertiary, in: .rect(cornerRadius: 15))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        } footer: {
            Text("Enter the name exactly as it appears in the Shortcuts app.")
        }
    }

    private var sizeSection: some View {
        Section("Size") {
            Picker("Size", selection: $draft.size) {
                ForEach(TileSize.allCases) { size in
                    Text(size.title).tag(size)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
        }
    }

    private var colorSection: some View {
        Section("Color") {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 38), spacing: 8)], spacing: 8) {
                ForEach(TileTint.allCases) { tint in
                    let isSelected = draft.tint == tint
                    Button {
                        draft.tint = tint
                    } label: {
                        Circle()
                            .fill(tint.color.gradient)
                            .frame(width: 30, height: 30)
                            .padding(4)
                            .overlay {
                                Circle().stroke(.tint, lineWidth: isSelected ? 2.5 : 0)
                            }
                            .contentShape(.circle)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text(tint.title))
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
            }
            .padding(.vertical, 6)
        }
    }

    private var iconSection: some View {
        Section("Icon") {
            VStack(spacing: 12) {
                ScrollView(.horizontal) {
                    LazyHGrid(rows: Self.symbolRows, spacing: 8) {
                        ForEach(symbolCategory.symbols, id: \.self) { symbol in
                            symbolButton(symbol)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .scrollIndicators(.hidden)
                .frame(height: 136)

                Picker("Category", selection: $symbolCategory) {
                    ForEach(ShortcutSymbolCategory.allCases) { category in
                        Text(category.title).tag(category)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }
        }
    }

    private var gestureSection: some View {
        Section {
            Picker("Gesture", selection: $draft.gesture) {
                Text("None").tag(HandGesture?.none)
                ForEach(HandGesture.allCases) { gesture in
                    Label {
                        Text(gesture.title)
                    } icon: {
                        Image(systemName: gesture.symbolName)
                    }
                    .tag(Optional(gesture))
                }
            }
            .pickerStyle(.menu)
        } header: {
            Text("Gesture")
        } footer: {
            gestureFooter
        }
    }

    @ViewBuilder
    private var gestureFooter: some View {
        if let gesture = draft.gesture {
            if let owner = tileUsing(gesture) {
                Text("\(Text(gesture.instruction)) This gesture currently runs “\(owner.name)”; saving moves it here.")
            } else {
                Text("\(Text(gesture.instruction)) Hold it in front of the camera for about a second to run this shortcut.")
            }
        } else {
            Text("Run this shortcut hands-free by holding a gesture in front of the camera. Each gesture runs one shortcut.")
        }
    }

    /// The tile other than the one being edited that already uses `gesture`.
    private func tileUsing(_ gesture: HandGesture) -> ShortcutTile? {
        let editedTile: ShortcutTile? = if case .edit(let tile) = target { tile } else { nil }
        return tiles.first { $0.gesture == gesture && $0 !== editedTile }
    }

    private func symbolButton(_ symbol: String) -> some View {
        let isSelected = draft.symbolName == symbol
        return Button {
            draft.symbolName = symbol
        } label: {
            Image(systemName: symbol)
                .font(.title3)
                .foregroundStyle(isSelected ? AnyShapeStyle(draft.tint.color) : AnyShapeStyle(.secondary))
                .frame(width: 40, height: 40)
                .background(
                    isSelected ? AnyShapeStyle(draft.tint.color.opacity(0.18)) : AnyShapeStyle(.clear),
                    in: .rect(cornerRadius: 10)
                )
                .contentShape(.rect(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(Self.accessibilityName(for: symbol)))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func save() {
        switch target {
        case .new:
            let tile = draft.makeTile(sortIndex: ShortcutTile.nextSortIndex(in: modelContext))
            modelContext.insert(tile)
            ShortcutTile.assign(draft.gesture, to: tile, in: modelContext)
        case .edit(let tile):
            draft.apply(to: tile)
            ShortcutTile.assign(draft.gesture, to: tile, in: modelContext)
        }
        dismiss()
    }

    /// A readable name for a symbol, such as “cup and saucer” for `cup.and.saucer.fill`.
    private static func accessibilityName(for symbol: String) -> String {
        symbol
            .split(separator: ".")
            .filter { !["fill", "circle", "square"].contains($0) }
            .joined(separator: " ")
    }
}
