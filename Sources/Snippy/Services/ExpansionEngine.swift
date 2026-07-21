import AppKit
import Combine

/// Buffers recently typed characters and fires an expansion when the buffer
/// ends with a known trigger at a word boundary.
final class ExpansionEngine {
    private let store: SnippetStore
    private let injector: TextInjector
    private let pauseController: PauseController
    private let fillPanel = FillFieldsPanelController()
    private let confetti = ConfettiOverlayController()
    private var buffer: String = ""
    private let bufferCap = 40
    private var pauseCancellable: AnyCancellable?

    /// Not a real snippet — never shown in Manage Snippets, never saved,
    /// stays hidden. Deletes itself and shows confetti; nothing is typed.
    private let easterEggTrigger = "@yay"

    /// Armed with the just-expanded trigger right after an expansion; the
    /// very next Cmd+Z retypes it instead of relying on the target app's own
    /// undo (which often only reverts the paste, not the deleted trigger).
    private var pendingUndoTrigger: String?

    private let backspaceKeyCode: UInt16 = 51
    private let returnKeyCode: UInt16 = 36
    private let tabKeyCode: UInt16 = 48
    private let escapeKeyCode: UInt16 = 53
    private let zKeyCode: UInt16 = 6

    init(store: SnippetStore, injector: TextInjector, pauseController: PauseController) {
        self.store = store
        self.injector = injector
        self.pauseController = pauseController

        pauseCancellable = pauseController.$isPaused
            .filter { $0 }
            .sink { [weak self] _ in self?.buffer = "" }
    }

    func handle(_ event: NSEvent) {
        guard event.type == .keyDown else { return }
        guard !pauseController.isPaused else { return }

        if isUndoCombo(event), let trigger = pendingUndoTrigger {
            pendingUndoTrigger = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [injector] in
                injector.retype(trigger)
            }
            return
        }
        pendingUndoTrigger = nil

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

        if matchesBufferEnd(easterEggTrigger), isWordBoundary(for: easterEggTrigger) {
            buffer = ""
            injector.deleteOnly(count: easterEggTrigger.count)
            confetti.show()
            return
        }

        guard let match = store.snippets.first(where: { matchesBufferEnd($0.trigger) && isAllowedInFrontmostApp($0) }),
              isWordBoundary(for: match.trigger) else { return }

        let typedTrigger = String(buffer.suffix(match.trigger.count))
        buffer = ""
        perform(match, typedTrigger: typedTrigger)
    }

    private func isUndoCombo(_ event: NSEvent) -> Bool {
        event.keyCode == zKeyCode
            && event.modifierFlags.contains(.command)
            && !event.modifierFlags.contains(.shift)
    }

    /// Case-insensitive so typing a trigger capitalized or in ALL CAPS still
    /// matches — `perform` derives the case style from what was actually typed.
    private func matchesBufferEnd(_ trigger: String) -> Bool {
        guard buffer.count >= trigger.count else { return false }
        return buffer.suffix(trigger.count).lowercased() == trigger.lowercased()
    }

    private func isWordBoundary(for trigger: String) -> Bool {
        let triggerStart = buffer.index(buffer.endIndex, offsetBy: -trigger.count)
        return triggerStart == buffer.startIndex
            || !buffer[buffer.index(before: triggerStart)].isLetter
            && !buffer[buffer.index(before: triggerStart)].isNumber
    }

    private func isAllowedInFrontmostApp(_ snippet: Snippet) -> Bool {
        guard !snippet.restrictedApps.isEmpty else { return true }
        guard let bundleID = NSWorkspace.shared.frontmostApplication?.bundleIdentifier else { return true }
        return snippet.restrictedApps.contains { $0.bundleIdentifier == bundleID }
    }

    private func perform(_ snippet: Snippet, typedTrigger: String) {
        let template = SnippetTemplate(snippet.expansion)
        let fieldNames = template.fillFieldNames
        let caseStyle = SnippetCaseStyle(matchingTypedTrigger: typedTrigger)

        guard !fieldNames.isEmpty else {
            inject(trigger: snippet.trigger, template: template, fillValues: [:], caseStyle: caseStyle)
            return
        }

        fillPanel.present(fieldNames: fieldNames) { [weak self] values in
            guard let self, let values else { return }
            self.inject(trigger: snippet.trigger, template: template, fillValues: values, caseStyle: caseStyle)
        }
    }

    private func inject(trigger: String, template: SnippetTemplate, fillValues: [String: String], caseStyle: SnippetCaseStyle) {
        let clipboard = NSPasteboard.general.string(forType: .string)
        let rendered = template.render(fillValues: fillValues, clipboard: clipboard)
        let finalText = caseStyle.apply(to: rendered.text)
        injector.expand(trigger: trigger, into: finalText, cursorOffsetFromEnd: rendered.cursorOffsetFromEnd)
        pendingUndoTrigger = trigger
    }
}

/// Derived from the letters in what was actually typed, not the snippet's
/// stored trigger — typing ";ADDR" expands differently than ";addr".
private enum SnippetCaseStyle {
    case upper
    case capitalized
    case asTyped

    init(matchingTypedTrigger typedTrigger: String) {
        let letters = typedTrigger.filter { $0.isLetter }
        guard let first = letters.first else {
            self = .asTyped
            return
        }
        if letters == letters.uppercased() && letters != letters.lowercased() {
            self = .upper
        } else if first.isUppercase {
            self = .capitalized
        } else {
            self = .asTyped
        }
    }

    func apply(to text: String) -> String {
        switch self {
        case .upper:
            return text.uppercased()
        case .capitalized:
            guard !text.isEmpty else { return text }
            return text.prefix(1).uppercased() + text.dropFirst()
        case .asTyped:
            return text
        }
    }
}
