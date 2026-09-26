import AVFoundation
import SwiftUI

struct ContentView: View {
  @Environment(\.openURL) private var openURL
  @Environment(\.scenePhase) private var scenePhase
  @State private var selectedTab: WorkspaceTab = .camera
  @State private var gestureLibrary = GestureLibrary()
  @State private var isCameraActive = false
  @State private var isGestureTrackingEnabled = false
  @State private var isGestureLibraryPresented = false
  @State private var gestureSheetDetent: PresentationDetent = .medium
  @State private var isCameraUnavailablePresented = false
  @State private var latestFeatures: [Double]?
  @State private var recentCaptureFeatures: [[Double]] = []
  @State private var stableCaptureFeatures: [Double]?
  @State private var missingFeatureFrames = 0
  @State private var matchedGestureID: String?
  @State private var candidateGestureID: String?
  @State private var candidateFrameCount = 0
  @State private var latchedGestureID: String?
  @State private var neutralFrameCount = 0

  var body: some View {
    NavigationStack {
      Group {
        if #available(iOS 27.1, *) {
          FoldAwareWorkspace(
            controls: { shortcutPanel },
            preview: { cameraPanel },
            flat: { flatWorkspace }
          )
        } else {
          flatWorkspace
        }
      }
      .navigationTitle("FlexDeck")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button("Manage Gestures", systemImage: "slider.horizontal.3") {
            prepareGestureEditing()
            isGestureLibraryPresented = true
          }
        }
      }
    }
    .tint(.accentColor)
    .onChange(of: selectedTab) { _, tab in
      if tab == .shortcuts {
        stopTracking()
      }
    }
    .onChange(of: isGestureLibraryPresented) { _, isPresented in
      if isPresented {
        prepareGestureEditing()
      }
    }
    .onChange(of: scenePhase) { _, phase in
      if phase != .active {
        stopTracking()
      }
    }
    .sheet(isPresented: $isGestureLibraryPresented) {
      GestureLibrarySheet(
        latestFeatures: $latestFeatures,
        stableCaptureFeatures: $stableCaptureFeatures,
        isCameraActive: $isCameraActive,
        presentationDetent: $gestureSheetDetent,
        assignments: gestureLibrary.assignments,
        onStartCameraForCapture: startCameraForCapture,
        onSave: gestureLibrary.save,
        onDelete: gestureLibrary.remove,
        onRun: runShortcut
      )
    }
    .alert("Camera unavailable", isPresented: $isCameraUnavailablePresented) {
      Button("OK", role: .cancel) { }
    } message: {
      Text("Allow camera access in Settings to recognize hand gestures.")
    }
  }

  private var cameraPanel: some View {
    GestureCameraPanel(
      isCameraActive: isCameraActive,
      isTracking: isGestureTrackingEnabled,
      matchedGesture: matchedAssignment,
      onToggleTracking: {
        if isGestureTrackingEnabled {
          stopTracking()
        } else {
          startTracking()
        }
      },
      onFeatures: receiveFeatures,
      onCameraFailure: {
        stopTracking()
        isCameraUnavailablePresented = true
      }
    )
  }

  private var shortcutPanel: some View {
    ShortcutPanel(
      assignments: gestureLibrary.assignments,
      onRun: runShortcut,
      onManage: {
        prepareGestureEditing()
        isGestureLibraryPresented = true
      }
    )
  }

  private var flatWorkspace: some View {
    TabView(selection: $selectedTab) {
      cameraPanel
        .tabItem { Label("Camera", systemImage: "camera.fill") }
        .tag(WorkspaceTab.camera)

      shortcutPanel
        .tabItem { Label("Shortcuts", systemImage: "square.grid.2x2.fill") }
        .tag(WorkspaceTab.shortcuts)
    }
  }

  private var matchedAssignment: GestureAssignment? {
    gestureLibrary.assignments.first { $0.id == matchedGestureID }
  }

  private func startTracking() {
    startCamera(enableGestureTracking: true)
  }

  private func startCameraForCapture() {
    startCamera(enableGestureTracking: false)
  }

  private func startCamera(enableGestureTracking: Bool) {
    guard AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) != nil else {
      isCameraUnavailablePresented = true
      return
    }

    func activateCamera() {
      recentCaptureFeatures = []
      stableCaptureFeatures = nil
      resetGestureRecognition()
      isCameraActive = true
      isGestureTrackingEnabled = enableGestureTracking
      selectedTab = .camera
    }

    switch AVCaptureDevice.authorizationStatus(for: .video) {
    case .authorized:
      activateCamera()
    case .notDetermined:
      Task {
        let isAuthorized = await AVCaptureDevice.requestAccess(for: .video)
        if isAuthorized {
          activateCamera()
        } else {
          isCameraUnavailablePresented = true
        }
      }
    case .denied, .restricted:
      isCameraUnavailablePresented = true
    @unknown default:
      isCameraUnavailablePresented = true
    }
  }

  private func stopTracking() {
    isCameraActive = false
    isGestureTrackingEnabled = false
    latestFeatures = nil
    missingFeatureFrames = 0
    recentCaptureFeatures = []
    stableCaptureFeatures = nil
    resetGestureRecognition()
  }

  private func prepareGestureEditing() {
    isGestureTrackingEnabled = false
    recentCaptureFeatures = []
    stableCaptureFeatures = nil
    resetGestureRecognition()
  }

  private func resetGestureRecognition() {
    matchedGestureID = nil
    candidateGestureID = nil
    candidateFrameCount = 0
    latchedGestureID = nil
    neutralFrameCount = 0
  }

  private func receiveFeatures(_ features: [Double]?) {
    guard isCameraActive else { return }

    guard let features else {
      missingFeatureFrames += 1
      recentCaptureFeatures = []
      stableCaptureFeatures = nil
      if missingFeatureFrames >= 5 {
        latestFeatures = nil
      }
      matchedGestureID = nil
      candidateGestureID = nil
      candidateFrameCount = 0
      neutralFrameCount += 1
      if neutralFrameCount >= 3 {
        latchedGestureID = nil
      }
      return
    }

    latestFeatures = features
    missingFeatureFrames = 0

    guard isGestureTrackingEnabled else {
      recentCaptureFeatures.append(features)
      if recentCaptureFeatures.count > HandPoseFeatures.captureWindowFrameCount {
        recentCaptureFeatures.removeFirst()
      }
      stableCaptureFeatures = HandPoseFeatures.stableConsensus(from: recentCaptureFeatures)
      resetGestureRecognition()
      return
    }

    recentCaptureFeatures = []
    stableCaptureFeatures = nil
    neutralFrameCount = 0
    matchedGestureID = nil
    let match = HandPoseFeatures.match(features, against: gestureLibrary.assignments)

    guard let match else {
      matchedGestureID = nil
      candidateGestureID = nil
      candidateFrameCount = 0
      neutralFrameCount += 1
      if neutralFrameCount >= 3 {
        latchedGestureID = nil
      }
      return
    }

    if candidateGestureID == match.id {
      candidateFrameCount += 1
    } else {
      candidateGestureID = match.id
      candidateFrameCount = 1
    }

    guard candidateFrameCount >= 5 else { return }
    matchedGestureID = match.id
    guard latchedGestureID != match.id else { return }
    latchedGestureID = match.id
    runShortcut(match)
  }

  private func runShortcut(_ assignment: GestureAssignment) {
    guard !assignment.shortcutName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
    var components = URLComponents()
    components.scheme = "shortcuts"
    components.host = "run-shortcut"
    components.queryItems = [URLQueryItem(name: "name", value: assignment.shortcutName)]
    if let url = components.url {
      openURL(url)
    }
  }
}

private enum WorkspaceTab: Hashable {
  case camera
  case shortcuts
}
