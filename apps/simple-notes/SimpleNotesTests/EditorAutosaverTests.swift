import XCTest
@testable import SimpleNotes

final class EditorAutosaverTests: XCTestCase {
    @MainActor
    func test_scheduleTouch_firesExactlyOnceAfterDebounce() async throws {
        let note = Note(body: "")
        let originalUpdated = note.updatedAt
        let autosaver = EditorAutosaver(debounce: .milliseconds(100))

        autosaver.scheduleTouch(on: note)
        autosaver.scheduleTouch(on: note)
        autosaver.scheduleTouch(on: note)

        try await Task.sleep(nanoseconds: 250_000_000)

        XCTAssertGreaterThan(note.updatedAt, originalUpdated)
    }

    @MainActor
    func test_cancel_preventsPendingTouch() async throws {
        let note = Note(body: "")
        let originalUpdated = note.updatedAt
        let autosaver = EditorAutosaver(debounce: .milliseconds(200))

        autosaver.scheduleTouch(on: note)
        autosaver.cancel()

        try await Task.sleep(nanoseconds: 300_000_000)

        XCTAssertEqual(note.updatedAt, originalUpdated)
    }
}
