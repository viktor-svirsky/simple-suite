import XCTest
@testable import SimpleNotes

final class AttachmentImporterTests: XCTestCase {
    func test_accepts_fileUnderLimit() throws {
        let data = Data(repeating: 0, count: 1024)
        let att = try AttachmentImporter.makeAttachment(
            filename: "notes.pdf",
            data: data,
            mimeType: "application/pdf"
        )
        XCTAssertEqual(att.mimeType, "application/pdf")
        XCTAssertEqual(att.filename, "notes.pdf")
    }

    func test_rejects_fileOverLimit() {
        let data = Data(repeating: 0, count: 11 * 1024 * 1024)
        XCTAssertThrowsError(try AttachmentImporter.makeAttachment(
            filename: "big.bin",
            data: data,
            mimeType: "application/octet-stream"
        )) { err in
            XCTAssertEqual(err as? AttachmentError, .tooLarge)
        }
    }

    func test_mimeTypeFromExtension_fallsBackToOctetStream() {
        XCTAssertEqual(AttachmentImporter.mimeType(forFilename: "a.pdf"), "application/pdf")
        XCTAssertEqual(AttachmentImporter.mimeType(forFilename: "a.png"), "image/png")
        XCTAssertEqual(AttachmentImporter.mimeType(forFilename: "a.zzz"), "application/octet-stream")
    }
}
