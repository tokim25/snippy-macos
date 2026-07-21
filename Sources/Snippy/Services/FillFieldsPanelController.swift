import AppKit
import SwiftUI

/// Shows a small floating panel prompting for `{fill:Name}` values before an
/// expansion is injected. Activates Snippy briefly to receive keystrokes,
/// then hides it again so focus returns to whatever the user was typing in.
final class FillFieldsPanelController: NSObject {
    private var panel: NSPanel?
    private var completion: (([String: String]?) -> Void)?

    func present(fieldNames: [String], completion: @escaping ([String: String]?) -> Void) {
        self.completion = completion

        let contentView = FillFieldsView(fieldNames: fieldNames) { [weak self] values in
            self?.finish(with: values)
        }

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 60 + CGFloat(fieldNames.count) * 56),
            styleMask: [.titled, .closable, .utilityWindow],
            backing: .buffered,
            defer: false
        )
        panel.title = "Fill in Snippet"
        panel.contentView = NSHostingView(rootView: contentView)
        panel.isReleasedWhenClosed = false
        panel.level = .floating
        panel.center()

        self.panel = panel

        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
    }

    private func finish(with values: [String: String]?) {
        panel?.close()
        panel = nil
        let handler = completion
        completion = nil

        NSApp.hide(nil)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            handler?(values)
        }
    }
}

private struct FillFieldsView: View {
    let fieldNames: [String]
    let onComplete: ([String: String]?) -> Void

    @State private var values: [String: String] = [:]
    @FocusState private var focusedField: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(fieldNames, id: \.self) { name in
                VStack(alignment: .leading, spacing: 4) {
                    Text(name)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("", text: binding(for: name))
                        .textFieldStyle(.roundedBorder)
                        .focused($focusedField, equals: name)
                        .onSubmit { onComplete(values) }
                }
            }

            HStack {
                Spacer()
                Button("Cancel") { onComplete(nil) }
                    .keyboardShortcut(.cancelAction)
                Button("Insert") { onComplete(values) }
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(16)
        .onAppear { focusedField = fieldNames.first }
    }

    private func binding(for name: String) -> Binding<String> {
        Binding(
            get: { values[name] ?? "" },
            set: { values[name] = $0 }
        )
    }
}
