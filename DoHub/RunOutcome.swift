import SwiftUI

/// How a shortcut run ended, as reported by its x-callback URL.
nonisolated enum RunOutcome: String, Codable, Sendable {
    case succeeded
    case cancelled
    case failed

    var title: LocalizedStringResource {
        switch self {
        case .succeeded: "Finished"
        case .cancelled: "Cancelled"
        case .failed: "Failed"
        }
    }

    var symbolName: String {
        switch self {
        case .succeeded: "checkmark.circle.fill"
        case .cancelled: "arrow.uturn.backward.circle.fill"
        case .failed: "exclamationmark.triangle.fill"
        }
    }

    var color: Color {
        switch self {
        case .succeeded: .green
        case .cancelled: .orange
        case .failed: .red
        }
    }
}
