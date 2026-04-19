import Foundation
import SwiftData

/// Runs a `SearchQuery` against a `ModelContext`, combining the scope
/// predicate (pushed to SwiftData) with in-memory filtering for folder-name,
/// tag, and free-text tokens. Keeping the query-side filter in Swift avoids
/// SwiftData `#Predicate` limitations (non-storable keypaths like
/// `folder?.name.localizedLowercase`) and keeps the compiler out of the
/// "unable to type-check" corner of large composite predicates.
enum NoteSearch {
    static func run(
        query: SearchQuery,
        base: NoteListScope = .all,
        in context: ModelContext
    ) throws -> [Note] {
        let descriptor = FetchDescriptor<Note>(
            predicate: base.predicate,
            sortBy: NoteListScope.sortDescriptors
        )
        let notes = try context.fetch(descriptor)
        return notes.filter { matches(query: query, note: $0) }
    }

    static func matches(query: SearchQuery, note: Note) -> Bool {
        if let folderName = query.folderName,
           note.folder?.name.localizedLowercase != folderName {
            return false
        }
        for name in query.tags where !note.tags.contains(where: { $0.name == name }) {
            return false
        }
        if !query.text.isEmpty,
           note.body.range(of: query.text, options: [.caseInsensitive, .diacriticInsensitive]) == nil {
            return false
        }
        return true
    }
}
