import Foundation

/// The hand gestures DoHub recognizes with the camera. Each can run one shortcut.
nonisolated enum HandGesture: String, Codable, CaseIterable, Identifiable, Sendable {
    case peaceSign
    case thumbsUp
    case openPalm
    case fingerGun

    var id: Self { self }

    var title: LocalizedStringResource {
        switch self {
        case .peaceSign: "Peace Sign"
        case .thumbsUp: "Thumbs Up"
        case .openPalm: "Open Palm"
        case .fingerGun: "Finger Gun"
        }
    }

    var instruction: LocalizedStringResource {
        switch self {
        case .peaceSign: "Extend your index and middle fingers; curl your ring and little fingers."
        case .thumbsUp: "Extend your thumb and curl the other four fingers."
        case .openPalm: "Extend all five fingers with your palm facing the camera."
        case .fingerGun: "Extend your thumb and index finger; curl the other three fingers."
        }
    }

    var symbolName: String {
        switch self {
        case .peaceSign: "peacesign"
        case .thumbsUp: "hand.thumbsup.fill"
        case .openPalm: "hand.raised.fingers.spread.fill"
        case .fingerGun: "hand.point.up.left.fill"
        }
    }

    /// The gesture a hand-pose feature vector shows, if any.
    static func classify(_ features: [Double]) -> HandGesture? {
        guard features.count == HandPoseFeatures.featureCount else { return nil }
        let thumb = features[0]
        let fingers = features[1...4]
        if features[0...4].allSatisfy({ $0 >= 0.84 }) {
            return .openPalm
        }
        if features[1] >= 0.82, features[2] >= 0.82, features[3] < 0.78, features[4] < 0.78 {
            return .peaceSign
        }
        if thumb >= 0.78, features[1] >= 0.82, features[2...4].allSatisfy({ $0 < 0.64 }) {
            return .fingerGun
        }
        if thumb >= 0.82, fingers.allSatisfy({ $0 < 0.64 }) {
            return .thumbsUp
        }
        return nil
    }
}
