import SwiftUI
import SwiftData
import PhotosUI
import UniformTypeIdentifiers

struct NoteEditorView: View {
    @Bindable var note: Note
    var onDelete: () -> Void = {}
    @Environment(\.modelContext) private var modelContext

    @State private var autosaver = EditorAutosaver()
    @State private var isEditing = false
    @FocusState private var isFocused: Bool
    @State private var showCheatsheet = false
    @State private var pickerItem: PhotosPickerItem?
    @State private var showFileImporter = false
    @State private var errorBanner: String?

    var body: some View {
        VStack(spacing: 0) {
            if !note.attachments.isEmpty {
                AttachmentChipRow(
                    attachments: note.attachments.sorted { $0.createdAt < $1.createdAt },
                    onDelete: deleteAttachment
                )
                Divider().background(Theme.Color.hairline)
            }
            Group {
                if isEditing {
                    TextEditor(text: $note.body)
                        .font(Theme.Font.serif(17))
                        .lineSpacing(6)
                        .focused($isFocused)
                        .scrollContentBackground(.hidden)
                        .background(Theme.Color.bg)
                        .padding(.horizontal, Theme.Metric.padding)
                        .padding(.vertical, 8)
                        .onChange(of: note.body) { _, _ in
                            autosaver.scheduleTouch(on: note)
                        }
                } else {
                    NoteMarkdownView(
                        markdown: note.body,
                        attachmentLookup: { id in
                            note.attachments.first { $0.id.uuidString == id }
                        },
                        onTapToEdit: { beginEditing() }
                    )
                }
            }
        }
        .navigationTitle(note.title)
        .navigationBarTitleDisplayMode(.inline)
        .task(id: note.id) {
            autosaver.onFlush {
                TagExtractor.apply(to: note, in: modelContext)
            }
        }
        .onDisappear(perform: flush)
        .safeAreaInset(edge: .top) {
            if let msg = errorBanner {
                Text(msg)
                    .font(Theme.Font.sans(13))
                    .foregroundStyle(.white)
                    .padding(.horizontal, Theme.Metric.padding)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(SwiftUI.Color.red.opacity(0.9))
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                PhotosPicker(selection: $pickerItem, matching: .images) {
                    Image(systemName: "photo")
                }
                .accessibilityLabel("Insert image")
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button { showFileImporter = true } label: {
                    Image(systemName: "doc.badge.plus")
                }
                .accessibilityLabel("Attach file")
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    note.isPinned.toggle()
                    note.touch()
                } label: {
                    Image(systemName: note.isPinned ? "pin.fill" : "pin")
                }
                .keyboardShortcut("p", modifiers: [.command, .shift])
                .accessibilityLabel(note.isPinned ? "Unpin" : "Pin")
            }
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        MarkdownFormatting.insert(.bold, into: &note.body)
                    } label: {
                        Label("Bold", systemImage: "bold")
                    }
                    .keyboardShortcut("b", modifiers: .command)

                    Button {
                        MarkdownFormatting.insert(.italic, into: &note.body)
                    } label: {
                        Label("Italic", systemImage: "italic")
                    }
                    .keyboardShortcut("i", modifiers: .command)

                    Divider()

                    Button(role: .destructive) {
                        deleteNote()
                    } label: {
                        Label("Delete Note", systemImage: "trash")
                    }
                    .keyboardShortcut(.delete, modifiers: .command)
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .accessibilityLabel("More actions")
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showCheatsheet = true
                } label: {
                    Image(systemName: "questionmark.circle")
                }
                .accessibilityLabel("Markdown cheatsheet")
            }
            if isEditing {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { endEditing() }
                        .font(Theme.Font.sans(15, weight: .medium))
                }
            }
        }
        .sheet(isPresented: $showCheatsheet) {
            NavigationStack {
                MarkdownCheatsheetView()
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Close") { showCheatsheet = false }
                        }
                    }
            }
        }
        .onChange(of: pickerItem) { _, newItem in
            Task { await handlePickedImage(newItem) }
        }
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [.pdf, .data, .content, .item],
            allowsMultipleSelection: false
        ) { result in
            handleFileImport(result)
        }
    }

    private func beginEditing() {
        isEditing = true
        isFocused = true
    }

    private func endEditing() {
        isFocused = false
        isEditing = false
        flush()
    }

    private func flush() {
        autosaver.cancel()
        note.touch()
        TagExtractor.apply(to: note, in: modelContext)
        try? modelContext.save()
    }

    private func deleteNote() {
        autosaver.cancel()
        onDelete()
    }

    private func handlePickedImage(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        defer { pickerItem = nil }
        do {
            guard
                let data = try await item.loadTransferable(type: Data.self),
                let image = UIImage(data: data)
            else { return }
            let compressed = try AttachmentCompressor.compress(image)
            let filename = "image-\(UUID().uuidString.prefix(6)).jpg"
            let att = Attachment(filename: filename, mimeType: "image/jpeg", data: compressed)
            NoteAttachments.attach(att, to: note, context: modelContext, isImage: true)
        } catch AttachmentError.tooLarge {
            showBanner("Image too large after compression (5 MB limit).")
        } catch {
            showBanner("Couldn't attach image.")
        }
    }

    private func handleFileImport(_ result: Result<[URL], Error>) {
        guard case .success(let urls) = result, let url = urls.first else { return }
        do {
            let needsRelease = url.startAccessingSecurityScopedResource()
            defer { if needsRelease { url.stopAccessingSecurityScopedResource() } }
            let values = try url.resourceValues(forKeys: [.fileSizeKey])
            if let size = values.fileSize, size > AttachmentImporter.maxBytes {
                showBanner("File too large (10 MB limit).")
                return
            }
            let data = try Data(contentsOf: url)
            let filename = url.lastPathComponent
            let mime = AttachmentImporter.mimeType(forFilename: filename)
            let att = try AttachmentImporter.makeAttachment(
                filename: filename,
                data: data,
                mimeType: mime
            )
            NoteAttachments.attach(att, to: note, context: modelContext, isImage: mime.hasPrefix("image/"))
        } catch AttachmentError.tooLarge {
            showBanner("File too large (10 MB limit).")
        } catch {
            showBanner("Couldn't attach file.")
        }
    }

    private func deleteAttachment(_ att: Attachment) {
        NoteAttachments.detach(att, from: note, context: modelContext)
    }

    private func showBanner(_ message: String) {
        withAnimation { errorBanner = message }
        Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            await MainActor.run {
                withAnimation { errorBanner = nil }
            }
        }
    }
}

#Preview {
    let container = try! ModelContainer(
        for: Note.self, Folder.self, Tag.self, Attachment.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let note = Note(body: "Hello\nBody here.")
    container.mainContext.insert(note)
    return NavigationStack { NoteEditorView(note: note) }
        .modelContainer(container)
}
