import ApplicationServices
import AppKit
import Combine

final class PermissionManager: ObservableObject {
    @Published private(set) var isTrusted: Bool = AXIsProcessTrusted()

    private var timer: Timer?

    func startPolling() {
        refresh()
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in
            self?.refresh()
        }
    }

    func refresh() {
        isTrusted = AXIsProcessTrusted()
    }

    /// Triggers the system's own Accessibility permission prompt.
    func requestPermission() {
        let key = kAXTrustedCheckOptionPrompt.takeRetainedValue() as String
        _ = AXIsProcessTrustedWithOptions([key: true] as CFDictionary)
    }

    func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
}
