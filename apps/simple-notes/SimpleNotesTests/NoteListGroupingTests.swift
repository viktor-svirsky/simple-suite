import XCTest
@testable import SimpleNotes

final class NoteListGroupingTests: XCTestCase {
    func test_groups_notesByFolder_preservingInboxFirst() {
        let journal = Folder(name: "Journal", sortOrder: 0)
        let work = Folder(name: "Work", sortOrder: 1)
        let a = Note(body: "a")
        let b = Note(body: "b"); b.folder = journal
        let c = Note(body: "c"); c.folder = work
        let d = Note(body: "d"); d.folder = work

        let sections = NoteListGrouping.group([a, b, c, d])

        XCTAssertEqual(sections.count, 3)
        XCTAssertNil(sections[0].folder)
        XCTAssertEqual(sections[0].notes.map(\.body), ["a"])
        XCTAssertEqual(sections[1].folder?.name, "Journal")
        XCTAssertEqual(sections[2].folder?.name, "Work")
        XCTAssertEqual(sections[2].notes.map(\.body), ["c", "d"])
    }

    func test_ordering_foldersBySortOrder() {
        let late = Folder(name: "Late", sortOrder: 10)
        let early = Folder(name: "Early", sortOrder: 0)
        let a = Note(body: "a"); a.folder = late
        let b = Note(body: "b"); b.folder = early
        let sections = NoteListGrouping.group([a, b])
        XCTAssertEqual(sections[0].folder?.name, "Early")
        XCTAssertEqual(sections[1].folder?.name, "Late")
    }

    func test_skipsInboxWhenEmpty() {
        let journal = Folder(name: "Journal", sortOrder: 0)
        let n = Note(body: "x"); n.folder = journal
        let sections = NoteListGrouping.group([n])
        XCTAssertEqual(sections.count, 1)
        XCTAssertEqual(sections[0].folder?.name, "Journal")
    }
}
