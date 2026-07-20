import AppKit

/// Watches key-down events system-wide. Requires Accessibility permission to
/// receive events from apps other than this one.
final class EventMonitor {
    var onKeyDown: ((NSEvent) -> Void)?

    private var monitor: Any?

    func start() {
        stop()
        monitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.onKeyDown?(event)
        }
    }

    func stop() {
        if let monitor {
            NSEvent.removeMonitor(monitor)
        }
        monitor = nil
    }
}
