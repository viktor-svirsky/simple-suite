import XCTest
import SwiftData
@testable import SimpleNotes

final class AttachmentModelTests: XCTestCase {
    private func ctx() throws -> ModelContext {
        ModelContext(try ModelContainer(
            for: Note.self, Folder.self, Tag.self, Attachment.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        ))
    }

    func test_deletingNote_cascadesAttachments() throws {
        let c = try ctx()
        let att = Attachment(filename: "x.jpg", data: Data([0x00]))
        let note = Note(body: "")
        note.attachments = [att]
        c.insert(note)
        try c.save()
        XCTAssertEqual(try c.fetchCount(FetchDescriptor<Attachment>()), 1)

        c.delete(note)
        try c.save()
        XCTAssertEqual(try c.fetchCount(FetchDescriptor<Attachment>()), 0)
    }

    func test_attachmentCreatedAt_defaultsToNow() {
        let before = Date()
        let att = Attachment(filename: "x.jpg", data: Data())
        XCTAssertGreaterThanOrEqual(att.createdAt, before)
    }

    func test_isImage_and_isPDF_flagsMatchMimeType() {
        XCTAssertTrue(Attachment(filename: "a.jpg", mimeType: "image/jpeg", data: Data()).isImage)
        XCTAssertTrue(Attachment(filename: "a.png", mimeType: "image/png", data: Data()).isImage)
        XCTAssertFalse(Attachment(filename: "a.pdf", mimeType: "application/pdf", data: Data()).isImage)
        XCTAssertTrue(Attachment(filename: "a.pdf", mimeType: "application/pdf", data: Data()).isPDF)
        XCTAssertFalse(Attachment(filename: "a.bin", data: Data()).isImage)
    }
}
