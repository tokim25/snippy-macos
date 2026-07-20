import SwiftUI

struct SnippetsListView: View {
    @EnvironmentObject private var store: SnippetStore
    @State private var selection: Snippet.ID?
    @State private var editingSnippet: Snippet?
    @State private var isAddingNew = false

    private var groups: [(folder: String, snippets: [Snippet])] {
        let grouped = Dictionary(grouping: store.snippets) { $0.folder ?? "Ungrouped" }
        return grouped
            .sorted { lhs, rhs in
                if lhs.key == "Ungrouped" { return false }
                if rhs.key == "Ungrouped" { return true }
                return lhs.key < rhs.key
            }
            .map { (folder: $0.key, snippets: $0.value.sorted { $0.trigger < $1.trigger }) }
    }

    var body: some View {
        VStack(spacing: 0) {
            if store.snippets.isEmpty {
                VStack(spacing: 8) {
                    Text("No snippets yet").foregroundStyle(.secondary)
                    Button("Add your first snippet") { isAddingNew = true }
                }
                .frame(maxHeight: .infinity)
            } else {
                List(selection: $selection) {
                    ForEach(groups, id: \.folder) { group in
                        Section(group.folder) {
                            ForEach(group.snippets) { snippet in
                                SnippetRow(snippet: snippet)
                                    .contentShape(Rectangle())
                                    .onTapGesture(count: 2) { editingSnippet = snippet }
                            }
                        }
                    }
                }
                .listStyle(.inset)
                .onDeleteCommand { removeSelected() }
            }

            Divider()

            HStack(spacing: 0) {
                Spacer().frame(width: 6)

                FooterGlyphButton(systemImage: "plus", isEnabled: true, help: "Add a snippet") {
                    isAddingNew = true
                }

                Divider().frame(height: 12)

                FooterGlyphButton(systemImage: "minus", isEnabled: selection != nil, help: "Remove the selected snippet") {
                    removeSelected()
                }

                Spacer()

                if let selection, let selected = store.snippets.first(where: { $0.id == selection }) {
                    Text("Edit…")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .padding(.trailing, 10)
                        .contentShape(Rectangle())
                        .onTapGesture { editingSnippet = selected }
                }
            }
            .frame(height: 22)
            .background(.bar)
        }
        .sheet(item: $editingSnippet) { snippet in
            SnippetEditorView(snippet: snippet)
        }
        .sheet(isPresented: $isAddingNew) {
            SnippetEditorView(snippet: nil)
        }
    }

    private func removeSelected() {
        guard let selection, let snippet = store.snippets.first(where: { $0.id == selection }) else { return }
        store.remove(snippet)
        self.selection = nil
    }
}

/// A flat, glyph-only tap target with no button chrome — matches the native
/// +/- footer used by System Settings' own permission lists, which a plain
/// SwiftUI `Button` (even `.borderless`) no longer renders as on macOS 26.
private struct FooterGlyphButton: View {
    let systemImage: String
    let isEnabled: Bool
    let help: String
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        Image(systemName: systemImage)
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(isEnabled ? Color.primary : Color.secondary.opacity(0.35))
            .frame(width: 22, height: 20)
            .background(isHovering && isEnabled ? Color.secondary.opacity(0.15) : Color.clear)
            .contentShape(Rectangle())
            .onHover { isHovering = $0 }
            .onTapGesture { if isEnabled { action() } }
            .help(help)
    }
}

private struct SnippetRow: View {
    let snippet: Snippet

    var body: some View {
        HStack {
            Text(snippet.trigger)
                .font(.system(.body, design: .monospaced))
                .bold()
                .frame(width: 90, alignment: .leading)
            Text(snippet.expansion)
                .lineLimit(1)
                .truncationMode(.tail)
                .foregroundStyle(.secondary)
        }
    }
}
