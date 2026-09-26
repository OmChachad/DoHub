import SwiftData
import SwiftUI

/// Runs shortcuts through the Shortcuts URL scheme and records their callback output.
@Observable
final class ShortcutRunner {
    /// The output expanded into a card in the history. `nil` when every output is collapsed.
    var expandedRecordID: UUID?
    /// A just-arrived output, shown briefly before it minimizes into the history button.
    var newOutputID: UUID?
    /// The tile waiting for input before it runs, for tiles set to ask each time.
    var pendingInputTile: ShortcutTile?
    /// The tile a recognized gesture is about to run, shown briefly on the top screen.
    var gestureTriggeredTile: ShortcutTile?

    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    /// Opens Shortcuts to run `tile`. `answer` is the text entered for `.askEachTime` input.
    func run(_ tile: ShortcutTile, answer: String? = nil, openURL: OpenURLAction) {
        let runID = UUID()
        let name = tile.name
        let symbolName = tile.symbolName
        let tint = tile.tint
        let callbackContext = [
            "run": runID.uuidString,
            "name": name,
            "symbol": symbolName,
            "tint": tint.rawValue,
        ]

        guard let url = ShortcutURLBuilder.runURL(
            shortcutName: name,
            input: tile.runInput(answer: answer),
            context: callbackContext
        ) else {
            recordFailure(runID: runID, name: name, symbolName: symbolName, tint: tint,
                          message: String(localized: "DoHub couldn’t create a link to run this shortcut."))
            return
        }

        openURL(url) { [weak self] accepted in
            guard !accepted else { return }
            self?.recordFailure(runID: runID, name: name, symbolName: symbolName, tint: tint,
                                message: String(localized: "Couldn’t open the Shortcuts app."))
        }
    }

    /// Flashes `tile` on the top screen, then runs it (or asks for its input).
    func runFromGesture(_ tile: ShortcutTile, openURL: OpenURLAction) {
        guard gestureTriggeredTile == nil else { return }
        withAnimation(.smooth) { gestureTriggeredTile = tile }
        Task {
            try? await Task.sleep(for: .seconds(1.2))
            withAnimation(.smooth) { gestureTriggeredTile = nil }
            guard tile.modelContext != nil else { return }
            if tile.inputMode == .askEachTime {
                withAnimation(.smooth) { requestInput(for: tile) }
            } else {
                run(tile, openURL: openURL)
            }
        }
    }

    func requestInput(for tile: ShortcutTile) {
        pendingInputTile = tile
    }

    func cancelInput() {
        pendingInputTile = nil
    }

    /// Runs the tile waiting for input with `answer`.
    func submitInput(_ answer: String, openURL: OpenURLAction) {
        guard let tile = pendingInputTile else { return }
        pendingInputTile = nil
        run(tile, answer: answer, openURL: openURL)
    }

    /// Records the output of a DoHub x-callback URL. Returns `false` for any other URL.
    @discardableResult
    func handleCallback(_ url: URL) -> Bool {
        guard let callback = ShortcutURLBuilder.callback(from: url) else { return false }
        let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        func value(_ name: String) -> String? {
            items.first { $0.name == name }?.value
        }

        let record = ShortcutRunRecord(
            runID: value("run").flatMap(UUID.init(uuidString:)) ?? UUID(),
            shortcutName: value("name") ?? String(localized: "Shortcut"),
            symbolName: value("symbol") ?? "bolt.fill",
            tint: value("tint").flatMap(TileTint.init(rawValue:)) ?? .blue,
            outcome: callback.outcome,
            output: value("result"),
            errorMessage: value("errorMessage")
        )
        insert(record)
        return true
    }

    func toggleExpansion(of record: ShortcutRunRecord) {
        expandedRecordID = expandedRecordID == record.runID ? nil : record.runID
    }

    func collapse() {
        expandedRecordID = nil
    }

    func dismissNewOutput() {
        newOutputID = nil
    }

    func delete(_ record: ShortcutRunRecord) {
        if expandedRecordID == record.runID {
            expandedRecordID = nil
        }
        if newOutputID == record.runID {
            newOutputID = nil
        }
        context.delete(record)
        try? context.save()
    }

    func clearHistory() {
        expandedRecordID = nil
        newOutputID = nil
        try? context.delete(model: ShortcutRunRecord.self)
        try? context.save()
    }

    private func recordFailure(runID: UUID, name: String, symbolName: String, tint: TileTint, message: String) {
        insert(ShortcutRunRecord(runID: runID, shortcutName: name, symbolName: symbolName, tint: tint,
                                 outcome: .failed, errorMessage: message))
    }

    private func insert(_ record: ShortcutRunRecord) {
        context.insert(record)
        try? context.save()
        newOutputID = record.runID
    }
}
