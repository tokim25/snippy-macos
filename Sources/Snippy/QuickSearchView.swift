import SwiftUI

struct QuickSearchView: View {
    let snippets: [Snippet]
    let onSelect: (Snippet) -> Void
    let onCancel: () -> Void

    @State private var query = ""
    @State private var selectedIndex = 0
    @FocusState private var isSearchFocused: Bool

    private var filtered: [Snippet] {
        guard !query.isEmpty else { return snippets }
        let needle = query.lowercased()
        return snippets.filter {
            $0.trigger.lowercased().contains(needle) || $0.expansion.lowercased().contains(needle)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            TextField("Search snippets…", text: $query)
                .textFieldStyle(.plain)
                .font(.title3)
                .padding(12)
                .focused($isSearchFocused)
                .onChange(of: query) { _, _ in selectedIndex = 0 }

            Divider()

            if filtered.isEmpty {
                Text("No matches")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 0) {
                            ForEach(Array(filtered.enumerated()), id: \.element.id) { index, snippet in
                                QuickSearchRow(snippet: snippet, isSelected: index == selectedIndex)
                                    .id(index)
                                    .contentShape(Rectangle())
                                    .onTapGesture { onSelect(snippet) }
                            }
                        }
                    }
                    .onChange(of: selectedIndex) { _, newValue in
                        proxy.scrollTo(newValue, anchor: .center)
                    }
                }
            }
        }
        .frame(width: 420, height: 320)
        .onAppear { isSearchFocused = true }
        .onKeyPress(.upArrow) {
            selectedIndex = max(0, selectedIndex - 1)
            return .handled
        }
        .onKeyPress(.downArrow) {
            selectedIndex = min(max(filtered.count - 1, 0), selectedIndex + 1)
            return .handled
        }
        .onKeyPress(.return) {
            if filtered.indices.contains(selectedIndex) {
                onSelect(filtered[selectedIndex])
            }
            return .handled
        }
        .onKeyPress(.escape) {
            onCancel()
            return .handled
        }
    }
}

private struct QuickSearchRow: View {
    let snippet: Snippet
    let isSelected: Bool

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
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
    }
}
