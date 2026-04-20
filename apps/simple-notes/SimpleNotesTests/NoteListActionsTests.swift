import XCTest
import SwiftData
@testable import SimpleNotes

final class NoteListActionsTests: XCTestCase {
    private func makeContext() throws -> ModelContext {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Note.self, configurations: config)
        return ModelContext(container)
    }

    @MainActor
    func test_togglePin_flipsIsPinnedAndTouches() throws {
        let ctx = try makeContext()
        let n = Note(body: "x", createdAt: Date(timeIntervalSince1970: 0))
        ctx.insert(n)
        try ctx.save()
        XCTAssertFalse(n.isPinned)
        let before = n.updatedAt

        NoteActions.togglePin(n)

        XCTAssertTrue(n.isPinned)
        XCTAssertGreaterThan(n.updatedAt, before)
    }

    @MainActor
    func test_delete_removesFromContext() throws {
        let ctx = try makeContext()
        let n = Note(body: "x")
        ctx.insert(n)
        try ctx.save()
        XCTAssertEqual(try ctx.fetchCount(FetchDescriptor<Note>()), 1)

        NoteActions.delete(n, in: ctx)
        try ctx.save()

        XCTAssertEqual(try ctx.fetchCount(FetchDescriptor<Note>()), 0)
    }
}
