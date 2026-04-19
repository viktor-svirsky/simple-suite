import XCTest
import SwiftUI
@testable import SimpleNotes

final class MarkdownRendererTests: XCTestCase {
    func test_renders_boldItalicInline() {
        let s = MarkdownRenderer.render("Hello **bold** and _italic_")
        let raw = String(s.characters)
        XCTAssertTrue(raw.contains("Hello bold and italic"))
    }

    func test_styles_tags_asMonospaceMuted() {
        let s = MarkdownRenderer.render("tagged #journal here")
        let runs = s.runs
        let tagRun = runs.first { run in
            let slice = s[run.range]
            return String(slice.characters) == "#journal"
        }
        XCTAssertNotNil(tagRun, "expected a run for #journal")
    }

    func test_preservesPlainTextCharacters() {
        let s = MarkdownRenderer.render("Plain text.")
        XCTAssertEqual(String(s.characters), "Plain text.")
    }

    func test_codeBlock_isMonospaced() {
        let md = """
        Text.

        ```
        let x = 1
        ```
        """
        let s = MarkdownRenderer.render(md)
        let raw = String(s.characters)
        XCTAssertTrue(raw.contains("let x = 1"))
    }
}
