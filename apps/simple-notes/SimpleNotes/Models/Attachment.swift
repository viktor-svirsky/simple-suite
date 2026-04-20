import Foundation
import SwiftData

@Model
final class Attachment {
    var id: UUID
    var filename: String
    var mimeType: String
    var data: Data
    var createdAt: Date

    init(
        id: UUID = UUID(),
        filename: String,
        mimeType: String = "application/octet-stream",
        data: Data,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.filename = filename
        self.mimeType = mimeType
        self.data = data
        self.createdAt = createdAt
    }

    var isImage: Bool { mimeType.hasPrefix("image/") }
    var isPDF: Bool { mimeType == "application/pdf" }
}
