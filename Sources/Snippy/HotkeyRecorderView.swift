import SwiftUI
import AppKit

/// Captures the next key combo pressed while recording, via a *local*
/// monitor (scoped to this app's own windows — no Accessibility permission
/// needed, unlike the global monitor Snippy uses for expansion).
private final class HotkeyRecorderSession: ObservableObject {
    private var monitor: Any?

    func start(onCapture: @escaping (UInt16, NSEvent.ModifierFlags) -> Void) {
        stop()
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            guard !modifiers.isEmpty else { return event }
            onCapture(event.keyCode, modifiers)
            return nil
        }
    }

    func stop() {
        if let monitor {
            NSEvent.removeMonitor(monitor)
        }
        monitor = nil
    }
}

struct HotkeyRecorderView: View {
    @ObservedObject var hotkeyManager: HotkeyManager
    @State private var isRecording = false
    @StateObject private var session = HotkeyRecorderSession()

    var body: some View {
        HStack(spacing: 8) {
            Text(isRecording ? "Press a key combo…" : hotkeyManager.displayString)
                .font(.system(.body, design: .monospaced))
                .frame(width: 150, alignment: .leading)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(RoundedRectangle(cornerRadius: 5).fill(Color.secondary.opacity(isRecording ? 0.25 : 0.12)))
                .overlay(RoundedRectangle(cornerRadius: 5).strokeBorder(Color.secondary.opacity(0.3)))

            Button(isRecording ? "Cancel" : "Change…") {
                isRecording.toggle()
            }

            if hotkeyManager.isCustomized {
                Button("Reset") { hotkeyManager.resetToDefault() }
            }
        }
        .onChange(of: isRecording) { _, recording in
            if recording {
                session.start { keyCode, modifiers in
                    hotkeyManager.set(keyCode: keyCode, modifiers: modifiers)
                    isRecording = false
                }
            } else {
                session.stop()
            }
        }
    }
}
