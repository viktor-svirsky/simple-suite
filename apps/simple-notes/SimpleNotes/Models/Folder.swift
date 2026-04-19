import Foundation
import SwiftData

@Model
final class Folder {
    var id: UUID
    var name: String
    var sortOrder: Int
    @Relationship(inverse: \Note.folder) var notes: [Note]

    init(id: UUID = UUID(), name: String, sortOrder: Int = 0) {
        self.id = id
        self.name = name
        self.sortOrder = sortOrder
        self.notes = []
    }
}
