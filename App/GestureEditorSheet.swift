import SwiftUI

struct GestureEditorSheet: View {
  @Environment(\.dismiss) private var dismiss
  @Binding var latestFeatures: [Double]?
  @Binding var stableCaptureFeatures: [Double]?
  @Binding var isCameraActive: Bool
  @Binding var presentationDetent: PresentationDetent
  var existing: GestureAssignment?
  var onStartCameraForCapture: () -> Void
  var onSave: (GestureAssignment) -> Void

  @State private var gestureName: String
  @State private var shortcutName: String
  @State private var capturedPose: [Double]?
  @State private var captureFeedback: String?
  @FocusState private var focusedField: Field?

  init(
    existing: GestureAssignment?,
    latestFeatures: Binding<[Double]?>,
    stableCaptureFeatures: Binding<[Double]?>,
    isCameraActive: Binding<Bool>,
    presentationDetent: Binding<PresentationDetent>,
    onStartCameraForCapture: @escaping () -> Void,
    onSave: @escaping (GestureAssignment) -> Void
  ) {
    self.existing = existing
    self._latestFeatures = latestFeatures
    self._stableCaptureFeatures = stableCaptureFeatures
    self._isCameraActive = isCameraActive
    self._presentationDetent = presentationDetent
    self.onStartCameraForCapture = onStartCameraForCapture
    self.onSave = onSave
    _gestureName = State(initialValue: existing?.name ?? "")
    _shortcutName = State(initialValue: existing?.shortcutName ?? "")
    _capturedPose = State(
      initialValue: existing?.kind == .capturedPose
        && existing?.sample.count == HandPoseFeatures.featureCount
        ? existing?.sample
        : nil
    )
  }

  var body: some View {
    Form {
      Section("Gesture") {
        TextField("Gesture name", text: $gestureName)
          .textContentType(.name)
          .focused($focusedField, equals: .gesture)
          .submitLabel(.next)
          .onSubmit { focusedField = .shortcut }

        if let captureFeedback {
          Label(captureFeedback, systemImage: "exclamationmark.circle")
            .font(.subheadline)
            .foregroundStyle(.orange)
        } else if capturedPose != nil {
          Label("Pose captured. Hold the same hand shape to trigger it.", systemImage: "checkmark")
            .font(.subheadline)
            .foregroundStyle(.tint)
        } else if let existing, existing.kind != .capturedPose {
          Label(existing.kind.instruction, systemImage: existing.kind.symbolName)
            .font(.subheadline)
            .foregroundStyle(.secondary)
        } else if existing?.kind == .capturedPose && capturedPose == nil {
          Label("Capture this saved pose again for improved recognition.", systemImage: "arrow.clockwise")
            .font(.subheadline)
            .foregroundStyle(.secondary)
        } else if stableCaptureFeatures != nil {
          Label("Pose steady. Tap Capture this pose to save it.", systemImage: "viewfinder")
            .font(.subheadline)
            .foregroundStyle(.tint)
        } else if latestFeatures != nil {
          Label("Hold your hand steady in view for about a second.", systemImage: "viewfinder")
            .font(.subheadline)
            .foregroundStyle(.secondary)
        } else {
          Text("Show one hand clearly in the camera and hold your pose steady.")
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }

        if isCameraActive {
          Button("Capture this pose", systemImage: "viewfinder") {
            revealCamera()
            if let stableCaptureFeatures {
              capturedPose = stableCaptureFeatures
              captureFeedback = nil
            } else {
              captureFeedback = "Hold one clear pose steady for about a second, then capture it."
            }
          }
        } else {
          Button("Start camera for capture", systemImage: "camera.fill") {
            revealCamera()
            onStartCameraForCapture()
          }
        }
      }

      Section("Shortcut") {
        TextField("Shortcut name", text: $shortcutName)
          .textInputAutocapitalization(.words)
          .autocorrectionDisabled()
          .focused($focusedField, equals: .shortcut)
          .submitLabel(.done)

        Text("Enter the exact name of a shortcut in Apple’s Shortcuts app.")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
    }
    .navigationTitle(existing == nil ? "New Gesture" : "Edit Gesture")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .cancellationAction) {
        Button("Cancel") {
          dismiss()
        }
      }
      ToolbarItem(placement: .confirmationAction) {
        Button("Save") {
          saveGesture()
        }
        .disabled(!canSave)
      }
    }
    .scrollDismissesKeyboard(.interactively)
    .onAppear {
      withAnimation(.smooth) {
        presentationDetent = .large
      }
    }
    .onChange(of: stableCaptureFeatures != nil) { _, hasStablePose in
      if hasStablePose {
        captureFeedback = nil
      }
    }
  }

  private var canSave: Bool {
    !gestureName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
      && !shortcutName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
      && (existing.map { $0.kind != .capturedPose } == true || capturedPose != nil)
  }

  private func revealCamera() {
    focusedField = nil
    withAnimation(.smooth) {
      presentationDetent = .medium
    }
  }

  private func saveGesture() {
    let cleanName = gestureName.trimmingCharacters(in: .whitespacesAndNewlines)
    let cleanShortcutName = shortcutName.trimmingCharacters(in: .whitespacesAndNewlines)
    var assignment = existing ?? GestureAssignment(
      id: UUID().uuidString,
      name: cleanName,
      shortcutName: cleanShortcutName,
      kind: .capturedPose,
      sample: capturedPose ?? []
    )
    assignment.name = cleanName
    assignment.shortcutName = cleanShortcutName
    if let capturedPose {
      assignment.kind = .capturedPose
      assignment.sample = capturedPose
    }
    onSave(assignment)
    dismiss()
  }

  private enum Field: Hashable {
    case gesture
    case shortcut
  }
}
