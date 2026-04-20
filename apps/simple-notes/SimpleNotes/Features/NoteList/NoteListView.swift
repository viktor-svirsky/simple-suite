import SwiftUI
import SwiftData

struct NoteListView: View {
    let scope: NoteListScope
    @Binding var selection: UUID?

    @Environment(\.modelContext) private var modelContext
    @Query private var notes: [Note]
    @State private var searchText: String = ""

    init(scope: NoteListScope, selection: Binding<UUID?>) {
        self.scope = scope
        self._selection = selection
        _notes = Query(
            filter: scope.predicate,
            sort: NoteListScope.sortDescriptors
        )
    }

    private var parsedQuery: SearchQuery {
        SearchQueryParser.parse(searchText)
    }

    private var filteredNotes: [Note] {
        let q = parsedQuery
        guard !q.isEmpty else { return notes }
        return notes.filter { NoteSearch.matches(query: q, note: $0) }
    }

    var body: some View {
        Group {
            if filteredNotes.isEmpty {
                ContentUnavailableView(
                    parsedQuery.isEmpty ? "No notes yet" : "No matches",
                    systemImage: parsedQuery.isEmpty ? "square.and.pencil" : "magnifyingglass",
                    description: Text(
                        parsedQuery.isEmpty
                            ? "Tap + to create one."
                            : "Try a different search."
                    )
                )
            } else {
                List(selection: $selection) {
                    ForEach(filteredNotes) { note in
                        NavigationLink(value: note.id) {
                            NoteListRow(
                                title: note.title,
                                preview: note.preview,
                                meta: NoteListScope.relativeDateString(for: note.updatedAt),
                                tags: [],
                                isPinned: note.isPinned
                            )
                        }
                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                            Button {
                                NoteActions.togglePin(note)
                            } label: {
                                Label(
                                    note.isPinned ? "Unpin" : "Pin",
                                    systemImage: note.isPinned ? "pin.slash" : "pin"
                                )
                            }
                            .tint(Theme.Color.muted)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                if selection == note.id { selection = nil }
                                NoteActions.delete(note, in: modelContext)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .searchable(text: $searchText, prompt: "Search #tag folder:name text")
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
        if case .folder(let id, _) = scope,
           let folder = try? modelContext.fetch(
               FetchDescriptor<Folder>(predicate: #Predicate { $0.id == id })
           ).first {
            note.folder = folder
        }
        modelContext.insert(note)
        selection = note.id
    }
}

#Preview {
    NavigationStack {
        NoteListView(scope: .all, selection: .constant(nil))
    }
    .modelContainer(for: [Note.self, Folder.self, Tag.self], inMemory: true)
}
