import SwiftUI
import SwiftData

struct SidebarView: View {
    @Binding var selectedScope: NoteListScope
    @Binding var scrollTarget: UUID?

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Note.updatedAt, order: .reverse) private var allNotes: [Note]
    @Query(sort: [SortDescriptor(\Folder.sortOrder), SortDescriptor(\Folder.name)])
    private var folders: [Folder]
    @Query private var tagsRaw: [Tag]

    @State private var renameTarget: Folder?
    @State private var renameText: String = ""

    private var pinnedCount: Int { allNotes.filter(\.isPinned).count }

    private var tags: [Tag] {
        tagsRaw.sorted {
            if $0.notes.count != $1.notes.count {
                return $0.notes.count > $1.notes.count
            }
            return $0.name < $1.name
        }
    }

    private var scopeSelection: Binding<NoteListScope?> {
        Binding(
            get: { selectedScope },
            set: { if let new = $0 { selectedScope = new } }
        )
    }

    private var renameBinding: Binding<Bool> {
        Binding(
            get: { renameTarget != nil },
            set: { if !$0 { renameTarget = nil } }
        )
    }

    var body: some View {
        List(selection: scopeSelection) {
            Section("Library") {
                libraryRow("All Notes", count: allNotes.count, systemImage: "tray", scope: .all)
                libraryRow("Pinned", count: pinnedCount, systemImage: "pin", scope: .pinned)
            }
            Section("Folders") {
                ForEach(folders) { folder in
                    folderRow(folder)
                }
                Button(action: addFolder) {
                    Label("New Folder", systemImage: "folder.badge.plus")
                        .font(Theme.Font.sans(16))
                }
            }
            if !tags.isEmpty {
                Section("Tags") {
                    ForEach(tags) { tag in
                        tagRow(tag)
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("simple notes")
        .alert("Rename folder", isPresented: renameBinding) {
            TextField("Name", text: $renameText)
            Button("Cancel", role: .cancel) {
                renameTarget = nil
            }
            Button("Rename") {
                let trimmed = renameText.trimmingCharacters(in: .whitespacesAndNewlines)
                if let target = renameTarget, !trimmed.isEmpty {
                    target.name = trimmed
                }
                renameTarget = nil
            }
        }
    }

    private func libraryRow(_ title: String, count: Int, systemImage: String, scope: NoteListScope) -> some View {
        NavigationLink(value: scope) {
            HStack {
                Label(title, systemImage: systemImage)
                    .font(Theme.Font.sans(16))
                Spacer()
                Text("\(count)")
                    .font(Theme.Font.mono(12))
                    .foregroundStyle(Theme.Color.muted)
            }
        }
    }

    private func folderRow(_ folder: Folder) -> some View {
        Button {
            if selectedScope != .all { selectedScope = .all }
            scrollTarget = folder.id
        } label: {
            HStack {
                Label(folder.name, systemImage: "folder")
                    .font(Theme.Font.sans(16))
                Spacer()
                Text("\(folder.notes.count)")
                    .font(Theme.Font.mono(12))
                    .foregroundStyle(Theme.Color.muted)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                deleteFolder(folder)
            } label: {
                Label("Delete", systemImage: "trash")
            }
            Button {
                renameText = folder.name
                renameTarget = folder
            } label: {
                Label("Rename", systemImage: "pencil")
            }
            .tint(Theme.Color.muted)
        }
    }

    private func tagRow(_ tag: Tag) -> some View {
        let scope = NoteListScope.tag(id: tag.id, name: tag.name)
        return NavigationLink(value: scope) {
            HStack {
                Text("#\(tag.name)")
                    .font(Theme.Font.sans(16))
                Spacer()
                Text("\(tag.notes.count)")
                    .font(Theme.Font.mono(12))
                    .foregroundStyle(Theme.Color.muted)
            }
        }
    }

    private func addFolder() {
        let next = (folders.map(\.sortOrder).max() ?? 0) + 1
        let folder = Folder(name: "New Folder", sortOrder: next)
        modelContext.insert(folder)
    }

    private func deleteFolder(_ folder: Folder) {
        if case .folder(let id, _) = selectedScope, id == folder.id {
            selectedScope = .all
        }
        modelContext.delete(folder)
    }
}

#Preview {
    NavigationStack {
        SidebarView(selectedScope: .constant(.all), scrollTarget: .constant(nil))
    }
    .modelContainer(for: [Note.self, Folder.self, Tag.self], inMemory: true)
}
