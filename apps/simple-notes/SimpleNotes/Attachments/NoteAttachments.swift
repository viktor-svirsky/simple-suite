import Foundation
import SwiftData

enum NoteAttachments {
    static func attach(
        _ att: Attachment,
        to note: Note,
        context: ModelContext,
        isImage: Bool
    ) {
        context.insert(att)
        note.attachments.append(att)
        let bang = isImage ? "!" : ""
        note.body.append("\n\n\(bang)[\(att.filename)](attachment://\(att.id))\n")
        note.touch()
        try? context.save()
    }

    static func detach(_ att: Attachment, from note: Note, context: ModelContext) {
        let marker = "(attachment://\(att.id))"
        let lines = note.body.split(omittingEmptySubsequences: false, whereSeparator: \.isNewline)
        let filtered = lines.filter { !$0.contains(marker) }
        note.body = filtered.joined(separator: "\n")
        note.attachments.removeAll { $0.id == att.id }
        context.delete(att)
        note.touch()
        try? context.save()
    }
}
