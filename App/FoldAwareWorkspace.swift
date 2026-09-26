import SwiftUI

@available(iOS 27.1, *)
struct FoldAwareWorkspace<Controls: View, Preview: View, Flat: View>: View {
  var controls: Controls
  var preview: Preview
  var flat: Flat

  init(
    @ViewBuilder controls: () -> Controls,
    @ViewBuilder preview: () -> Preview,
    @ViewBuilder flat: () -> Flat
  ) {
    self.controls = controls()
    self.preview = preview()
    self.flat = flat()
  }

  var body: some View {
    GeometryReader { geometry in
      let hasActiveFold = geometry
        .reservedRegions(kind: .division)
        .contains(where: \.isActive)

      Group {
        if hasActiveFold {
          ArrangementView {
            preview
          } secondary: {
            controls
          }
          .arrangementViewStyle(.split.axes(.vertical))
        } else {
          flat
        }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .background(Color(uiColor: .systemGroupedBackground))
    }
  }
}
