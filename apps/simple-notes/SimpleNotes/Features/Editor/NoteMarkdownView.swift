import SwiftUI
import PDFKit

struct NoteMarkdownView: View {
    let markdown: String
    var attachmentLookup: (String) -> Attachment? = { _ in nil }
    let onTapToEdit: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(segments) { segment in
                    view(for: segment)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Theme.Metric.padding)
            .padding(.vertical, 8)
        }
        .background(Theme.Color.bg)
        .contentShape(Rectangle())
        .onTapGesture { onTapToEdit() }
    }

    @ViewBuilder
    private func view(for segment: RenderSegment) -> some View {
        switch segment.payload {
        case .text(let string):
            if !string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(MarkdownRenderer.render(string))
                    .font(Theme.Font.serif(17))
                    .foregroundStyle(Theme.Color.text)
                    .lineSpacing(6)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        case .image(let att):
            if let image = UIImage(data: att.data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            } else {
                AttachmentFileChip(attachment: att)
            }
        case .pdf(let att):
            AttachmentPDFThumbnail(attachment: att)
        case .file(let att):
            AttachmentFileChip(attachment: att)
        case .missing(let caption):
            Text(caption.isEmpty ? "missing attachment" : caption)
                .font(Theme.Font.mono(12))
                .foregroundStyle(Theme.Color.muted)
        }
    }

    private var segments: [RenderSegment] {
        let refs = MarkdownRenderer.attachmentReferences(in: markdown)
        guard !refs.isEmpty else {
            return [RenderSegment(id: 0, payload: .text(markdown))]
        }

        var result: [RenderSegment] = []
        var cursor = markdown.startIndex
        var nextID = 0
        for ref in refs {
            if cursor < ref.range.lowerBound {
                let chunk = String(markdown[cursor..<ref.range.lowerBound])
                result.append(RenderSegment(id: nextID, payload: .text(chunk)))
                nextID += 1
            }
            if let att = attachmentLookup(ref.idString) {
                switch ref.kind {
                case .image:
                    if att.isImage {
                        result.append(RenderSegment(id: nextID, payload: .image(att)))
                    } else if att.isPDF {
                        result.append(RenderSegment(id: nextID, payload: .pdf(att)))
                    } else {
                        result.append(RenderSegment(id: nextID, payload: .file(att)))
                    }
                case .file:
                    if att.isPDF {
                        result.append(RenderSegment(id: nextID, payload: .pdf(att)))
                    } else {
                        result.append(RenderSegment(id: nextID, payload: .file(att)))
                    }
                }
            } else {
                result.append(RenderSegment(id: nextID, payload: .missing(ref.caption)))
            }
            nextID += 1
            cursor = ref.range.upperBound
        }
        if cursor < markdown.endIndex {
            result.append(RenderSegment(
                id: nextID,
                payload: .text(String(markdown[cursor..<markdown.endIndex]))
            ))
        }
        return result
    }
}

private struct RenderSegment: Identifiable {
    enum Payload {
        case text(String)
        case image(Attachment)
        case pdf(Attachment)
        case file(Attachment)
        case missing(String)
    }
    let id: Int
    let payload: Payload
}

private struct AttachmentPDFThumbnail: View {
    let attachment: Attachment
    @State private var thumbnail: UIImage?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Group {
                if let thumbnail {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Theme.Color.hairline, lineWidth: Theme.Metric.hairline)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                } else {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Theme.Color.surface)
                        .frame(height: 220)
                        .overlay(ProgressView())
                }
            }
            AttachmentFileChip(attachment: attachment)
        }
        .task(id: attachment.id) {
            thumbnail = await Self.renderThumbnail(data: attachment.data)
        }
    }

    static func renderThumbnail(data: Data) async -> UIImage? {
        await Task.detached(priority: .userInitiated) {
            guard
                let document = PDFDocument(data: data),
                let page = document.page(at: 0)
            else { return nil }
            return page.thumbnail(of: CGSize(width: 1024, height: 1400), for: .cropBox)
        }.value
    }
}

#Preview {
    NoteMarkdownView(
        markdown: "# Hi\n\nA **note** with a #tag and `code`.",
        onTapToEdit: {}
    )
}
