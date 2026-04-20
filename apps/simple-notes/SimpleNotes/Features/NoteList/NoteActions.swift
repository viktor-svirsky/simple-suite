import Foundation
import SwiftData

enum NoteActions {
    @MainActor
    static func togglePin(_ note: Note) {
        note.isPinned.toggle()
        note.touch()
        Haptics.fire(.pin)
    }

    @MainActor
    static func delete(_ note: Note, in context: ModelContext) {
        context.delete(note)
        Haptics.fire(.delete)
    }
}
