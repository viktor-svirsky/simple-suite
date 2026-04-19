import XCTest
@testable import SimpleNotes

final class MarkdownTagScannerTests: XCTestCase {
    func test_matches_simpleTag() {
        let tags = MarkdownTagScanner.tags(in: "hello #world")
        XCTAssertEqual(tags.map(\.name), ["world"])
    }

    func test_matches_multipleTagsWithPunctuation() {
        let tags = MarkdownTagScanner.tags(in: "#one and #two-three, also #four_FIVE.")
        XCTAssertEqual(tags.map(\.name), ["one", "two-three", "four_FIVE"])
    }

    func test_skips_hashInWord() {
        XCTAssertTrue(MarkdownTagScanner.tags(in: "C#is not a tag").isEmpty)
    }

    func test_skips_bareHash() {
        XCTAssertTrue(MarkdownTagScanner.tags(in: "# header").isEmpty)
    }

    func test_ranges_coverTheTagIncludingHash() {
        let source = "a #tag b"
        let tags = MarkdownTagScanner.tags(in: source)
        XCTAssertEqual(tags.count, 1)
        let range = tags[0].range
        XCTAssertEqual(source[range], "#tag")
    }
}
