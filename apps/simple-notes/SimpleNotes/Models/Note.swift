import Foundation
import SwiftData

@Model
final class Note {
    var id: UUID
    var body: String
    var createdAt: Date
    var updatedAt: Date
    var isPinned: Bool

    init(
        id: UUID = UUID(),
        body: String = "",
        createdAt: Date = Date(),
        isPinned: Bool = false
    ) {
        self.id = id
        self.body = body
        self.createdAt = createdAt
        self.updatedAt = createdAt
        self.isPinned = isPinned
    }

    func touch(_ now: Date = Date()) {
        updatedAt = now
    }
}
