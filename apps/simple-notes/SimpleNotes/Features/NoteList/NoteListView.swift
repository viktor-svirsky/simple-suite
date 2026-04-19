import SwiftUI

private struct MockRow: Identifiable {
    let id = UUID()
    let title: String
    let preview: String
    let meta: String
    let tags: [String]
    let isPinned: Bool
}

struct NoteListView: View {
    private let mockRows: [MockRow] = [
        .init(title: "On slow mornings",
              preview: "Coffee, a book, and the window half open.",
              meta: "Today · 9:12", tags: ["#journal"], isPinned: true),
        .init(title: "Abacus billing edge cases",
              preview: "1. Trailing payee. 2. Split contracts.",
              meta: "Yesterday", tags: ["#work"], isPinned: false),
    ]

    var body: some View {
        List(mockRows) { row in
            NoteListRow(
                title: row.title,
                preview: row.preview,
                meta: row.meta,
                tags: row.tags,
                isPinned: row.isPinned
            )
        }
        .listStyle(.plain)
        .navigationTitle("All Notes")
    }
}

#Preview { NavigationStack { NoteListView() } }
