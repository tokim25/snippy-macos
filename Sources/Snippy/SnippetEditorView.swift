import SwiftUI

struct SnippetEditorView: View {
    @EnvironmentObject private var store: SnippetStore
    @Environment(\.dismiss) private var dismiss

    let snippet: Snippet?

    @State private var trigger: String = ""
    @State private var expansion: String = ""
    @State private var folder: String = ""
    @State private var errorMessage: String?

    private var isEditing: Bool { snippet != nil }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(isEditing ? "Edit Snippet" : "New Snippet")
                .font(.headline)

            VStack(alignment: .leading, spacing: 4) {
                Text("Trigger").font(.caption).foregroundStyle(.secondary)
                TextField(";addr", text: $trigger)
                    .font(.system(.body, design: .monospaced))
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Expansion").font(.caption).foregroundStyle(.secondary)
                TextEditor(text: $expansion)
                    .font(.body)
                    .frame(height: 90)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.secondary.opacity(0.3)))
                Text("Tokens: {date}  {time}  {clipboard}  {cursor}  {fill:Label}")
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Folder (optional)").font(.caption).foregroundStyle(.secondary)
                TextField("e.g. Work", text: $folder)
                    .textFieldStyle(.roundedBorder)
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                Button(isEditing ? "Save" : "Add") { save() }
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 360)
        .onAppear {
            if let snippet {
                trigger = snippet.trigger
                expansion = snippet.expansion
                folder = snippet.folder ?? ""
            }
        }
    }

    private func save() {
        do {
            if let snippet {
                try store.update(snippet, trigger: trigger, expansion: expansion, folder: folder)
            } else {
                try store.add(trigger: trigger, expansion: expansion, folder: folder)
            }
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
