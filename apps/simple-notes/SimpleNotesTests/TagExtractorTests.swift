import XCTest
import SwiftData
@testable import SimpleNotes

final class TagExtractorTests: XCTestCase {
    private func context() throws -> ModelContext {
        ModelContext(
            try ModelContainer(
                for: Note.self, Folder.self, Tag.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
        )
    }

    func test_extracts_newTags_and_attachesToNote() throws {
        let ctx = try context()
        let note = Note(body: "hello #Work and #journal")
        ctx.insert(note)
        TagExtractor.apply(to: note, in: ctx)
        try ctx.save()
        XCTAssertEqual(Set(note.tags.map(\.name)), ["work", "journal"])
    }

    func test_reuses_existingTags() throws {
        let ctx = try context()
        let existing = Tag(name: "work")
        ctx.insert(existing)
        let note = Note(body: "hello #work")
        ctx.insert(note)
        TagExtractor.apply(to: note, in: ctx)
        try ctx.save()
        XCTAssertEqual(note.tags.count, 1)
        XCTAssertTrue(note.tags.contains { $0 === existing })
    }

    func test_removes_tagsNoLongerInBody() throws {
        let ctx = try context()
        let note = Note(body: "#a #b")
        ctx.insert(note)
        TagExtractor.apply(to: note, in: ctx)
        try ctx.save()
        XCTAssertEqual(Set(note.tags.map(\.name)), ["a", "b"])

        note.body = "only #a now"
        TagExtractor.apply(to: note, in: ctx)
        try ctx.save()
        XCTAssertEqual(Set(note.tags.map(\.name)), ["a"])
    }
}
