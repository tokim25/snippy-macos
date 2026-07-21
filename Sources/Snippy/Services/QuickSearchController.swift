import AppKit
import SwiftUI

/// A floating search panel toggled by a global hotkey — find a snippet by
/// name and insert it directly, without needing to remember or type its
/// trigger. Unlike a normal expansion there's no typed trigger to delete
/// first, so injection happens with an empty trigger (a no-op delete).
final class QuickSearchController: NSObject {
    private let store: SnippetStore
    private let injector: TextInjector
    private let fillPanel = FillFieldsPanelController()
    private var panel: NSPanel?

    init(store: SnippetStore, injector: TextInjector) {
        self.store = store
        self.injector = injector
    }

    func toggle() {
        if panel != nil {
            close()
        } else {
            present()
        }
    }

    private func present() {
        let contentView = QuickSearchView(
            snippets: store.snippets,
            onSelect: { [weak self] snippet in self?.select(snippet) },
            onCancel: { [weak self] in self?.close() }
        )

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 320),
            styleMask: [.titled, .closable, .utilityWindow],
            backing: .buffered,
            defer: false
        )
        panel.title = "Quick Search"
        panel.contentView = NSHostingView(rootView: contentView)
        panel.isReleasedWhenClosed = false
        panel.level = .floating
        panel.center()

        self.panel = panel
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
    }

    private func close() {
        panel?.close()
        panel = nil
    }

    private func select(_ snippet: Snippet) {
        close()
        let template = SnippetTemplate(snippet.expansion)
        let fieldNames = template.fillFieldNames

        guard !fieldNames.isEmpty else {
            NSApp.hide(nil)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [injector] in
                let clipboard = NSPasteboard.general.string(forType: .string)
                let rendered = template.render(fillValues: [:], clipboard: clipboard)
                injector.expand(trigger: "", into: rendered.text, cursorOffsetFromEnd: rendered.cursorOffsetFromEnd)
            }
            return
        }

        fillPanel.present(fieldNames: fieldNames) { [injector] values in
            guard let values else { return }
            let clipboard = NSPasteboard.general.string(forType: .string)
            let rendered = template.render(fillValues: values, clipboard: clipboard)
            injector.expand(trigger: "", into: rendered.text, cursorOffsetFromEnd: rendered.cursorOffsetFromEnd)
        }
    }
}
