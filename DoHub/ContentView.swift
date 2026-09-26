import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openURL) private var openURL
    @Environment(ShortcutRunner.self) private var runner
    @Query private var tiles: [ShortcutTile]
    @Namespace private var namespace

    @State private var editorTarget: ShortcutEditorTarget?
    @State private var isEditingDeck = false
    @State private var isShowingHistory = false
    @State private var gestureRecognizer = HandGestureRecognizer()

    var body: some View {
        NavigationStack {
            Group {
                if isCompact {
                    compactLayout
                } else {
                    HubArrangementView {
                        topScreen
                            .padding()
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    } deck: {
                        deck
                    }
                }
            }
            .toolbar {
                toolbarContent
            }
        }
        .animation(.smooth, value: horizontalSizeClass)
        .onChange(of: scenePhase, initial: true) { _, phase in
            guard phase == .active else {
                gestureRecognizer.stop()
                return
            }
            // Pick up shortcuts added from the share sheet while DoHub was in the background.
            withAnimation(.smooth) {
                ShortcutTile.insertPendingImports(into: modelContext)
            }
            gestureRecognizer.onGesture = { gesture in
                runShortcut(for: gesture)
            }
            Task { await gestureRecognizer.start() }
        }
        .sheet(item: $editorTarget) { target in
            ShortcutEditorView(target: target)
        }
        #if os(iOS)
        .fullScreenCover(isPresented: isShowingFullScreenHistory) {
            OutputHistoryScreen()
                .navigationTransition(.zoom(sourceID: OutputDock.historyTransitionID, in: namespace))
        }
        #else
        .sheet(isPresented: isShowingFullScreenHistory) {
            OutputHistoryScreen()
        }
        #endif
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button(isEditingDeck ? "Done" : "Edit", systemImage: isEditingDeck ? "checkmark" : "pencil") {
                withAnimation(.smooth) { isEditingDeck.toggle() }
            }
        }
    }

    /// The outer display: the deck, with outputs and input shown above it.
    private var compactLayout: some View {
        deck
            .safeAreaInset(edge: .top) {
                topScreen
                    .padding(.horizontal)
                    .padding(.bottom, 8)
            }
    }

    private var isCompact: Bool {
        horizontalSizeClass == .compact
    }

    /// On the single outer display the history covers the screen; with two screens it
    /// expands in place on the top screen instead.
    private var isShowingFullScreenHistory: Binding<Bool> {
        Binding {
            isShowingHistory && isCompact
        } set: { isPresented in
            isShowingHistory = isPresented
        }
    }

    private var topScreen: some View {
        TopScreenContent(
            namespace: namespace,
            isHistoryExpandedInline: isShowingHistory && !isCompact,
            onOpenHistory: {
                withAnimation(.smooth) { isShowingHistory = true }
            },
            onCloseHistory: {
                withAnimation(.smooth) { isShowingHistory = false }
            }
        )
    }

    private var deck: some View {
        ShortcutDeckView(isEditing: isEditingDeck, onAdd: addShortcut, onEdit: editShortcut)
    }

    /// Runs the tile assigned to `gesture`, unless the deck or a shortcut is being edited.
    private func runShortcut(for gesture: HandGesture) {
        guard !isEditingDeck, editorTarget == nil, runner.pendingInputTile == nil,
              let tile = tiles.first(where: { $0.gesture == gesture })
        else { return }
        runner.runFromGesture(tile, openURL: openURL)
    }

    private func addShortcut() {
        editorTarget = .new
    }

    private func editShortcut(_ tile: ShortcutTile) {
        editorTarget = .edit(tile)
    }
}
