import Foundation
import SwiftData
import UniformTypeIdentifiers

/// One saved shortcut run and its output, shown in the output history.
@Model
final class ShortcutRunRecord {
    @Attribute(.unique) var runID: UUID
    var date: Date
    /// A snapshot of the tile that ran, so the record stays readable after the tile changes or is deleted.
    var shortcutName: String
    var symbolName: String
    var tint: TileTint
    var outcome: RunOutcome
    var text: String?
    var errorMessage: String?
    @Attribute(.externalStorage) var mediaData: Data?
    var mediaTypeIdentifier: String?

    init(
        runID: UUID,
        date: Date = .now,
        shortcutName: String,
        symbolName: String,
        tint: TileTint,
        outcome: RunOutcome,
        output: String? = nil,
        errorMessage: String? = nil
    ) {
        self.runID = runID
        self.date = date
        self.shortcutName = shortcutName
        self.symbolName = symbolName
        self.tint = tint
        self.outcome = outcome
        self.errorMessage = errorMessage
        // Store decoded media as bytes rather than keeping the much larger base64 text.
        if case .media(let data, let type) = ShortcutOutputContent.detect(in: output) {
            self.text = nil
            self.mediaData = data
            self.mediaTypeIdentifier = type.identifier
        } else {
            self.text = output
            self.mediaData = nil
            self.mediaTypeIdentifier = nil
        }
    }

    /// Fetches only the most recent record.
    static var latestDescriptor: FetchDescriptor<ShortcutRunRecord> {
        var descriptor = FetchDescriptor<ShortcutRunRecord>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        descriptor.fetchLimit = 1
        return descriptor
    }

    var mediaType: UTType? {
        mediaTypeIdentifier.flatMap(UTType.init)
    }

    var content: ShortcutOutputContent {
        if let mediaData, let mediaType {
            return .media(mediaData, mediaType)
        }
        return ShortcutOutputContent.textOrLink(text)
    }

    /// A one-line summary for history rows. Avoids loading media bytes.
    var previewText: String {
        switch outcome {
        case .cancelled:
            return String(localized: "Cancelled")
        case .failed:
            return errorMessage ?? String(localized: "The shortcut failed.")
        case .succeeded:
            if let mediaType {
                if mediaType.conforms(to: .image) { return String(localized: "Image") }
                if mediaType.conforms(to: .pdf) { return String(localized: "PDF Document") }
                return String(localized: "File")
            }
            switch ShortcutOutputContent.textOrLink(text) {
            case .text(let text):
                let firstLine = text.split(whereSeparator: \.isNewline).first { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
                return firstLine.map { String($0).trimmingCharacters(in: .whitespaces) } ?? text
            case .link(let url):
                return url.host() ?? url.absoluteString
            case .empty, .media:
                return String(localized: "No output")
            }
        }
    }
}
