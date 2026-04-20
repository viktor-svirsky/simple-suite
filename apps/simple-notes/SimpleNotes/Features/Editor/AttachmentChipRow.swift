import SwiftUI

struct AttachmentChipRow: View {
    let attachments: [Attachment]
    let onDelete: (Attachment) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(attachments) { att in
                    HStack(spacing: 6) {
                        Image(systemName: icon(for: att))
                            .foregroundStyle(Theme.Color.muted)
                        Text(att.filename)
                            .font(Theme.Font.mono(11))
                            .foregroundStyle(Theme.Color.text)
                            .lineLimit(1)
                        Button {
                            onDelete(att)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(Theme.Color.muted)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Remove \(att.filename)")
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Theme.Color.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Theme.Color.hairline, lineWidth: Theme.Metric.hairline)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
            .padding(.horizontal, Theme.Metric.padding)
            .padding(.vertical, 6)
        }
    }

    private func icon(for att: Attachment) -> String {
        if att.isImage { return "photo" }
        if att.isPDF { return "doc.richtext" }
        return "doc"
    }
}
