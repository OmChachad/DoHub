import SwiftUI

struct GestureCameraPanel: View {
  var isCameraActive: Bool
  var isTracking: Bool
  var matchedGesture: GestureAssignment?
  var onToggleTracking: () -> Void
  var onFeatures: ([Double]?) -> Void
  var onCameraFailure: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack(alignment: .firstTextBaseline) {
        VStack(alignment: .leading, spacing: 3) {
          Text("Live gestures")
            .font(.headline)

          Text(statusText)
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }

        Spacer(minLength: 8)

        Button(action: onToggleTracking) {
          Label(isTracking ? "Pause" : "Start tracking", systemImage: isTracking ? "pause.fill" : "viewfinder")
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.regular)
      }

      previewArea
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .frame(minHeight: 230)
    }
    .padding(16)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  private var statusText: String {
    if !isTracking {
      return isCameraActive ? "Camera on · shortcuts paused" : "Start tracking to recognize a gesture"
    }
    if let matchedGesture {
      return "\(matchedGesture.name) detected · \(matchedGesture.shortcutName)"
    }
    return "Hold a saved pose steady to run its shortcut"
  }

  private var previewArea: some View {
    GeometryReader { geometry in
      ZStack {
        Color.black

        if isCameraActive {
          GestureCameraPreview(onFeatures: onFeatures, onUnavailable: onCameraFailure)
            .overlay(alignment: .topLeading) {
              Label(
                isTracking ? "Gesture tracking" : "Pose capture · shortcuts paused",
                systemImage: "viewfinder"
              )
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(.black.opacity(0.56), in: Capsule())
                .padding(12)
            }
            .overlay(alignment: .bottom) {
              if let matchedGesture {
                Label("Running \(matchedGesture.shortcutName)", systemImage: "checkmark")
                  .font(.callout.weight(.semibold))
                  .foregroundStyle(.white)
                  .padding(.horizontal, 14)
                  .padding(.vertical, 10)
                  .background(.black.opacity(0.64), in: Capsule())
                  .padding(12)
              } else {
                Text(isTracking ? "Gestures are processed on this iPhone" : "Shortcuts are paused until Start tracking")
                  .font(.caption.weight(.medium))
                  .foregroundStyle(.white)
                  .padding(.horizontal, 12)
                  .padding(.vertical, 8)
                  .background(.black.opacity(0.56), in: Capsule())
                  .padding(12)
              }
            }
        } else {
          VStack(spacing: 10) {
            Image(systemName: "viewfinder")
              .font(.system(size: 36, weight: .light))
              .accessibilityHidden(true)

            Text("Gesture camera")
              .font(.headline)

            Text("Start tracking, then hold one of your saved hand poses.")
              .font(.subheadline)
              .multilineTextAlignment(.center)
              .foregroundStyle(.white.opacity(0.82))
          }
          .foregroundStyle(.white)
          .padding(20)
        }
      }
      .frame(width: geometry.size.width, height: geometry.size.height)
      .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
    .accessibilityElement(children: .contain)
  }
}
