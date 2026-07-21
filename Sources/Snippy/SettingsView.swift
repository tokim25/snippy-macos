import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var permissions: PermissionManager
    @EnvironmentObject private var store: SnippetStore
    @EnvironmentObject private var hotkeyManager: HotkeyManager
    @StateObject private var loginItem = LoginItemManager()

    private static let syncedAtFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()

    var body: some View {
        Form {
            Section("Sync") {
                HStack(spacing: 8) {
                    Circle()
                        .fill(store.isICloudAvailable ? Color.green : Color.orange)
                        .frame(width: 8, height: 8)
                    Text(store.isICloudAvailable ? "Synced via iCloud Drive" : "iCloud Drive unavailable — snippets stay on this Mac")
                }
                if store.isICloudAvailable, let lastSyncedAt = store.lastSyncedAt {
                    Text("Last updated \(Self.syncedAtFormatter.string(from: lastSyncedAt))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Permission") {
                HStack(spacing: 8) {
                    Circle()
                        .fill(permissions.isTrusted ? Color.green : Color.orange)
                        .frame(width: 8, height: 8)
                    Text(permissions.isTrusted ? "Accessibility access granted" : "Accessibility access not granted")
                }
                if !permissions.isTrusted {
                    Button("Open Accessibility Settings") {
                        permissions.openAccessibilitySettings()
                    }
                }
            }

            Section("Quick Search") {
                HotkeyRecorderView(hotkeyManager: hotkeyManager)
                Text("Opens a search box to find and insert any snippet by name.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Startup") {
                Toggle("Launch Snippy at login", isOn: Binding(
                    get: { loginItem.isEnabled },
                    set: { loginItem.setEnabled($0) }
                ))
                if let lastError = loginItem.lastError {
                    Text(lastError)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
        }
        .padding(20)
        .onAppear {
            permissions.refresh()
            loginItem.refresh()
        }
    }
}
