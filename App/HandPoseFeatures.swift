import Vision

enum HandPoseFeatures {
  static let featureCount = 20
  static let captureWindowFrameCount = 5

  private static var fingerJoints: [[VNHumanHandPoseObservation.JointName]] {
    [
      [.thumbCMC, .thumbMP, .thumbIP, .thumbTip],
      [.indexMCP, .indexPIP, .indexDIP, .indexTip],
      [.middleMCP, .middlePIP, .middleDIP, .middleTip],
      [.ringMCP, .ringPIP, .ringDIP, .ringTip],
      [.littleMCP, .littlePIP, .littleDIP, .littleTip]
    ]
  }

  static func vector(from observation: VNHumanHandPoseObservation) -> [Double]? {
    var fingers: [[VNRecognizedPoint]] = []

    for joints in fingerJoints {
      var points: [VNRecognizedPoint] = []
      for joint in joints {
        guard let point = try? observation.recognizedPoint(joint), point.confidence >= 0.25 else {
          return nil
        }
        points.append(point)
      }
      fingers.append(points)
    }

    var values: [Double] = []
    for points in fingers {
      var chainLength = 0.0
      for index in 0..<(points.count - 1) {
        chainLength += distance(points[index].location, points[index + 1].location)
      }
      guard chainLength > 0 else { return nil }
      let reach = distance(points[0].location, points[points.count - 1].location)
      values.append(min(1, max(0, reach / chainLength)))
    }

    let handScale = distance(fingers[1][0].location, fingers[4][0].location)
    guard handScale > 0.025 else { return nil }

    let palmJoints = [fingers[0][0], fingers[1][0], fingers[2][0], fingers[3][0], fingers[4][0]]
    let palmCenter = CGPoint(
      x: palmJoints.map { $0.location.x }.reduce(0, +) / CGFloat(palmJoints.count),
      y: palmJoints.map { $0.location.y }.reduce(0, +) / CGFloat(palmJoints.count)
    )
    let fingertips = fingers.map { $0[$0.count - 1].location }

    for tip in fingertips {
      values.append(distance(tip, palmCenter) / handScale)
    }

    for firstIndex in fingertips.indices {
      for secondIndex in fingertips.indices where secondIndex > firstIndex {
        values.append(distance(fingertips[firstIndex], fingertips[secondIndex]) / handScale)
      }
    }

    guard values.count == featureCount else { return nil }
    return values
  }

  static func stableConsensus(from samples: [[Double]]) -> [Double]? {
    let window = Array(samples.suffix(captureWindowFrameCount))
    guard
      window.count == captureWindowFrameCount,
      window.allSatisfy({ $0.count == featureCount })
    else { return nil }

    var consensus: [Double] = []
    for featureIndex in 0..<featureCount {
      let values = window.map { $0[featureIndex] }
      guard let smallest = values.min(), let largest = values.max(), largest - smallest <= 0.18 else {
        return nil
      }
      consensus.append(values.reduce(0, +) / Double(values.count))
    }
    return consensus
  }

  static func match(
    _ features: [Double],
    against assignments: [GestureAssignment]
  ) -> GestureAssignment? {
    guard features.count == featureCount else { return nil }
    let candidates = assignments.compactMap { assignment -> (GestureAssignment, Double)? in
      switch assignment.kind {
      case .peaceSign:
        guard isPeaceSign(features) else { return nil }
        return (assignment, 0)
      case .thumbsUp:
        guard isThumbsUp(features) else { return nil }
        return (assignment, 0)
      case .openPalm:
        guard isOpenPalm(features) else { return nil }
        return (assignment, 0)
      case .fingerGun:
        guard isFingerGun(features) else { return nil }
        return (assignment, 0)
      case .capturedPose:
        guard assignment.sample.count == features.count else { return nil }
        let differences = zip(features, assignment.sample).map { abs($0 - $1) }
        let straightnessDifferences = differences.prefix(5)
        let geometryDifferences = differences.dropFirst(5)
        guard
          let largestStraightnessDifference = straightnessDifferences.max(),
          let largestGeometryDifference = geometryDifferences.max(),
          largestStraightnessDifference <= 0.24,
          largestGeometryDifference <= 0.36
        else { return nil }
        let poseDistance = sqrt(differences.reduce(0) { $0 + $1 * $1 } / Double(differences.count))
        guard poseDistance <= 0.18 else { return nil }
        return (assignment, poseDistance)
      }
    }

    return candidates.min { $0.1 < $1.1 }?.0
  }

  private static func isPeaceSign(_ features: [Double]) -> Bool {
    guard features.count == featureCount else { return false }
    let index = features[1]
    let middle = features[2]
    let ring = features[3]
    let little = features[4]
    return index >= 0.82 && middle >= 0.82 && ring < 0.78 && little < 0.78
  }

  private static func isThumbsUp(_ features: [Double]) -> Bool {
    guard features.count == featureCount else { return false }
    return features[0] >= 0.82 && features[1...4].allSatisfy { $0 < 0.64 }
  }

  private static func isOpenPalm(_ features: [Double]) -> Bool {
    guard features.count == featureCount else { return false }
    return features[0...4].allSatisfy { $0 >= 0.84 }
  }

  private static func isFingerGun(_ features: [Double]) -> Bool {
    guard features.count == featureCount else { return false }
    return features[0] >= 0.78
      && features[1] >= 0.82
      && features[2...4].allSatisfy { $0 < 0.64 }
  }

  private static func distance(_ first: CGPoint, _ second: CGPoint) -> Double {
    hypot(Double(first.x - second.x), Double(first.y - second.y))
  }
}
