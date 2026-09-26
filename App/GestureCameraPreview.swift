import AVFoundation
import SwiftUI
import Vision

struct GestureCameraPreview: UIViewRepresentable {
  var onFeatures: ([Double]?) -> Void
  var onUnavailable: () -> Void

  func makeCoordinator() -> Coordinator {
    Coordinator(onFeatures: onFeatures, onUnavailable: onUnavailable)
  }

  func makeUIView(context: Context) -> GesturePreviewSurface {
    let view = GesturePreviewSurface()
    context.coordinator.attach(to: view)
    return view
  }

  func updateUIView(_ view: GesturePreviewSurface, context: Context) {
    context.coordinator.onFeatures = onFeatures
    context.coordinator.onUnavailable = onUnavailable
  }

  static func dismantleUIView(_ view: GesturePreviewSurface, coordinator: Coordinator) {
    coordinator.stop()
  }

  final class Coordinator: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    var onFeatures: ([Double]?) -> Void
    var onUnavailable: () -> Void

    private var session = AVCaptureSession()
    private var output = AVCaptureVideoDataOutput()
    private var previewSurface: GesturePreviewSurface?
    private var rotationCoordinator: AVCaptureDevice.RotationCoordinator?
    private var rotationObservation: NSKeyValueObservation?
    private var didConfigureSession = false
    private var lastPublishedAt = 0.0
    private let sessionQueue = DispatchQueue(label: "app.flexdeck.camera-session")
    private let analysisQueue = DispatchQueue(label: "app.flexdeck.hand-analysis")
    private var handPoseRequest: VNDetectHumanHandPoseRequest = {
      let request = VNDetectHumanHandPoseRequest()
      request.maximumHandCount = 1
      return request
    }()

    init(onFeatures: @escaping ([Double]?) -> Void, onUnavailable: @escaping () -> Void) {
      self.onFeatures = onFeatures
      self.onUnavailable = onUnavailable
    }

    func attach(to surface: GesturePreviewSurface) {
      previewSurface = surface
      surface.previewLayer.videoGravity = .resizeAspectFill
      surface.previewLayer.session = session
      sessionQueue.async { [weak self, weak surface] in
        guard let self, let surface else { return }
        self.configureSession(for: surface)
      }
    }

    func stop() {
      rotationObservation = nil
      sessionQueue.async { [weak self] in
        guard let self, self.session.isRunning else { return }
        self.session.stopRunning()
      }
    }

    private func configureSession(for surface: GesturePreviewSurface) {
      guard !didConfigureSession else {
        if !session.isRunning {
          session.startRunning()
        }
        return
      }

      guard
        let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
        let input = try? AVCaptureDeviceInput(device: device)
      else {
        notifyUnavailable()
        return
      }

      session.beginConfiguration()
      session.sessionPreset = .high
      guard session.canAddInput(input) else {
        session.commitConfiguration()
        notifyUnavailable()
        return
      }
      session.addInput(input)

      output.alwaysDiscardsLateVideoFrames = true
      output.videoSettings = [
        kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
      ]
      output.setSampleBufferDelegate(self, queue: analysisQueue)
      guard session.canAddOutput(output) else {
        session.commitConfiguration()
        notifyUnavailable()
        return
      }
      session.addOutput(output)
      session.commitConfiguration()
      didConfigureSession = true

      DispatchQueue.main.async { [weak self, weak surface] in
        guard let self, let surface else { return }
        self.configureRotation(for: device, surface: surface)
        self.sessionQueue.async { [weak self] in
          guard let self, !self.session.isRunning else { return }
          self.session.startRunning()
        }
      }
    }

    private func configureRotation(for device: AVCaptureDevice, surface: GesturePreviewSurface) {
      let coordinator = AVCaptureDevice.RotationCoordinator(device: device, previewLayer: surface.previewLayer)
      rotationCoordinator = coordinator
      rotationObservation = coordinator.observe(
        \.videoRotationAngleForHorizonLevelPreview,
        options: [.initial, .new]
      ) { [weak self, weak surface] coordinator, _ in
        guard let self, let surface else { return }
        let angle = coordinator.videoRotationAngleForHorizonLevelPreview
        DispatchQueue.main.async {
          if let connection = surface.previewLayer.connection {
            connection.automaticallyAdjustsVideoMirroring = false
            if connection.isVideoMirroringSupported {
              connection.isVideoMirrored = true
            }
            if connection.isVideoRotationAngleSupported(angle) {
              connection.videoRotationAngle = angle
            }
          }
          if let connection = self.output.connection(with: .video),
             connection.isVideoRotationAngleSupported(angle) {
            connection.videoRotationAngle = angle
          }
        }
      }
    }

    private func notifyUnavailable() {
      DispatchQueue.main.async { [weak self] in
        self?.onUnavailable()
      }
    }

    func captureOutput(
      _ output: AVCaptureOutput,
      didOutput sampleBuffer: CMSampleBuffer,
      from connection: AVCaptureConnection
    ) {
      let now = ProcessInfo.processInfo.systemUptime
      guard now - lastPublishedAt >= 0.20 else { return }
      lastPublishedAt = now

      let features: [Double]?
      do {
        let handler = VNImageRequestHandler(cmSampleBuffer: sampleBuffer, orientation: .up, options: [:])
        try handler.perform([handPoseRequest])
        if let observation = handPoseRequest.results?.first {
          features = HandPoseFeatures.vector(from: observation)
        } else {
          features = nil
        }
      } catch {
        features = nil
      }

      DispatchQueue.main.async { [weak self] in
        self?.onFeatures(features)
      }
    }
  }
}

final class GesturePreviewSurface: UIView {
  override class var layerClass: AnyClass {
    AVCaptureVideoPreviewLayer.self
  }

  var previewLayer: AVCaptureVideoPreviewLayer {
    layer as! AVCaptureVideoPreviewLayer
  }
}
