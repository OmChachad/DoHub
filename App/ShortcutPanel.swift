import SwiftUI

struct ShortcutPanel: View {
  var assignments: [GestureAssignment]
  var onRun: (GestureAssignment) -> Void
  var onManage: () -> Void

  private var columns: [GridItem] {
    [
      GridItem(.flexible(), spacing: 12),
      GridItem(.flexible(), spacing: 12)
    ]
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 16) {
        HStack(alignment: .top) {
          VStack(alignment: .leading, spacing: 4) {
            Text("Gesture shortcuts")
              .font(.title2.weight(.semibold))

            Text("Tap a card to run it. Start tracking to run shortcuts with gestures.")
              .font(.subheadline)
              .foregroundStyle(.secondary)
          }

          Spacer(minLength: 8)

          Button("Add gesture", systemImage: "plus") {
            onManage()
          }
          .labelStyle(.iconOnly)
          .accessibilityLabel("Add or manage gestures")
          .buttonStyle(.bordered)
        }

        LazyVGrid(columns: columns, spacing: 12) {
          ForEach(assignments) { assignment in
            GestureShortcutTile(assignment: assignment, onRun: onRun)
          }
        }

        VStack(alignment: .leading, spacing: 8) {
          Label("Connect Apple Shortcuts", systemImage: "arrow.up.right.square")
            .font(.headline)

          Text("Create matching shortcuts in Apple’s Shortcuts app, such as “Open Clock” with an Open App action for Clock. Gesture actions stay paused until you tap Start tracking.")
            .font(.subheadline)
            .foregroundStyle(.secondary)

          Text("Starter gestures suggest Open Clock, Open Photos, Open Camera, and Open Messages. Create each matching shortcut or change its name in Manage Gestures.")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
          Color(uiColor: .secondarySystemGroupedBackground),
          in: RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
      }
      .frame(maxWidth: 600, alignment: .leading)
      .frame(maxWidth: .infinity)
      .padding(16)
    }
    .scrollIndicators(.hidden)
    .scrollBounceBehavior(.basedOnSize)
  }
}

private struct GestureShortcutTile: View {
  var assignment: GestureAssignment
  var onRun: (GestureAssignment) -> Void

  var body: some View {
    Button {
      onRun(assignment)
    } label: {
      VStack(alignment: .leading, spacing: 9) {
        Image(systemName: assignment.kind.symbolName)
          .font(.title2)
          .foregroundStyle(.tint)
          .accessibilityHidden(true)

        Text(assignment.name)
          .font(.headline)
          .foregroundStyle(.primary)
          .lineLimit(2)

        Text(assignment.kind.shortInstruction)
          .font(.caption)
          .foregroundStyle(.secondary)

        Label(assignment.shortcutName, systemImage: "play.fill")
          .font(.caption)
          .foregroundStyle(.secondary)
          .lineLimit(2)
          .labelStyle(.titleAndIcon)
      }
      .frame(maxWidth: .infinity, minHeight: 144, alignment: .leading)
      .padding(14)
      .background(
        Color(uiColor: .secondarySystemGroupedBackground),
        in: RoundedRectangle(cornerRadius: 20, style: .continuous)
      )
      .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
    .buttonStyle(.plain)
    .accessibilityLabel("Run \(assignment.shortcutName), assigned to \(assignment.name)")
  }
}
