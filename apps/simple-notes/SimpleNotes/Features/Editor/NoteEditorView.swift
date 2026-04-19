import SwiftUI

struct NoteEditorView: View {
    var body: some View {
        ContentUnavailableView(
            "Select a note",
            systemImage: "text.alignleft"
        )
    }
}

#Preview { NoteEditorView() }
