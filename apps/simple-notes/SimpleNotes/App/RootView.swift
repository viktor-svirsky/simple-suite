import SwiftUI

struct RootView: View {
    var body: some View {
        NavigationSplitView {
            SidebarView()
        } content: {
            NoteListView()
        } detail: {
            NoteEditorView()
        }
        .tint(Theme.Color.accent)
    }
}

#Preview { RootView() }
