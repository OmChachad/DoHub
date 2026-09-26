import SwiftData
import SwiftUI

/// The output history shown in place on the top screen, expanded from the history button.
struct OutputHistoryPanel: View {
    var onClose: () -> Void

    @Environment(ShortcutRunner.self) private var runner
    @Namespace private var namespace
    @Query(ShortcutRunRecord.latestDescriptor) private var latestRecords: [ShortcutRunRecord]
    @State private var isConfirmingClear = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Text("Output History")
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)
                Spacer(minLength: 8)
                Button("Clear History", systemImage: "trash") {
                    isConfirmingClear = true
                }
                .disabled(latestRecords.isEmpty)
                Button("Close", systemImage: "xmark", action: onClose)
            }
            .labelStyle(.iconOnly)
            .font(.body.weight(.semibold))
            .buttonStyle(.bordered)
            .buttonBorderShape(.circle)
            .padding(.horizontal)
            .padding(.top, 12)

            OutputHistoryView(namespace: namespace, usesGlass: false)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .confirmationDialog("Clear Output History?", isPresented: $isConfirmingClear, titleVisibility: .visible) {
            Button("Clear History", role: .destructive) {
                withAnimation(.smooth) { runner.clearHistory() }
            }
        } message: {
            Text("Every saved shortcut output will be deleted.")
        }
    }
}
