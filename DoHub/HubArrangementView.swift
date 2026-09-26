import SwiftUI

/// The inner-display layout: the top screen above the shortcuts deck, arranged around
/// the fold when the device is partially open.
struct HubArrangementView<Top: View, Deck: View>: View {
    @ViewBuilder var top: Top
    @ViewBuilder var deck: Deck

    var body: some View {
        #if os(iOS)
        if #available(iOS 27.1, *) {
            // A vertical split places the primary view on top, leaving the deck in the
            // bottom region, which suits touch controls.
            ArrangementView {
                top
            } secondary: {
                deck
            }
            .arrangementViewStyle(SplitArrangementViewStyle.split.axes(.vertical))
        } else {
            stacked
        }
        #else
        stacked
        #endif
    }

    private var stacked: some View {
        VStack(spacing: 0) {
            top
            deck
        }
    }
}
