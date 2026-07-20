import AppKit

/// Buffers recently typed characters and fires an expansion when the buffer
/// ends with a known trigger at a word boundary.
final class ExpansionEngine {
    private let store: SnippetStore
    private let injector: TextInjector
    private var buffer: String = ""
    private let bufferCap = 40

    private let backspaceKeyCode: UInt16 = 51
    private let returnKeyCode: UInt16 = 36
    private let tabKeyCode: UInt16 = 48
    private let escapeKeyCode: UInt16 = 53

    init(store: SnippetStore, injector: TextInjector) {
        self.store = store
        self.injector = injector
    }

    func handle(_ event: NSEvent) {
        guard event.type == .keyDown else { return }

        if !event.modifierFlags.intersection([.command, .control, .option]).isEmpty {
            buffer = ""
            return
        }

        switch event.keyCode {
        case backspaceKeyCode:
            if !buffer.isEmpty { buffer.removeLast() }
            return
        case returnKeyCode, tabKeyCode, escapeKeyCode:
            buffer = ""
            return
        default:
            break
        }

        guard let characters = event.characters, !characters.isEmpty else { return }
        buffer.append(characters)
        if buffer.count > bufferCap {
            buffer.removeFirst(buffer.count - bufferCap)
        }

        guard let match = store.snippets.first(where: { buffer.hasSuffix($0.trigger) }) else { return }

        let triggerStart = buffer.index(buffer.endIndex, offsetBy: -match.trigger.count)
        let isWordBoundary = triggerStart == buffer.startIndex
            || !buffer[buffer.index(before: triggerStart)].isLetter
            && !buffer[buffer.index(before: triggerStart)].isNumber

        guard isWordBoundary else { return }

        buffer = ""
        injector.expand(trigger: match.trigger, into: match.expansion)
    }
}
