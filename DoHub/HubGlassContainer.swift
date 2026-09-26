import SwiftUI

/// A `GlassEffectContainer` on platforms with Liquid Glass. visionOS already draws its
/// own glass and has no `glassEffect`, so there it passes the content through.
struct HubGlassContainer<Content: View>: View {
    var spacing: CGFloat?
    @ViewBuilder var content: Content

    var body: some View {
        #if os(visionOS)
        content
        #else
        GlassEffectContainer(spacing: spacing) {
            content
        }
        #endif
    }
}

extension View {
    /// Liquid Glass in `shape`, falling back to a material on visionOS.
    @ViewBuilder
    func hubGlass(in shape: some Shape, isInteractive: Bool = false) -> some View {
        #if os(visionOS)
        background(.regularMaterial, in: shape)
        #else
        glassEffect(.regular.interactive(isInteractive), in: shape)
        #endif
    }

    /// Associates glass with `id` so it morphs between views sharing the ID.
    @ViewBuilder
    func hubGlassID(_ id: some Hashable & Sendable, in namespace: Namespace.ID) -> some View {
        #if os(visionOS)
        self
        #else
        glassEffectID(id, in: namespace)
        #endif
    }
}
