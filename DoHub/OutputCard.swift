import SwiftUI
import UniformTypeIdentifiers
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// An expanded output: selectable text with a Copy button, or media with a share button.
struct OutputCard: View {
    var record: ShortcutRunRecord
    /// Limits the output to a short preview, for new outputs shown above the deck.
    var isCompact = false
    var onCollapse: () -> Void

    @State private var didCopy = false
    @State private var previewImage: CGImage?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            output
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .task(id: record.runID) {
            loadPreviewImage()
        }
        .task(id: didCopy) {
            guard didCopy else { return }
            try? await Task.sleep(for: .seconds(1.5))
            didCopy = false
        }
        .sensoryFeedback(.success, trigger: didCopy) { _, copied in copied }
    }

    private var header: some View {
        HStack(spacing: 10) {
            Button("Collapse", systemImage: "chevron.up", action: onCollapse)
                .labelStyle(.iconOnly)
                .font(.body.weight(.semibold))
                .frame(minWidth: 32, minHeight: 32)
                .contentShape(.rect)
                .buttonStyle(.borderless)
            TileIconBadge(symbolName: record.symbolName, tint: record.tint, dimension: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text(record.shortcutName)
                    .font(.headline)
                    .lineLimit(2)
                HStack(spacing: 4) {
                    Label {
                        Text(record.outcome.title)
                    } icon: {
                        Image(systemName: record.outcome.symbolName)
                            .foregroundStyle(record.outcome.color)
                    }
                    Text("·")
                        .accessibilityHidden(true)
                    Text(record.date, format: .dateTime.hour().minute())
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            trailingAction
                .labelStyle(.iconOnly)
                .font(.body.weight(.semibold))
                .buttonStyle(.bordered)
                .buttonBorderShape(.circle)
        }
    }

    @ViewBuilder
    private var trailingAction: some View {
        if record.outcome == .succeeded {
            switch record.content {
            case .text(let text):
                Button(didCopy ? "Copied" : "Copy", systemImage: didCopy ? "checkmark" : "document.on.document") {
                    copy(text)
                }
                .contentTransition(.symbolEffect(.replace))
            case .link(let url):
                ShareLink(item: url) {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
            case .media(let data, let type):
                let file = SharedOutputFile(data: data, type: type, name: record.shortcutName)
                if let previewImage {
                    ShareLink(item: file, preview: SharePreview(record.shortcutName, image: Image(decorative: previewImage, scale: 1))) {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                } else {
                    ShareLink(item: file, preview: SharePreview(record.shortcutName)) {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                }
            case .empty:
                EmptyView()
            }
        }
    }

    @ViewBuilder
    private var output: some View {
        switch record.outcome {
        case .failed:
            Text(record.errorMessage ?? String(localized: "The shortcut failed."))
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
        case .cancelled:
            Text("The shortcut was cancelled before it finished.")
                .foregroundStyle(.secondary)
        case .succeeded:
            switch record.content {
            case .empty:
                Text("The shortcut finished without returning any output.")
                    .foregroundStyle(.secondary)
            case .text(let text):
                Text(text)
                    .lineLimit(isCompact ? 3 : nil)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            case .link(let url):
                Text(url.absoluteString)
                    .foregroundStyle(.tint)
                    .textSelection(.enabled)
            case .media(let data, let type):
                media(data: data, type: type)
            }
        }
    }

    @ViewBuilder
    private func media(data: Data, type: UTType) -> some View {
        if let previewImage {
            Image(decorative: previewImage, scale: 1)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: isCompact ? 120 : 280)
                .clipShape(.rect(cornerRadius: 14))
                .accessibilityLabel("Image output from \(record.shortcutName)")
        } else {
            Label {
                VStack(alignment: .leading) {
                    Text(type.localizedDescription ?? String(localized: "File"))
                    Text(Int64(data.count), format: .byteCount(style: .file))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } icon: {
                Image(systemName: "document.fill")
                    .font(.title)
            }
        }
    }

    private func loadPreviewImage() {
        guard let mediaData = record.mediaData, record.mediaType?.conforms(to: .image) == true else {
            previewImage = nil
            return
        }
        previewImage = ShortcutOutputContent.thumbnail(from: mediaData)
    }

    private func copy(_ text: String) {
        #if canImport(UIKit)
        UIPasteboard.general.string = text
        #elseif canImport(AppKit)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        #endif
        didCopy = true
    }
}
