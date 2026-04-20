import Foundation
import UniformTypeIdentifiers

enum AttachmentImporter {
    static let maxBytes = 10 * 1024 * 1024

    static func makeAttachment(
        filename: String,
        data: Data,
        mimeType: String
    ) throws -> Attachment {
        guard data.count <= maxBytes else { throw AttachmentError.tooLarge }
        return Attachment(filename: filename, mimeType: mimeType, data: data)
    }

    static func mimeType(forFilename filename: String) -> String {
        let ext = (filename as NSString).pathExtension
        guard !ext.isEmpty,
              let type = UTType(filenameExtension: ext),
              let mime = type.preferredMIMEType
        else {
            return "application/octet-stream"
        }
        return mime
    }
}
