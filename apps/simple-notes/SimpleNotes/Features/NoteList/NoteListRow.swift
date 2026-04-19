import SwiftUI

struct NoteListRow: View {
    let title: String
    let preview: String
    let meta: String
    let tags: [String]
    let isPinned: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(Theme.Font.serif(17, weight: .medium))
                .foregroundStyle(Theme.Color.text)
            if !preview.isEmpty {
                Text(preview)
                    .font(Theme.Font.sans(13))
                    .foregroundStyle(Theme.Color.muted)
                    .lineLimit(2)
            }
            HStack(spacing: 8) {
                Text(meta)
                    .font(Theme.Font.sans(11))
                    .foregroundStyle(Theme.Color.muted)
                ForEach(tags, id: \.self) { tag in
                    Text(tag)
                        .font(Theme.Font.mono(11))
                        .foregroundStyle(Theme.Color.muted)
                }
                if isPinned {
                    Image(systemName: "pin.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(Theme.Color.muted)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NoteListRow(
        title: "Preview",
        preview: "Some body preview text spanning a couple of lines for demonstration.",
        meta: "Today",
        tags: ["#demo"],
        isPinned: true
    )
    .padding()
}
