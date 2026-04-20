import SwiftUI

struct AttachmentFileChip: View {
    let attachment: Attachment

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: iconName)
                .font(.system(size: 20))
                .foregroundStyle(Theme.Color.muted)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(attachment.filename)
                    .font(Theme.Font.sans(14, weight: .medium))
                    .foregroundStyle(Theme.Color.text)
                    .lineLimit(1)
                Text(sizeLabel)
                    .font(Theme.Font.mono(11))
                    .foregroundStyle(Theme.Color.muted)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Color.surface)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Theme.Color.hairline, lineWidth: Theme.Metric.hairline)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var iconName: String {
        if attachment.isPDF { return "doc.richtext" }
        if attachment.isImage { return "photo" }
        return "doc"
    }

    private var sizeLabel: String {
        ByteCountFormatter.string(
            fromByteCount: Int64(attachment.data.count),
            countStyle: .file
        )
    }
}
