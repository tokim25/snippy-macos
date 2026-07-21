import AppKit
import CoreGraphics

/// Replaces a just-typed trigger with its expansion: deletes the trigger
/// with simulated backspaces, then pastes the expansion via the clipboard
/// (saving and restoring whatever was on it beforehand).
final class TextInjector {
    private let deleteKeyCode: CGKeyCode = 0x33
    private let vKeyCode: CGKeyCode = 0x09
    private let leftArrowKeyCode: CGKeyCode = 0x7B

    /// Retypes literal text (e.g. restoring a trigger after Cmd+Z) via the
    /// same paste mechanism as `expand` — reusing it means this can't create
    /// a feedback loop through our own keystroke monitor the way per-character
    /// synthetic typing would.
    func retype(_ text: String) {
        pasteText(text)
    }

    /// Deletes typed characters without inserting anything — e.g. removing
    /// a hidden trigger that has no expansion text of its own.
    func deleteOnly(count: Int) {
        deleteCharacters(count: count)
    }

    func expand(trigger: String, into expansion: String, cursorOffsetFromEnd: Int? = nil) {
        deleteCharacters(count: trigger.count)
        pasteText(expansion)

        if let cursorOffsetFromEnd, cursorOffsetFromEnd > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
                self?.moveCursorLeft(count: cursorOffsetFromEnd)
            }
        }
    }

    private func moveCursorLeft(count: Int) {
        let source = CGEventSource(stateID: .hidSystemState)
        for _ in 0..<count {
            CGEvent(keyboardEventSource: source, virtualKey: leftArrowKeyCode, keyDown: true)?
                .post(tap: .cghidEventTap)
            CGEvent(keyboardEventSource: source, virtualKey: leftArrowKeyCode, keyDown: false)?
                .post(tap: .cghidEventTap)
        }
    }

    private func deleteCharacters(count: Int) {
        guard count > 0 else { return }
        let source = CGEventSource(stateID: .hidSystemState)
        for _ in 0..<count {
            CGEvent(keyboardEventSource: source, virtualKey: deleteKeyCode, keyDown: true)?
                .post(tap: .cghidEventTap)
            CGEvent(keyboardEventSource: source, virtualKey: deleteKeyCode, keyDown: false)?
                .post(tap: .cghidEventTap)
        }
    }

    private func pasteText(_ text: String) {
        let pasteboard = NSPasteboard.general
        let previous = pasteboard.string(forType: .string)
        let previousChangeCount = pasteboard.changeCount

        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)

        let source = CGEventSource(stateID: .hidSystemState)
        let vDown = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: true)
        vDown?.flags = .maskCommand
        let vUp = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: false)
        vUp?.flags = .maskCommand
        vDown?.post(tap: .cghidEventTap)
        vUp?.post(tap: .cghidEventTap)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            guard pasteboard.changeCount == previousChangeCount + 1 else { return }
            pasteboard.clearContents()
            if let previous {
                pasteboard.setString(previous, forType: .string)
            }
        }
    }
}
