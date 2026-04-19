import SwiftUI
import SwiftData

struct NoteEditorView: View {
    @Bindable var note: Note
    @Environment(\.modelContext) private var modelContext

    @State private var autosaver = EditorAutosaver()

    var body: some View {
        TextEditor(text: $note.body)
            .font(Theme.Font.serif(17))
            .lineSpacing(6)
            .scrollContentBackground(.hidden)
            .background(Theme.Color.bg)
            .padding(.horizontal, Theme.Metric.padding)
            .padding(.vertical, 8)
            .navigationTitle(note.title)
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: note.body) { _, _ in
                autosaver.scheduleTouch(on: note)
            }
            .onDisappear {
                autosaver.cancel()
                note.touch()
                try? modelContext.save()
            }
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
            }
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
