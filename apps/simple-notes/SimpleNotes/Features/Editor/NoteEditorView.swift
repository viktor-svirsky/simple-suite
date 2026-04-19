import SwiftUI
import SwiftData

struct NoteEditorView: View {
    @Bindable var note: Note
    @Environment(\.modelContext) private var modelContext

    @State private var autosaver = EditorAutosaver()
    @State private var isEditing = false
    @FocusState private var isFocused: Bool
    @State private var showCheatsheet = false

    var body: some View {
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
                NoteMarkdownView(markdown: note.body) {
                    beginEditing()
                }
            }
        }
        .navigationTitle(note.title)
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear(perform: flush)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    note.isPinned.toggle()
                    note.touch()
                } label: {
                    Image(systemName: note.isPinned ? "pin.fill" : "pin")
                }
                .accessibilityLabel(note.isPinned ? "Unpin" : "Pin")
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
        try? modelContext.save()
    }
}

#Preview {
    let container = try! ModelContainer(
        for: Note.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let note = Note(body: "Hello\nBody here.")
    container.mainContext.insert(note)
    return NavigationStack { NoteEditorView(note: note) }
        .modelContainer(container)
}
