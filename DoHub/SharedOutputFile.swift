import CoreTransferable
import Foundation
import UniformTypeIdentifiers

/// Media output packaged as a file with the right extension for the share sheet.
nonisolated struct SharedOutputFile: Transferable, Sendable {
    var data: Data
    var type: UTType
    var name: String

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: .pdf, exporting: export)
            .exportingCondition { $0.type.conforms(to: .pdf) }
        FileRepresentation(exportedContentType: .image, exporting: export)
            .exportingCondition { $0.type.conforms(to: .image) }
        FileRepresentation(exportedContentType: .data, exporting: export)
    }

    private var fileName: String {
        let base = name.isEmpty ? "Output" : name.replacing("/", with: "-")
        guard let fileExtension = type.preferredFilenameExtension else { return base }
        return "\(base).\(fileExtension)"
    }

    @Sendable private static func export(_ file: SharedOutputFile) async throws -> SentTransferredFile {
        let directory = URL.temporaryDirectory.appending(path: UUID().uuidString, directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appending(path: file.fileName)
        try file.data.write(to: url, options: .atomic)
        return SentTransferredFile(url)
    }
}
