import SwiftUI

/// The form section for choosing what a tile sends to its shortcut when it runs.
struct InputConfigurationSection: View {
    @Binding var mode: ShortcutInputMode
    /// The fixed input for `.text`, or the prompt for `.askEachTime`.
    @Binding var text: String
    @Binding var parameters: [ShortcutParameter]

    var body: some View {
        Section {
            Picker("Input", selection: $mode) {
                ForEach(ShortcutInputMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.menu)

            switch mode {
            case .none, .clipboard:
                EmptyView()
            case .text:
                TextField("Text", text: $text, axis: .vertical)
                    .lineLimit(2...8)
            case .askEachTime:
                TextField("Prompt (Optional)", text: $text)
            case .parameters:
                ForEach($parameters) { $parameter in
                    HStack {
                        TextField("Key", text: $parameter.key)
                            .autocorrectionDisabled()
                        Divider()
                        TextField("Value", text: $parameter.value)
                    }
                }
                .onDelete { offsets in
                    parameters.remove(atOffsets: offsets)
                }
                Button("Add Parameter", systemImage: "plus") {
                    parameters.append(ShortcutParameter())
                }
            }
        } header: {
            Text("Input")
        } footer: {
            Text(mode.footer)
        }
    }
}
