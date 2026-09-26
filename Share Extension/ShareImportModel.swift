import SwiftShortcuts
import SwiftUI
import UniformTypeIdentifiers

/// Reads the shared iCloud shortcut link, fetches the shortcut's name, color, and icon,
/// and queues the configured tile for DoHub.
@Observable
final class ShareImportModel {
    enum Phase {
        case loading
        case ready(link: String)
        case failed(String)
    }

    private(set) var phase: Phase = .loading
    var draft = TileImport()

    @ObservationIgnored private weak var extensionContext: NSExtensionContext?

    init(extensionContext: NSExtensionContext?) {
        self.extensionContext = extensionContext
    }

    func load() async {
        guard let link = await sharedShortcutLink() else {
            phase = .failed(String(localized: "Share a shortcut’s iCloud link from the Shortcuts app to add it to DoHub."))
            return
        }
        do {
            let record = try await ShortcutRecord.fetch(link: link)
            // `ShortcutData` maps the Shortcuts glyph to an SF Symbol.
            let data = ShortcutData(
                id: record.id,
                name: record.name,
                iconColor: record.iconColor,
                iconGlyph: record.iconGlyph,
                iconURL: nil,
                shortcutURL: nil,
                iCloudLink: link
            )
            draft.name = data.name
            draft.tint = TileTint(shortcutsIconColor: data.iconColor)
            if let symbol = data.icon, ShortcutSymbolCategory.contains(symbol) {
                draft.symbolName = symbol
            }
            phase = .ready(link: link)
        } catch {
            phase = .failed(String(localized: "DoHub couldn’t load this shortcut. Check your connection and try again."))
        }
    }

    func add() {
        do {
            try TileImportQueue.enqueue(draft)
            extensionContext?.completeRequest(returningItems: nil)
        } catch {
            phase = .failed(String(localized: "DoHub couldn’t save this shortcut. Open DoHub once, then try again."))
        }
    }

    func cancel() {
        extensionContext?.cancelRequest(withError: CocoaError(.userCancelled))
    }

    /// The first iCloud shortcut link among the shared items, whether shared as a URL or as text.
    private func sharedShortcutLink() async -> String? {
        let items = extensionContext?.inputItems.compactMap { $0 as? NSExtensionItem } ?? []
        for provider in items.flatMap({ $0.attachments ?? [] }) {
            for type in [UTType.url, UTType.plainText] where provider.hasItemConformingToTypeIdentifier(type.identifier) {
                let item = try? await provider.loadItem(forTypeIdentifier: type.identifier)
                let text = (item as? URL)?.absoluteString
                    ?? (item as? String)
                    ?? (item as? Data).map { String(decoding: $0, as: UTF8.self) }
                if let text, let link = Self.shortcutLink(in: text) {
                    return link
                }
            }
        }
        for item in items {
            if let text = item.attributedContentText?.string, let link = Self.shortcutLink(in: text) {
                return link
            }
        }
        return nil
    }

    private static func shortcutLink(in text: String) -> String? {
        guard let match = text.firstMatch(of: /https:\/\/(www\.)?icloud\.com\/shortcuts\/[A-Za-z0-9]+/) else {
            return nil
        }
        return String(match.output.0)
    }
}
