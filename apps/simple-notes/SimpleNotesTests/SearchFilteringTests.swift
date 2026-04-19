import XCTest
import SwiftData
@testable import SimpleNotes

final class SearchFilteringTests: XCTestCase {
    private func ctx() throws -> ModelContext {
        ModelContext(
            try ModelContainer(
                for: Note.self, Folder.self, Tag.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
        )
    }

    func test_filtersByFolderName() throws {
        let c = try ctx()
        let journal = Folder(name: "Journal")
        let work = Folder(name: "Work")
        c.insert(journal); c.insert(work)
        let a = Note(body: "A"); a.folder = journal
        let b = Note(body: "B"); b.folder = work
        c.insert(a); c.insert(b)
        try c.save()

        let query = SearchQueryParser.parse("folder:journal")
        let matches = try NoteSearch.run(query: query, in: c)
        XCTAssertEqual(matches.map(\.body), ["A"])
    }

    func test_filtersByTag() throws {
        let c = try ctx()
        let t = Tag(name: "todo"); c.insert(t)
        let a = Note(body: "A #todo"); a.tags = [t]
        let b = Note(body: "B")
        c.insert(a); c.insert(b)
        try c.save()

        let matches = try NoteSearch.run(
            query: SearchQueryParser.parse("#todo"),
            in: c
        )
        XCTAssertEqual(matches.map(\.body), ["A #todo"])
    }

    func test_filtersByFreeText_caseInsensitive() throws {
        let c = try ctx()
        c.insert(Note(body: "A note about Swift"))
        c.insert(Note(body: "Something else"))
        try c.save()

        let matches = try NoteSearch.run(
            query: SearchQueryParser.parse("swift"),
            in: c
        )
        XCTAssertEqual(matches.map(\.body), ["A note about Swift"])
    }
}
