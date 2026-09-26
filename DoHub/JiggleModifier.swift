import SwiftUI

/// Wiggles a view like Home Screen icons in edit mode. Each view gets its own tempo so
/// the deck doesn't move in lockstep. Stays still when Reduce Motion is on.
struct JiggleModifier: ViewModifier {
    var isActive: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var stepDuration = Double.random(in: 0.11...0.15)
    @State private var angle = Double.random(in: 1.2...1.8)

    @ViewBuilder
    func body(content: Content) -> some View {
        if isActive && !reduceMotion {
            content
                .keyframeAnimator(initialValue: 0.0, repeating: true) { content, rotation in
                    content.rotationEffect(.degrees(rotation))
                } keyframes: { _ in
                    CubicKeyframe(angle, duration: stepDuration)
                    CubicKeyframe(-angle, duration: stepDuration * 2)
                    CubicKeyframe(0, duration: stepDuration)
                }
        } else {
            content
        }
    }
}

extension View {
    func jiggle(_ isActive: Bool) -> some View {
        modifier(JiggleModifier(isActive: isActive))
    }
}
