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

    /// Bumps `updatedAt`. Call whenever persisted content changes.
    func touch(_ now: Date = Date()) {
        updatedAt = now
    }

    /// First non-empty line of `body`, trimmed, capped at 80 chars.
    /// Returns "New Note" when the body has no content yet — gives new notes a
    /// stable label in the list before the user types anything.
    var title: String {
        let firstLine = body
            .split(whereSeparator: \.isNewline)
            .lazy
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .first { !$0.isEmpty }
            ?? ""
        if firstLine.isEmpty {
            return "New Note"
        }
        if firstLine.count <= 80 {
            return firstLine
        }
        return String(firstLine.prefix(80))
    }

    /// Body after the title line, trimmed. Empty when body is one line or blank.
    var preview: String {
        let lines = body.split(whereSeparator: \.isNewline).map(String.init)
        guard lines.count > 1 else { return "" }
        return lines.dropFirst()
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespaces)
    }
}
