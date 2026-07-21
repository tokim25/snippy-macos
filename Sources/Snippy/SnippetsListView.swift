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

            HStack(spacing: 8) {
                HStack(spacing: 6) {
                    FooterGlyphButton(systemImage: "plus", isEnabled: true, help: "Add a snippet") {
                        isAddingNew = true
                    }
                    FooterGlyphButton(systemImage: "minus", isEnabled: selection != nil, help: "Remove the selected snippet") {
                        removeSelected()
                    }
                }

                Spacer()

                if let selection, let selected = store.snippets.first(where: { $0.id == selection }) {
                    Text("Edit…")
                        .font(.callout.weight(.medium))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(RoundedRectangle(cornerRadius: 5).fill(Color.secondary.opacity(0.15)))
                        .overlay(RoundedRectangle(cornerRadius: 5).strokeBorder(Color.secondary.opacity(0.3)))
                        .contentShape(Rectangle())
                        .onTapGesture { editingSnippet = selected }
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
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

/// A visibly-bordered glyph button — deliberately more prominent than the
/// native System-Settings-style +/- footer, since a flat hover-only glyph
/// turned out too easy to miss. Function over form here: always-on
/// background and border so it reads as a button at rest, not just on hover.
private struct FooterGlyphButton: View {
    let systemImage: String
    let isEnabled: Bool
    let help: String
    let action: () -> Void

    @State private var isHovering = false

    private var fillOpacity: Double {
        guard isEnabled else { return 0.06 }
        return isHovering ? 0.35 : 0.18
    }

    var body: some View {
        Image(systemName: systemImage)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(isEnabled ? Color.primary : Color.secondary.opacity(0.35))
            .frame(width: 28, height: 24)
            .background(RoundedRectangle(cornerRadius: 5).fill(Color.secondary.opacity(fillOpacity)))
            .overlay(RoundedRectangle(cornerRadius: 5).strokeBorder(Color.secondary.opacity(isEnabled ? 0.4 : 0.15)))
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
