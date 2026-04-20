import XCTest
@testable import SimpleNotes

final class MarkdownFormattingTests: XCTestCase {
    func test_insertBold_intoEmpty_appendsMarkers() {
        var s = ""
        MarkdownFormatting.insert(.bold, into: &s)
        XCTAssertEqual(s, "**bold**")
    }

    func test_insertBold_afterWord_addsSeparator() {
        var s = "hello"
        MarkdownFormatting.insert(.bold, into: &s)
        XCTAssertEqual(s, "hello **bold**")
    }

    func test_insertBold_afterTrailingSpace_noExtraSeparator() {
        var s = "hello "
        MarkdownFormatting.insert(.bold, into: &s)
        XCTAssertEqual(s, "hello **bold**")
    }

    func test_insertItalic_afterNewline_noExtraSeparator() {
        var s = "line\n"
        MarkdownFormatting.insert(.italic, into: &s)
        XCTAssertEqual(s, "line\n_italic_")
    }

    func test_insertItalic_intoEmpty_appendsMarkers() {
        var s = ""
        MarkdownFormatting.insert(.italic, into: &s)
        XCTAssertEqual(s, "_italic_")
    }
}
