import SwiftUI
import AppKit

struct MenuBarContentView: View {
    @EnvironmentObject private var store: SnippetStore
    @EnvironmentObject private var permissions: PermissionManager
    @EnvironmentObject private var hotkeyManager: HotkeyManager
    @EnvironmentObject private var pauseController: PauseController
    @Environment(\.openWindow) private var openWindow

    private var statusColor: Color {
        guard permissions.isTrusted else { return .orange }
        return pauseController.isPaused ? .gray : .green
    }

    private var statusText: String {
        guard permissions.isTrusted else { return "Accessibility permission needed" }
        return pauseController.isPaused ? "Expansion is paused" : "Expansion is active"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
                Text(statusText)
                    .font(.headline)
            }

            if !permissions.isTrusted {
                Button("Grant Accessibility Access") {
                    permissions.requestPermission()
                    permissions.openAccessibilitySettings()
                }
                Text("Snippy needs this to see what you type and expand triggers anywhere on the Mac.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Button(pauseController.isPaused ? "Resume Expansion" : "Pause Expansion") {
                    pauseController.toggle()
                }
            }

            Divider()

            Text("\(store.snippets.count) snippet\(store.snippets.count == 1 ? "" : "s")")
                .font(.caption)
                .foregroundStyle(.secondary)

            Button("Manage Snippets…") {
                openWindow(id: "manage")
                NSApp.activate(ignoringOtherApps: true)
            }

            Text("Quick Search: \(hotkeyManager.displayString)")
                .font(.caption)
                .foregroundStyle(.secondary)

            Divider()

            Button("Quit Snippy") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding(14)
        .frame(width: 260)
    }
}
