import SwiftUI

struct ManageView: View {
    var body: some View {
        TabView {
            SnippetsListView()
                .tabItem { Label("Snippets", systemImage: "list.bullet") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
        .frame(width: 440, height: 440)
    }
}
