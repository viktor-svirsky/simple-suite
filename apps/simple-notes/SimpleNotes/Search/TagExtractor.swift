import Foundation
import SwiftData

enum TagExtractor {
    static func apply(to note: Note, in context: ModelContext) {
        let names = Set(
            MarkdownTagScanner.tags(in: note.body)
                .map { $0.name.lowercased() }
        )

        note.tags = note.tags.filter { names.contains($0.name) }

        for name in names where !note.tags.contains(where: { $0.name == name }) {
            let existing = try? context.fetch(
                FetchDescriptor<Tag>(predicate: #Predicate { $0.name == name })
            ).first
            let tag = existing ?? Tag(name: name)
            if existing == nil { context.insert(tag) }
            note.tags.append(tag)
        }
    }
}
