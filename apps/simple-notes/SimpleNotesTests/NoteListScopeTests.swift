import XCTest
import SwiftData
@testable import SimpleNotes

final class NoteListScopeTests: XCTestCase {
    func test_scope_all_includesEveryNote() {
        let pinned = Note(body: "P", isPinned: true)
        let plain = Note(body: "X")
        XCTAssertTrue(NoteListScope.all.includes(pinned))
        XCTAssertTrue(NoteListScope.all.includes(plain))
    }

    func test_scope_pinned_onlyIncludesPinned() {
        let pinned = Note(body: "P", isPinned: true)
        let plain = Note(body: "X")
        XCTAssertTrue(NoteListScope.pinned.includes(pinned))
        XCTAssertFalse(NoteListScope.pinned.includes(plain))
    }

    func test_relativeDate_today_showsTime() {
        let calendar = Calendar(identifier: .gregorian)
        let now = Date()
        let earlier = calendar.date(byAdding: .minute, value: -30, to: now)!
        let s = NoteListScope.relativeDateString(for: earlier, now: now)
        // Should include a colon from the time formatter ("9:12 AM" or similar).
        XCTAssertTrue(s.contains(":"))
    }

    func test_relativeDate_yesterday_isLiteral() {
        let calendar = Calendar(identifier: .gregorian)
        let now = calendar.date(from: DateComponents(year: 2026, month: 4, day: 19, hour: 10))!
        let y   = calendar.date(from: DateComponents(year: 2026, month: 4, day: 18, hour: 10))!
        XCTAssertEqual(NoteListScope.relativeDateString(for: y, now: now), "Yesterday")
    }

    func test_scope_folder_includesOnlyNotesInThatFolder() throws {
        let c = try ModelContainer(
            for: Note.self, Folder.self, Tag.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let ctx = ModelContext(c)
        let journal = Folder(name: "Journal")
        let work = Folder(name: "Work")
        ctx.insert(journal); ctx.insert(work)
        let a = Note(body: "A"); a.folder = journal
        let b = Note(body: "B"); b.folder = work
        ctx.insert(a); ctx.insert(b)
        try ctx.save()

        let scope = NoteListScope.folder(id: journal.id, name: journal.name)
        XCTAssertTrue(scope.includes(a))
        XCTAssertFalse(scope.includes(b))

        let matches = try ctx.fetch(FetchDescriptor<Note>(predicate: scope.predicate))
        XCTAssertEqual(matches.map(\.body), ["A"])
    }

    func test_scope_tag_includesOnlyNotesWithTag() throws {
        let c = try ModelContainer(
            for: Note.self, Folder.self, Tag.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let ctx = ModelContext(c)
        let t = Tag(name: "todo")
        ctx.insert(t)
        let a = Note(body: "A #todo"); a.tags = [t]
        let b = Note(body: "B")
        ctx.insert(a); ctx.insert(b)
        try ctx.save()

        let scope = NoteListScope.tag(id: t.id, name: t.name)
        XCTAssertTrue(scope.includes(a))
        XCTAssertFalse(scope.includes(b))
    }

    func test_title_folderAndTag() {
        let id = UUID()
        XCTAssertEqual(NoteListScope.folder(id: id, name: "Journal").title, "Journal")
        XCTAssertEqual(NoteListScope.tag(id: id, name: "todo").title, "#todo")
    }

    func test_relativeDate_olderThanAWeek_showsMonthDay() {
        let calendar = Calendar(identifier: .gregorian)
        let now = calendar.date(from: DateComponents(year: 2026, month: 4, day: 19))!
        let old = calendar.date(from: DateComponents(year: 2026, month: 4, day: 1))!
        let s = NoteListScope.relativeDateString(for: old, now: now)
        XCTAssertTrue(s.contains("Apr") || s.contains("4"))
    }
}
