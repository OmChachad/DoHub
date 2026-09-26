import Foundation

enum GestureKind: String, Codable {
  case peaceSign
  case thumbsUp
  case openPalm
  case fingerGun
  case capturedPose

  var instruction: String {
    switch self {
    case .peaceSign:
      return "Extend your index and middle fingers; curl your ring and little fingers."
    case .thumbsUp:
      return "Extend your thumb and curl the other four fingers."
    case .openPalm:
      return "Extend all five fingers with your palm facing the camera."
    case .fingerGun:
      return "Extend your thumb and index finger; curl the other three fingers."
    case .capturedPose:
      return "Hold the same hand shape you captured."
    }
  }

  var shortInstruction: String {
    switch self {
    case .peaceSign: return "Index + middle up"
    case .thumbsUp: return "Thumb up, fingers curled"
    case .openPalm: return "All five fingers extended"
    case .fingerGun: return "Thumb + index extended"
    case .capturedPose: return "Hold your saved pose"
    }
  }

  var symbolName: String {
    switch self {
    case .peaceSign: return "peacesign"
    case .thumbsUp: return "hand.thumbsup.fill"
    case .openPalm: return "hand.raised.fingers.spread.fill"
    case .fingerGun: return "hand.point.up.left.fill"
    case .capturedPose: return "viewfinder"
    }
  }
}

struct GestureAssignment: Codable, Identifiable, Equatable {
  var id: String
  var name: String
  var shortcutName: String
  var kind: GestureKind
  var sample: [Double]

  static var starterPeace: GestureAssignment {
    GestureAssignment(
      id: "starter-peace-sign",
      name: "Peace Sign",
      shortcutName: "Open Clock",
      kind: .peaceSign,
      sample: [0.55, 0.96, 0.96, 0.52, 0.50]
    )
  }

  static var starterGestures: [GestureAssignment] {
    [
      starterPeace,
      GestureAssignment(
        id: "starter-thumbs-up",
        name: "Thumbs Up",
        shortcutName: "Open Photos",
        kind: .thumbsUp,
        sample: []
      ),
      GestureAssignment(
        id: "starter-open-palm",
        name: "Open Palm",
        shortcutName: "Open Camera",
        kind: .openPalm,
        sample: []
      ),
      GestureAssignment(
        id: "starter-finger-gun",
        name: "Finger Gun",
        shortcutName: "Open Messages",
        kind: .fingerGun,
        sample: []
      )
    ]
  }
}
