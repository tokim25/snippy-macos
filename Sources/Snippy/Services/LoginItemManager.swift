import ServiceManagement

/// Registers Snippy as a login item. Only takes effect once Snippy is
/// packaged and launched as a proper .app bundle — a bare SPM debug binary
/// isn't something `SMAppService` can register.
final class LoginItemManager: ObservableObject {
    @Published private(set) var isEnabled: Bool = SMAppService.mainApp.status == .enabled
    @Published var lastError: String?

    func refresh() {
        isEnabled = SMAppService.mainApp.status == .enabled
    }

    func setEnabled(_ enabled: Bool) {
        lastError = nil
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            lastError = error.localizedDescription
        }
        refresh()
    }
}
