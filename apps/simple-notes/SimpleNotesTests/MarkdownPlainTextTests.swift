import XCTest
@testable import SimpleNotes

final class MarkdownPlainTextTests: XCTestCase {
    func test_strips_inlineEmphasis() {
        XCTAssertEqual(
            MarkdownPlainText.strip("**bold** and _italic_"),
            "bold and italic"
        )
    }

    func test_strips_inlineCodeFences() {
        XCTAssertEqual(
            MarkdownPlainText.strip("use `xcodebuild` to compile"),
            "use xcodebuild to compile"
        )
    }

    func test_drops_linkUrlKeepsLabel() {
        XCTAssertEqual(
            MarkdownPlainText.strip("see [docs](https://example.com/a)"),
            "see docs"
        )
    }

    func test_keeps_tagLiterally() {
        XCTAssertEqual(MarkdownPlainText.strip("tagged #journal"), "tagged #journal")
    }
}
