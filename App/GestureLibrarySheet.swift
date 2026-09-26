import SwiftUI

struct GestureLibrarySheet: View {
  @Environment(\.dismiss) private var dismiss
  @Binding var latestFeatures: [Double]?
  @Binding var stableCaptureFeatures: [Double]?
  @Binding var isCameraActive: Bool
  @Binding var presentationDetent: PresentationDetent
  var assignments: [GestureAssignment]
  var onStartCameraForCapture: () -> Void
  var onSave: (GestureAssignment) -> Void
  var onDelete: (GestureAssignment) -> Void
  var onRun: (GestureAssignment) -> Void

  var body: some View {
    NavigationStack {
      List {
        Section {
          Text("Gestures launch shortcuts only while Start tracking is on. Create matching shortcuts in Apple’s Shortcuts app for Open Clock, Open Photos, Open Camera, or Open Messages, or edit a gesture to use another shortcut.")
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
        }

        Section("Your gestures") {
          if assignments.isEmpty {
            ContentUnavailableView(
              "No gestures yet",
              systemImage: "viewfinder",
              description: Text("Add one to connect a hand pose to a Shortcut.")
            )
          } else {
            ForEach(assignments) { assignment in
              NavigationLink {
                editor(for: assignment)
              } label: {
                assignmentRow(assignment)
              }
              .swipeActions {
                Button("Delete", systemImage: "trash", role: .destructive) {
                  onDelete(assignment)
                }
              }
            }
          }
        }

        Section {
          NavigationLink {
            editor(for: nil)
          } label: {
            Label("Create a gesture", systemImage: "plus")
          }
        }
      }
      .navigationTitle("Manage Gestures")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button("Done", systemImage: "checkmark") {
            dismiss()
          }
        }
      }
    }
    .presentationDetents([.medium, .large], selection: $presentationDetent)
  }

  private func editor(for assignment: GestureAssignment?) -> some View {
    GestureEditorSheet(
      existing: assignment,
      latestFeatures: $latestFeatures,
      stableCaptureFeatures: $stableCaptureFeatures,
      isCameraActive: $isCameraActive,
      presentationDetent: $presentationDetent,
      onStartCameraForCapture: onStartCameraForCapture,
      onSave: onSave
    )
  }

  private func assignmentRow(_ assignment: GestureAssignment) -> some View {
    HStack(spacing: 12) {
      Image(systemName: assignment.kind.symbolName)
        .font(.title3)
        .foregroundStyle(.tint)
        .frame(width: 34, height: 34)
        .background(.tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

      VStack(alignment: .leading, spacing: 3) {
        Text(assignment.name)
          .font(.headline)

        Text(assignmentDetail(assignment))
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }
    }
    .padding(.vertical, 3)
    .contentShape(Rectangle())
    .accessibilityElement(children: .combine)
  }

  private func assignmentDetail(_ assignment: GestureAssignment) -> String {
    if assignment.kind == .capturedPose && assignment.sample.count != HandPoseFeatures.featureCount {
      return "Needs pose recapture · \(assignment.shortcutName)"
    }
    return "Runs \(assignment.shortcutName)"
  }
}
