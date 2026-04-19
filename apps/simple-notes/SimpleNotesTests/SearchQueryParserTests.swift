import XCTest
@testable import SimpleNotes

final class SearchQueryParserTests: XCTestCase {
    func test_parses_freeText() {
        let q = SearchQueryParser.parse("hello world")
        XCTAssertEqual(q.text, "hello world")
        XCTAssertTrue(q.tags.isEmpty)
        XCTAssertNil(q.folderName)
    }

    func test_parses_tag() {
        let q = SearchQueryParser.parse("#journal review")
        XCTAssertEqual(q.tags, ["journal"])
        XCTAssertEqual(q.text, "review")
    }

    func test_parses_folderToken() {
        let q = SearchQueryParser.parse("folder:Journal notes")
        XCTAssertEqual(q.folderName, "journal")
        XCTAssertEqual(q.text, "notes")
    }

    func test_parses_multipleTokens() {
        let q = SearchQueryParser.parse("folder:work #todo urgent")
        XCTAssertEqual(q.tags, ["todo"])
        XCTAssertEqual(q.folderName, "work")
        XCTAssertEqual(q.text, "urgent")
    }

    func test_empty_isEmpty() {
        XCTAssertTrue(SearchQueryParser.parse("").isEmpty)
    }
}
