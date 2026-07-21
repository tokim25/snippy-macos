import AppKit
import SwiftUI

/// A borderless, click-through overlay that doesn't steal keyboard focus —
/// `orderFrontRegardless()` shows it without activating Snippy, so whatever
/// app you were typing in keeps focus the whole time.
final class ConfettiOverlayController {
    private var window: NSWindow?

    func show(duration: TimeInterval = 3.2) {
        guard let screen = NSScreen.main else { return }

        let window = NSWindow(
            contentRect: screen.frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false,
            screen: screen
        )
        window.isOpaque = false
        window.backgroundColor = .clear
        window.ignoresMouseEvents = true
        window.hasShadow = false
        window.level = .screenSaver
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]
        window.contentView = NSHostingView(rootView: ConfettiView())
        window.orderFrontRegardless()

        self.window = window

        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            self?.window?.close()
            self?.window = nil
        }
    }
}
