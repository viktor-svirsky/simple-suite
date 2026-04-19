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

    func test_touch_updatesUpdatedAtWithoutChangingCreatedAt() throws {
        let created = Date(timeIntervalSince1970: 1_000_000)
        let note = Note(body: "x", createdAt: created)
        XCTAssertEqual(note.updatedAt, created)

        let later = Date(timeIntervalSince1970: 1_000_100)
        note.touch(later)

        XCTAssertEqual(note.createdAt, created)
        XCTAssertEqual(note.updatedAt, later)
    }

    func test_title_derivedFromFirstNonEmptyLine() {
        let n = Note(body: "  \n\nHello world\nsecond line\n")
        XCTAssertEqual(n.title, "Hello world")
    }

    func test_title_trimmedAndTruncatedTo80Chars() {
        let long = String(repeating: "a", count: 120)
        let n = Note(body: "   \(long)   ")
        XCTAssertEqual(n.title.count, 80)
        XCTAssertEqual(n.title, String(repeating: "a", count: 80))
    }

    func test_title_emptyBodyYieldsNewNoteLabel() {
        let n = Note(body: "")
        XCTAssertEqual(n.title, "New Note")
        let n2 = Note(body: "   \n\n")
        XCTAssertEqual(n2.title, "New Note")
    }

    func test_preview_skipsFirstLineAndTrims() {
        let n = Note(body: "Headline\nBody first sentence. Body second sentence.")
        XCTAssertEqual(n.preview, "Body first sentence. Body second sentence.")
    }

    func test_preview_emptyBodyIsEmpty() {
        XCTAssertEqual(Note(body: "Only headline").preview, "")
        XCTAssertEqual(Note(body: "").preview, "")
    }
}
