import SwiftUI

struct NoteEditorView: View {
    // Mock until M1 wires @Bindable note.
    let title: String = "On slow mornings"
    let meta: String = "Today · 9:12  ·  Journal"
    let tag: String = "#journal"
    let paragraphs: [String] = [
        "Coffee, a book, and the window half open. The trick is not to check the phone before the kettle sings.",
        "Some mornings the rules fall apart. That is also fine. The point is the cadence, not the streak.",
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(title)
                    .font(Theme.Font.serif(28, weight: .medium))
                    .foregroundStyle(Theme.Color.text)
                HStack(spacing: 8) {
                    Text(meta)
                        .font(Theme.Font.sans(12))
                        .foregroundStyle(Theme.Color.muted)
                    Text(tag)
                        .font(Theme.Font.mono(12))
                        .foregroundStyle(Theme.Color.muted)
                }

                Text("Rules")
                    .font(Theme.Font.serif(20, weight: .medium))
                    .padding(.top, 8)
                VStack(alignment: .leading, spacing: 4) {
                    bullet("No screens before water boils")
                    bullet("Read twenty pages, no more")
                    bullet("Write one sentence about the day")
                }

                ForEach(paragraphs, id: \.self) { p in
                    Text(p)
                        .font(Theme.Font.serif(17))
                        .foregroundStyle(Theme.Color.text)
                        .lineSpacing(6)
                }
            }
            .padding(.horizontal, Theme.Metric.padding)
            .padding(.vertical, 24)
        }
        .background(Theme.Color.bg)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button { } label: { Image(systemName: "pin") }
                Button { } label: { Image(systemName: "ellipsis.circle") }
            }
        }
    }

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text("·")
                .font(Theme.Font.serif(17))
                .foregroundStyle(Theme.Color.muted)
            Text(text)
                .font(Theme.Font.serif(17))
                .foregroundStyle(Theme.Color.text)
        }
    }
}

#Preview { NavigationStack { NoteEditorView() } }
