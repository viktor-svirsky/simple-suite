import XCTest
import SwiftData
@testable import SimpleNotes

final class NoteModelTests: XCTestCase {
    private func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: Note.self, configurations: config)
    }

    func test_insertingNote_persistsAndRetrievesIt() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let note = Note(body: "Hello world")
        context.insert(note)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<Note>())
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.body, "Hello world")
    }

    func test_newNote_hasDefaultTimestampsAndIsNotPinned() throws {
        let before = Date()
        let note = Note(body: "x")
        let after = Date()

        XCTAssertFalse(note.isPinned)
        XCTAssertGreaterThanOrEqual(note.createdAt, before)
        XCTAssertLessThanOrEqual(note.createdAt, after)
        XCTAssertEqual(note.createdAt, note.updatedAt)
    }
}
