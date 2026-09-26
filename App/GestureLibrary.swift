import Foundation
import Observation

@MainActor
@Observable
final class GestureLibrary {
  private(set) var assignments: [GestureAssignment]
  private static let storageKey = "flexdeck.gestureAssignments"
  private static let starterVersionKey = "flexdeck.gestureLibraryStarterVersion"
  private static let currentStarterVersion = 1

  init() {
    let defaults = UserDefaults.standard
    if let data = UserDefaults.standard.data(forKey: Self.storageKey),
       let saved = try? JSONDecoder().decode([GestureAssignment].self, from: data) {
      assignments = saved
      if defaults.integer(forKey: Self.starterVersionKey) < Self.currentStarterVersion {
        for starter in GestureAssignment.starterGestures
        where !assignments.contains(where: { $0.id == starter.id }) {
          assignments.append(starter)
        }
        defaults.set(Self.currentStarterVersion, forKey: Self.starterVersionKey)
        persist()
      }
    } else {
      assignments = GestureAssignment.starterGestures
      defaults.set(Self.currentStarterVersion, forKey: Self.starterVersionKey)
      persist()
    }
  }

  func save(_ assignment: GestureAssignment) {
    if let existingIndex = assignments.firstIndex(where: { $0.id == assignment.id }) {
      assignments[existingIndex] = assignment
    } else {
      assignments.append(assignment)
    }
    persist()
  }

  func remove(_ assignment: GestureAssignment) {
    assignments.removeAll { $0.id == assignment.id }
    persist()
  }

  private func persist() {
    guard let data = try? JSONEncoder().encode(assignments) else { return }
    UserDefaults.standard.set(data, forKey: Self.storageKey)
  }
}
