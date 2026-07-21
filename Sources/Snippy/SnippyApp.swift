import SwiftUI

@main
struct SnippyApp: App {
    @StateObject private var store: SnippetStore
    @StateObject private var permissions: PermissionManager
    @StateObject private var hotkeyManager: HotkeyManager

    private let eventMonitor = EventMonitor()
    private let engine: ExpansionEngine
    private let quickSearch: QuickSearchController

    init() {
        let store = SnippetStore()
        let permissions = PermissionManager()
        let hotkeyManager = HotkeyManager()
        _store = StateObject(wrappedValue: store)
        _permissions = StateObject(wrappedValue: permissions)
        _hotkeyManager = StateObject(wrappedValue: hotkeyManager)
        engine = ExpansionEngine(store: store, injector: TextInjector())
        quickSearch = QuickSearchController(store: store, injector: TextInjector())
    }

    var body: some Scene {
        MenuBarExtra("Snippy", systemImage: "keyboard") {
            MenuBarContentView()
                .environmentObject(store)
                .environmentObject(permissions)
                .environmentObject(hotkeyManager)
                .onAppear {
                    permissions.startPolling()
                    if permissions.isTrusted {
                        startMonitoring()
                    }
                }
                .onChange(of: permissions.isTrusted) { _, trusted in
                    if trusted {
                        startMonitoring()
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
                .environmentObject(hotkeyManager)
        }
        .windowResizability(.contentSize)
    }

    private func startMonitoring() {
        eventMonitor.onKeyDown = { [engine, quickSearch, hotkeyManager] event in
            if hotkeyManager.matches(event) {
                quickSearch.toggle()
            } else {
                engine.handle(event)
            }
        }
        eventMonitor.start()
    }
}
