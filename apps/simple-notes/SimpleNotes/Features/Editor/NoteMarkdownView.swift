import SwiftUI

struct NoteMarkdownView: View {
    let markdown: String
    let onTapToEdit: () -> Void

    var body: some View {
        ScrollView {
            Text(MarkdownRenderer.render(markdown))
                .font(Theme.Font.serif(17))
                .foregroundStyle(Theme.Color.text)
                .lineSpacing(6)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, Theme.Metric.padding)
                .padding(.vertical, 8)
        }
        .background(Theme.Color.bg)
        .contentShape(Rectangle())
        .onTapGesture { onTapToEdit() }
    }
}

#Preview {
    NoteMarkdownView(
        markdown: "# Hi\n\nA **note** with a #tag and `code`.",
        onTapToEdit: {}
    )
}
