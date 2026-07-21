import SwiftUI
import AppKit

struct MenuBarContentView: View {
    @EnvironmentObject private var store: SnippetStore
    @EnvironmentObject private var permissions: PermissionManager
    @EnvironmentObject private var hotkeyManager: HotkeyManager
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Circle()
                    .fill(permissions.isTrusted ? Color.green : Color.orange)
                    .frame(width: 8, height: 8)
                Text(permissions.isTrusted ? "Expansion is active" : "Accessibility permission needed")
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
