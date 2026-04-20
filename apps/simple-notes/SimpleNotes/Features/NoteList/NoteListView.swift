import SwiftUI
import SwiftData

struct NoteListView: View {
    let scope: NoteListScope
    @Binding var selection: UUID?
    @Binding var scrollTarget: UUID?

    @Environment(\.modelContext) private var modelContext
    @Query private var notes: [Note]
    @State private var searchText: String = ""

    private static let inboxAnchorID = UUID(uuidString: "00000000-0000-0000-0000-00000000B0C5")!

    init(scope: NoteListScope, selection: Binding<UUID?>) {
        self.init(scope: scope, selection: selection, scrollTarget: .constant(nil))
    }

    init(scope: NoteListScope, selection: Binding<UUID?>, scrollTarget: Binding<UUID?>) {
        self.scope = scope
        self._selection = selection
        self._scrollTarget = scrollTarget
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

    private var sections: [FolderSection] {
        NoteListGrouping.group(filteredNotes)
    }

    var body: some View {
        Group {
            if sections.isEmpty {
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
                ScrollViewReader { proxy in
                    List(selection: $selection) {
                        ForEach(sections) { section in
                            sectionView(section)
                        }
                    }
                    .listStyle(.plain)
                    .onChange(of: scrollTarget) { _, target in
                        guard let target else { return }
                        withAnimation {
                            proxy.scrollTo(target, anchor: .top)
                        }
                        scrollTarget = nil
                    }
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search #tag folder:name text")
        .navigationTitle(scope.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    createNote(in: nil)
                } label: {
                    Image(systemName: "square.and.pencil")
                }
                .accessibilityLabel("New Note")
            }
        }
    }

    @ViewBuilder
    private func sectionView(_ section: FolderSection) -> some View {
        Section {
            ForEach(section.notes) { note in
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
        } header: {
            sectionHeader(section)
        }
        .id(section.folder?.id ?? Self.inboxAnchorID)
    }

    @ViewBuilder
    private func sectionHeader(_ section: FolderSection) -> some View {
        HStack(spacing: 8) {
            Text(section.title)
                .font(Theme.Font.sans(13, weight: .semibold))
                .foregroundStyle(Theme.Color.text)
            Text("\(section.notes.count)")
                .font(Theme.Font.mono(11))
                .foregroundStyle(Theme.Color.muted)
            Spacer()
            Button {
                createNote(in: section.folder)
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 13, weight: .semibold))
            }
            .buttonStyle(.borderless)
            .accessibilityLabel("New Note in \(section.title)")
        }
    }

    private func createNote(in folder: Folder?) {
        let note = Note()
        if let folder {
            note.folder = folder
        } else if case .folder(let id, _) = scope,
                  let scopeFolder = try? modelContext.fetch(
                      FetchDescriptor<Folder>(predicate: #Predicate { $0.id == id })
                  ).first {
            note.folder = scopeFolder
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
