import SwiftUI

struct MarkdownCheatsheetView: View {
    private struct Row: Identifiable {
        let id = UUID()
        let syntax: String
        let result: String
    }

    private let rows: [Row] = [
        .init(syntax: "# Heading", result: "Large heading"),
        .init(syntax: "## Subheading", result: "Subheading"),
        .init(syntax: "**bold**", result: "bold"),
        .init(syntax: "_italic_", result: "italic"),
        .init(syntax: "`code`", result: "code"),
        .init(syntax: "- item", result: "Bulleted list"),
        .init(syntax: "1. item", result: "Numbered list"),
        .init(syntax: "[label](https://…)", result: "Link"),
        .init(syntax: "#tag", result: "Tag (filter in M3)"),
        .init(syntax: "```…```", result: "Fenced code block"),
    ]

    var body: some View {
        List(rows) { row in
            VStack(alignment: .leading, spacing: 4) {
                Text(row.syntax)
                    .font(Theme.Font.mono(14))
                    .foregroundStyle(Theme.Color.text)
                Text(row.result)
                    .font(Theme.Font.sans(13))
                    .foregroundStyle(Theme.Color.muted)
            }
            .padding(.vertical, 2)
        }
        .listStyle(.plain)
        .navigationTitle("Markdown")
    }
}

#Preview { NavigationStack { MarkdownCheatsheetView() } }
