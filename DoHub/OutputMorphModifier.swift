import SwiftUI

/// Morphs output views into one another: matched geometry and glass for the shape,
/// a blur-replace for the content. Falls back to a cross-fade when Reduce Motion is on.
struct OutputMorphModifier<ID: Hashable & Sendable>: ViewModifier {
    var id: ID
    var namespace: Namespace.ID

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @ViewBuilder
    func body(content: Content) -> some View {
        if reduceMotion {
            content
                .transition(.opacity)
        } else {
            content
                .hubGlassID(id, in: namespace)
                .matchedGeometryEffect(id: id, in: namespace)
                .transition(.blurReplace)
        }
    }
}

extension View {
    func outputMorph(id: some Hashable & Sendable, in namespace: Namespace.ID) -> some View {
        modifier(OutputMorphModifier(id: id, namespace: namespace))
    }
}
