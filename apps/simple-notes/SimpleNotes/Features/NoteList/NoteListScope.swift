import Foundation
import SwiftData

// Bool lacks Comparable conformance in stdlib, which blocks
// `SortDescriptor(\.isPinned, order: .reverse)` from picking the non-NSObject
// overload. Adding it app-locally so @Query can sort pinned-first.
extension Bool: @retroactive Comparable {
    public static func < (lhs: Bool, rhs: Bool) -> Bool {
        !lhs && rhs
    }
}

enum NoteListScope: String, CaseIterable, Identifiable {
    case all, pinned
    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: return "All Notes"
        case .pinned: return "Pinned"
        }
    }

    /// Host-side filter (for unit tests and in-memory checks). `@Query` uses
    /// `#Predicate` directly — see `predicate`.
    func includes(_ note: Note) -> Bool {
        switch self {
        case .all: return true
        case .pinned: return note.isPinned
        }
    }

    var predicate: Predicate<Note> {
        switch self {
        case .all:
            return #Predicate<Note> { _ in true }
        case .pinned:
            return #Predicate<Note> { $0.isPinned }
        }
    }

    static let sortDescriptors: [SortDescriptor<Note>] = [
        SortDescriptor(\.isPinned, order: .reverse),
        SortDescriptor(\.updatedAt, order: .reverse),
    ]

    /// Formats `date` relative to `now`: today → time, yesterday → "Yesterday",
    /// within last week → weekday, older → "MMM d".
    static func relativeDateString(for date: Date, now: Date = Date()) -> String {
        let calendar = Calendar(identifier: .gregorian)
        if calendar.isDate(date, inSameDayAs: now) {
            return timeFormatter.string(from: date)
        }
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: now),
           calendar.isDate(date, inSameDayAs: yesterday) {
            return "Yesterday"
        }
        let days = calendar.dateComponents([.day], from: date, to: now).day ?? 0
        if days < 7 && days >= 0 {
            return weekdayFormatter.string(from: date)
        }
        return monthDayFormatter.string(from: date)
    }

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .none
        f.timeStyle = .short
        return f
    }()
    private static let weekdayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEE"
        return f
    }()
    private static let monthDayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f
    }()
}
