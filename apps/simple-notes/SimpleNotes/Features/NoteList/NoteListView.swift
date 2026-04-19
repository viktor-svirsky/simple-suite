import SwiftUI

struct NoteListRow: Identifiable {
    let id = UUID()
    let title: String
    let preview: String
    let meta: String
    let tags: [String]
    let isPinned: Bool
}

struct NoteListView: View {
    // Mock data until @Query lands in M1.
    let rows: [NoteListRow] = [
        .init(
            title: "On slow mornings",
            preview: "Coffee, a book, and the window half open. The trick is not to check the phone before the kettle sings.",
            meta: "Today · 9:12",
            tags: ["#journal"],
            isPinned: true
        ),
        .init(
            title: "Abacus billing edge cases",
            preview: "1. Trailing payee with no bank details. 2. Split contracts spanning cycle boundaries. 3. Zero-value statements.",
            meta: "Yesterday",
            tags: ["#work", "#todo"],
            isPinned: false
        ),
        .init(
            title: "Bear vs Apple Notes",
            preview: "Bear wins on typography and markdown. Apple Notes wins on sync reliability and Live Text. The right answer is: build your own.",
            meta: "Mon",
            tags: ["#idea"],
            isPinned: false
        ),
        .init(
            title: "The Pragmatic Programmer — notes",
            preview: "\"No broken windows\" — fix small decay immediately. Apply ruthlessly to test suites.",
            meta: "Apr 14",
            tags: ["#book"],
            isPinned: false
        ),
        .init(
            title: "Grocery",
            preview: "olive oil, sourdough, eggs, spinach, yogurt, lemons, parmesan",
            meta: "Apr 12",
            tags: ["#todo"],
            isPinned: false
        ),
    ]

    var body: some View {
        List(rows) { row in
            NavigationLink(value: row.id) {
                NoteRow(row: row)
            }
        }
        .listStyle(.plain)
        .navigationTitle("All Notes")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { } label: { Image(systemName: "square.and.pencil") }
            }
        }
    }
}

private struct NoteRow: View {
    let row: NoteListRow

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(row.title)
                .font(Theme.Font.serif(17, weight: .medium))
                .foregroundStyle(Theme.Color.text)
            Text(row.preview)
                .font(Theme.Font.sans(13))
                .foregroundStyle(Theme.Color.muted)
                .lineLimit(2)
            HStack(spacing: 8) {
                Text(row.meta)
                    .font(Theme.Font.sans(11))
                    .foregroundStyle(Theme.Color.muted)
                ForEach(row.tags, id: \.self) { tag in
                    Text(tag)
                        .font(Theme.Font.mono(11))
                        .foregroundStyle(Theme.Color.muted)
                }
                if row.isPinned {
                    Image(systemName: "pin.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(Theme.Color.muted)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview { NavigationStack { NoteListView() } }
