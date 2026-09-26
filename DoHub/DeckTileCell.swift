import SwiftUI

/// One tile in the deck, with its More menu, and Control Center–style delete and resize
/// handles while the deck is being edited.
struct DeckTileCell: View {
    var tile: ShortcutTile
    var isEditing: Bool
    var onRun: () -> Void
    var onEdit: () -> Void
    var onDelete: () -> Void

    @Environment(\.layoutDirection) private var layoutDirection
    @State private var tileWidth: CGFloat = 0
    @State private var resizeStart: (size: TileSize, cellWidth: CGFloat)?

    var body: some View {
        Button(action: isEditing ? onEdit : onRun) {
            ShortcutTileView(tile: tile)
        }
        .buttonStyle(TilePressStyle())
        .overlay(alignment: .topTrailing) {
            if !isEditing, tile.size == .wide {
                moreMenu
                    .padding(10)
            }
        }
        .overlay(alignment: .topLeading) {
            if isEditing {
                deleteBadge
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .overlay(alignment: .bottomTrailing) {
            if isEditing {
                resizeHandle
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .contextMenu {
            if !isEditing {
                actions
            }
        }
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { tileWidth = $0 }
        .sensoryFeedback(.impact(weight: .light), trigger: tile.size)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(tile.name)
        .accessibilityHint(isEditing ? "Edits the shortcut" : "Runs the shortcut")
        .accessibilityAction(named: "Edit", onEdit)
        .accessibilityAction(named: "Delete", onDelete)
    }

    @ViewBuilder
    private var actions: some View {
        Button("Edit…", systemImage: "pencil", action: onEdit)
        Picker("Size", systemImage: "square.resize", selection: Binding(
            get: { tile.size },
            set: { newSize in withAnimation(.smooth) { tile.size = newSize } }
        )) {
            ForEach(TileSize.allCases) { size in
                Text(size.title).tag(size)
            }
        }
        .pickerStyle(.menu)
        Divider()
        Button("Delete", systemImage: "trash", role: .destructive, action: onDelete)
    }

    private var moreMenu: some View {
        Menu {
            actions
        } label: {
            Label("More", systemImage: "ellipsis")
                .labelStyle(.iconOnly)
                .font(.footnote.weight(.bold))
                .foregroundStyle(tile.tint.foregroundColor)
                .frame(width: 28, height: 28)
                .background(tile.tint.foregroundColor.opacity(0.22), in: .circle)
                .contentShape(.circle)
        }
        .menuStyle(.button)
        .buttonStyle(.plain)
    }

    private var deleteBadge: some View {
        Button("Delete \(tile.name)", systemImage: "minus", action: onDelete)
            .labelStyle(.iconOnly)
            .font(.caption.weight(.heavy))
            .foregroundStyle(.primary)
            .frame(width: 26, height: 26)
            .hubGlass(in: .circle, isInteractive: true)
            .contentShape(.circle)
            .buttonStyle(.plain)
            .offset(x: layoutDirection == .rightToLeft ? 8 : -8, y: -8)
    }

    private var resizeHandle: some View {
        ResizeHandleShape()
            .stroke(.white, style: StrokeStyle(lineWidth: 5, lineCap: .round))
            .frame(width: 20, height: 20)
            .shadow(color: .black.opacity(0.25), radius: 3, y: 1)
            .padding(8)
            .frame(width: 44, height: 44, alignment: .bottomTrailing)
            .contentShape(.rect)
            .highPriorityGesture(resizeGesture)
            .accessibilityElement()
            .accessibilityLabel("Resize")
            .accessibilityValue(Text(tile.size.title))
            .accessibilityAdjustableAction { direction in
                withAnimation(.smooth) {
                    switch direction {
                    case .increment: tile.size = .wide
                    case .decrement: tile.size = .compact
                    @unknown default: break
                    }
                }
            }
    }

    /// Dragging the handle outward by half a cell widens the tile; dragging inward shrinks it.
    private var resizeGesture: some Gesture {
        DragGesture(minimumDistance: 2, coordinateSpace: .global)
            .onChanged { value in
                if resizeStart == nil {
                    let cellWidth = tile.size == .wide ? tileWidth / 2 : tileWidth
                    resizeStart = (tile.size, cellWidth)
                }
                guard let resizeStart else { return }
                let direction: CGFloat = layoutDirection == .rightToLeft ? -1 : 1
                let distance = value.translation.width * direction
                let threshold = resizeStart.cellWidth * 0.5
                let target: TileSize = switch resizeStart.size {
                case .compact: distance > threshold ? .wide : .compact
                case .wide: distance < -threshold ? .compact : .wide
                }
                if target != tile.size {
                    withAnimation(.snappy) { tile.size = target }
                }
            }
            .onEnded { _ in
                resizeStart = nil
            }
    }
}

/// Shrinks a tile slightly while it's pressed.
private struct TilePressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.snappy, value: configuration.isPressed)
    }
}

/// A quarter arc that follows a tile's bottom trailing corner, like Control Center's resize handle.
private struct ResizeHandleShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addArc(
            center: CGPoint(x: rect.minX, y: rect.minY),
            radius: min(rect.width, rect.height),
            startAngle: .degrees(0),
            endAngle: .degrees(90),
            clockwise: false
        )
        return path
    }
}
