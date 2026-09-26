import Vision

/// Turns a Vision hand pose into a scale-independent feature vector: how straight each
/// finger is, how far each fingertip is from the palm, and the spread between fingertips.
nonisolated enum HandPoseFeatures {
    static let featureCount = 20

    private static let fingerJoints: [[VNHumanHandPoseObservation.JointName]] = [
        [.thumbCMC, .thumbMP, .thumbIP, .thumbTip],
        [.indexMCP, .indexPIP, .indexDIP, .indexTip],
        [.middleMCP, .middlePIP, .middleDIP, .middleTip],
        [.ringMCP, .ringPIP, .ringDIP, .ringTip],
        [.littleMCP, .littlePIP, .littleDIP, .littleTip],
    ]

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

        // Straightness: fingertip reach relative to the length of the finger's joint chain.
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

        let palmJoints = fingers.map { $0[0].location }
        let palmCenter = CGPoint(
            x: palmJoints.map(\.x).reduce(0, +) / CGFloat(palmJoints.count),
            y: palmJoints.map(\.y).reduce(0, +) / CGFloat(palmJoints.count)
        )
        let fingertips = fingers.map { $0[$0.count - 1].location }
        for tip in fingertips {
            values.append(distance(tip, palmCenter) / handScale)
        }
        for first in fingertips.indices {
            for second in fingertips.indices where second > first {
                values.append(distance(fingertips[first], fingertips[second]) / handScale)
            }
        }

        return values.count == featureCount ? values : nil
    }

    private static func distance(_ first: CGPoint, _ second: CGPoint) -> Double {
        hypot(Double(first.x - second.x), Double(first.y - second.y))
    }
}
