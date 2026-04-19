import SwiftUI

struct SidebarView: View {
    var body: some View {
        List {
            Section("Library") {
                Label("All Notes", systemImage: "tray")
                Label("Pinned", systemImage: "pin")
            }
        }
        .navigationTitle("simple notes")
        .listStyle(.sidebar)
    }
}

#Preview { SidebarView() }
