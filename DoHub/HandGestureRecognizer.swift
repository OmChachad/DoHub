import Foundation

/// Watches the camera for gestures. A gesture counts once it's held steady for about a
/// second, and fires once until the hand relaxes or leaves the frame.
@Observable
final class HandGestureRecognizer {
    /// Whether the camera is running and looking for gestures.
    private(set) var isRunning = false
    /// Called when a gesture is recognized.
    @ObservationIgnored var onGesture: ((HandGesture) -> Void)?

    /// Consecutive analyzed frames (about five a second) needed to recognize a gesture.
    private static let requiredFrames = 5
    /// Frames without the gesture before it can fire again.
    private static let releaseFrames = 3

    @ObservationIgnored private var candidate: HandGesture?
    @ObservationIgnored private var candidateFrames = 0
    @ObservationIgnored private var latched: HandGesture?
    @ObservationIgnored private var neutralFrames = 0

    #if os(iOS)
    @ObservationIgnored private let camera = HandPoseCamera()
    #endif

    func start() async {
        #if os(iOS)
        guard !isRunning else { return }
        camera.onFeatures = { [weak self] features in
            self?.receive(features)
        }
        isRunning = await camera.start()
        #endif
    }

    func stop() {
        #if os(iOS)
        camera.stop()
        #endif
        isRunning = false
        reset()
    }

    private func receive(_ features: [Double]?) {
        guard isRunning else { return }
        guard let features, let gesture = HandGesture.classify(features) else {
            candidate = nil
            candidateFrames = 0
            neutralFrames += 1
            if neutralFrames >= Self.releaseFrames {
                latched = nil
            }
            return
        }

        neutralFrames = 0
        if gesture == candidate {
            candidateFrames += 1
        } else {
            candidate = gesture
            candidateFrames = 1
        }
        guard candidateFrames >= Self.requiredFrames, latched != gesture else { return }
        latched = gesture
        onGesture?(gesture)
    }

    private func reset() {
        candidate = nil
        candidateFrames = 0
        latched = nil
        neutralFrames = 0
    }
}
