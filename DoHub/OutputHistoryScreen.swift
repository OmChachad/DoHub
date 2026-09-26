import SwiftData
import SwiftUI

/// The full output history, presented from the history button.
struct OutputHistoryScreen: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(ShortcutRunner.self) private var runner
    @Namespace private var namespace
    @Query(ShortcutRunRecord.latestDescriptor) private var latestRecords: [ShortcutRunRecord]
    @State private var isConfirmingClear = false

    var body: some View {
        NavigationStack {
            OutputHistoryView(namespace: namespace)
                .navigationTitle("Output History")
                #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
                #endif
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(role: .close) {
                            dismiss()
                        }
                    }
                    ToolbarItem(placement: .primaryAction) {
                        Button("Clear History", systemImage: "trash", role: .destructive) {
                            isConfirmingClear = true
                        }
                        .disabled(latestRecords.isEmpty)
                    }
                }
                .confirmationDialog("Clear Output History?", isPresented: $isConfirmingClear, titleVisibility: .visible) {
                    Button("Clear History", role: .destructive) {
                        withAnimation(.smooth) { runner.clearHistory() }
                    }
                } message: {
                    Text("Every saved shortcut output will be deleted.")
                }
        }
    }
}
