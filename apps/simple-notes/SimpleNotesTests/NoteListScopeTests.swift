import XCTest
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

    func test_relativeDate_olderThanAWeek_showsMonthDay() {
        let calendar = Calendar(identifier: .gregorian)
        let now = calendar.date(from: DateComponents(year: 2026, month: 4, day: 19))!
        let old = calendar.date(from: DateComponents(year: 2026, month: 4, day: 1))!
        let s = NoteListScope.relativeDateString(for: old, now: now)
        XCTAssertTrue(s.contains("Apr") || s.contains("4"))
    }
}
