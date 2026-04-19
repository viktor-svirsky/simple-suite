import SwiftUI
import SwiftData

struct NoteListView: View {
    let scope: NoteListScope
    @Binding var selection: UUID?

    @Environment(\.modelContext) private var modelContext
    @Query private var notes: [Note]

    init(scope: NoteListScope, selection: Binding<UUID?>) {
        self.scope = scope
        self._selection = selection
        _notes = Query(
            filter: scope.predicate,
            sort: NoteListScope.sortDescriptors
        )
    }

    var body: some View {
        Group {
            if notes.isEmpty {
                ContentUnavailableView(
                    "No notes yet",
                    systemImage: "square.and.pencil",
                    description: Text("Tap + to create one.")
                )
            } else {
                List(selection: $selection) {
                    ForEach(notes) { note in
                        NavigationLink(value: note.id) {
                            NoteListRow(
                                title: note.title,
                                preview: note.preview,
                                meta: NoteListScope.relativeDateString(for: note.updatedAt),
                                tags: [],
                                isPinned: note.isPinned
                            )
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle(scope.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: createNote) {
                    Image(systemName: "square.and.pencil")
                }
                .accessibilityLabel("New Note")
            }
        }
    }

    private func createNote() {
        let note = Note()
        modelContext.insert(note)
        selection = note.id
    }
}

#Preview {
    NavigationStack {
        NoteListView(scope: .all, selection: .constant(nil))
    }
    .modelContainer(for: [Note.self], inMemory: true)
}
