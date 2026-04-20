import XCTest
@testable import SimpleNotes

final class AttachmentRenderingTests: XCTestCase {
    func test_renderer_extractsImageReference() {
        let md = "before ![cat](attachment://ABCD-1234) after"
        let refs = MarkdownRenderer.attachmentReferences(in: md)
        XCTAssertEqual(refs.count, 1)
        XCTAssertEqual(refs.first?.idString, "ABCD-1234")
        XCTAssertEqual(refs.first?.kind, .image)
        XCTAssertEqual(refs.first?.caption, "cat")
    }

    func test_renderer_distinguishesFileFromImageRefs() {
        let md = "![img](attachment://A) then [doc](attachment://B)"
        let refs = MarkdownRenderer.attachmentReferences(in: md)
        XCTAssertEqual(refs.count, 2)
        XCTAssertEqual(refs[0].kind, .image)
        XCTAssertEqual(refs[0].idString, "A")
        XCTAssertEqual(refs[1].kind, .file)
        XCTAssertEqual(refs[1].idString, "B")
    }

    func test_renderer_handlesMultipleImages() {
        let md = "![a](attachment://1) and ![b](attachment://2)"
        let refs = MarkdownRenderer.attachmentReferences(in: md)
        XCTAssertEqual(refs.count, 2)
        XCTAssertEqual(refs.map(\.idString), ["1", "2"])
    }

    func test_renderer_noRefs_returnsEmpty() {
        XCTAssertTrue(MarkdownRenderer.attachmentReferences(in: "plain text only").isEmpty)
    }

    func test_renderer_ignoresNonAttachmentLinks() {
        let md = "see [site](https://example.com) and ![pic](attachment://X)"
        let refs = MarkdownRenderer.attachmentReferences(in: md)
        XCTAssertEqual(refs.count, 1)
        XCTAssertEqual(refs.first?.kind, .image)
        XCTAssertEqual(refs.first?.idString, "X")
    }
}
