import SwiftUI
import AppKit

struct SnippetEditorView: View {
    @EnvironmentObject private var store: SnippetStore
    @Environment(\.dismiss) private var dismiss

    let snippet: Snippet?

    @State private var trigger: String = ""
    @State private var expansion: String = ""
    @State private var folder: String = ""
    @State private var restrictedApps: [RestrictedApp] = []
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

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Limit to apps (optional)").font(.caption).foregroundStyle(.secondary)
                    Spacer()
                    Button("Add App…") { addApp() }
                        .font(.caption)
                }

                if restrictedApps.isEmpty {
                    Text("Fires in every app")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                } else {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(restrictedApps) { app in
                            HStack {
                                Text(app.displayName).font(.caption)
                                Spacer()
                                Button {
                                    restrictedApps.removeAll { $0.id == app.id }
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.secondary)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
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
                restrictedApps = snippet.restrictedApps
            }
        }
    }

    private func addApp() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.application]
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.prompt = "Choose"

        guard panel.runModal() == .OK,
              let url = panel.url,
              let bundle = Bundle(url: url),
              let bundleID = bundle.bundleIdentifier else { return }

        guard !restrictedApps.contains(where: { $0.bundleIdentifier == bundleID }) else { return }

        let displayName = FileManager.default.displayName(atPath: url.path)
            .replacingOccurrences(of: ".app", with: "")
        restrictedApps.append(RestrictedApp(bundleIdentifier: bundleID, displayName: displayName))
    }

    private func save() {
        do {
            if let snippet {
                try store.update(snippet, trigger: trigger, expansion: expansion, folder: folder, restrictedApps: restrictedApps)
            } else {
                try store.add(trigger: trigger, expansion: expansion, folder: folder, restrictedApps: restrictedApps)
            }
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
