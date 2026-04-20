import SwiftUI
import SwiftData

struct RootView: View {
    @State private var scope: NoteListScope = .all
    @State private var selection: UUID?
    @State private var scrollTarget: UUID?

    var body: some View {
        NavigationSplitView {
            SidebarView(selectedScope: $scope, scrollTarget: $scrollTarget)
        } content: {
            NoteListView(scope: scope, selection: $selection, scrollTarget: $scrollTarget)
                .id(scope)
        } detail: {
            Group {
                if let id = selection,
                   let note = fetchNote(id: id) {
                    NoteEditorView(note: note)
                } else {
                    ContentUnavailableView("Select a note", systemImage: "text.alignleft")
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .tint(Theme.Color.accent)
    }

    @Environment(\.modelContext) private var modelContext

    private func fetchNote(id: UUID) -> Note? {
        var descriptor = FetchDescriptor<Note>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        return try? modelContext.fetch(descriptor).first
    }
}
