import Foundation
import ImageIO
import UniformTypeIdentifiers

/// The kind of output a shortcut returned. Shortcuts only returns text through x-callback,
/// so media arrives as a `data:` URI or as raw base64 and is detected here.
nonisolated enum ShortcutOutputContent: Sendable {
    case empty
    case text(String)
    case link(URL)
    case media(Data, UTType)

    /// Detects links, `data:` URIs, and base64-encoded images or PDFs in a shortcut's output.
    static func detect(in raw: String?) -> ShortcutOutputContent {
        guard let raw else { return .empty }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if let media = decodeDataURI(trimmed) ?? decodeBase64(trimmed) {
            return media
        }
        return textOrLink(raw)
    }

    /// Classifies output as a link or plain text without attempting to decode media.
    static func textOrLink(_ raw: String?) -> ShortcutOutputContent {
        guard let raw else { return .empty }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return .empty }
        if !trimmed.contains(where: \.isWhitespace),
           let url = URL(string: trimmed),
           let scheme = url.scheme?.lowercased(),
           (scheme == "file" || (["http", "https"].contains(scheme) && url.host() != nil)) {
            return .link(url)
        }
        return .text(raw)
    }

    private static func decodeDataURI(_ string: String) -> ShortcutOutputContent? {
        guard string.hasPrefix("data:"), let comma = string.firstIndex(of: ",") else { return nil }
        let header = string[string.index(string.startIndex, offsetBy: 5)..<comma]
        guard header.hasSuffix(";base64"),
              let data = Data(base64Encoded: String(string[string.index(after: comma)...]), options: .ignoreUnknownCharacters),
              !data.isEmpty
        else { return nil }
        let mimeType = String(header.dropLast(";base64".count))
        let type = sniffType(of: data) ?? UTType(mimeType: mimeType) ?? .data
        return .media(data, type)
    }

    private static func decodeBase64(_ string: String) -> ShortcutOutputContent? {
        // Encoded files are long and contain no spaces, which rules out ordinary text quickly.
        guard string.count >= 64, !string.contains(" "),
              let data = Data(base64Encoded: string, options: .ignoreUnknownCharacters),
              let type = sniffType(of: data)
        else { return nil }
        return .media(data, type)
    }

    private static func sniffType(of data: Data) -> UTType? {
        if data.starts(with: Data("%PDF".utf8)) {
            return .pdf
        }
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              CGImageSourceGetCount(source) > 0,
              let identifier = CGImageSourceGetType(source) as String?
        else { return nil }
        return UTType(identifier)
    }

    /// Decodes a downsampled image for previewing media output.
    static func thumbnail(from data: Data, maxPixelSize: Int = 1200) -> CGImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
        ]
        return CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
    }
}
