import Foundation
import SwiftData

enum NoteActions {
    static func togglePin(_ note: Note) {
        note.isPinned.toggle()
        note.touch()
    }

    static func delete(_ note: Note, in context: ModelContext) {
        context.delete(note)
    }
}
