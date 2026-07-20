import SwiftUI

@main
struct SnippyApp: App {
    @StateObject private var store: SnippetStore
    @StateObject private var permissions: PermissionManager

    private let eventMonitor = EventMonitor()
    private let engine: ExpansionEngine

    init() {
        let store = SnippetStore()
        let permissions = PermissionManager()
        _store = StateObject(wrappedValue: store)
        _permissions = StateObject(wrappedValue: permissions)
        engine = ExpansionEngine(store: store, injector: TextInjector())
    }

    var body: some Scene {
        MenuBarExtra("Snippy", systemImage: "keyboard") {
            MenuBarContentView()
                .environmentObject(store)
                .environmentObject(permissions)
                .onAppear {
                    permissions.startPolling()
                    if permissions.isTrusted {
                        eventMonitor.onKeyDown = engine.handle
                        eventMonitor.start()
                    }
                }
                .onChange(of: permissions.isTrusted) { _, trusted in
                    if trusted {
                        eventMonitor.onKeyDown = engine.handle
                        eventMonitor.start()
                    } else {
                        eventMonitor.stop()
                    }
                }
        }
        .menuBarExtraStyle(.window)

        Window("Snippy", id: "manage") {
            ManageView()
                .environmentObject(store)
                .environmentObject(permissions)
        }
        .windowResizability(.contentSize)
    }
}
