import Foundation

struct FolderSection: Identifiable {
    var id: UUID? { folder?.id }
    let folder: Folder?
    let notes: [Note]

    var title: String { folder?.name ?? "Inbox" }
}

enum NoteListGrouping {
    static func group(_ notes: [Note]) -> [FolderSection] {
        var byFolder: [UUID: [Note]] = [:]
        var inbox: [Note] = []
        var foldersByID: [UUID: Folder] = [:]

        for note in notes {
            if let f = note.folder {
                byFolder[f.id, default: []].append(note)
                foldersByID[f.id] = f
            } else {
                inbox.append(note)
            }
        }

        var sections: [FolderSection] = []
        if !inbox.isEmpty {
            sections.append(FolderSection(folder: nil, notes: inbox))
        }
        let sortedFolders = foldersByID.values.sorted { lhs, rhs in
            if lhs.sortOrder != rhs.sortOrder {
                return lhs.sortOrder < rhs.sortOrder
            }
            return lhs.name < rhs.name
        }
        for folder in sortedFolders {
            let notes = byFolder[folder.id] ?? []
            sections.append(FolderSection(folder: folder, notes: notes))
        }
        return sections
    }
}
