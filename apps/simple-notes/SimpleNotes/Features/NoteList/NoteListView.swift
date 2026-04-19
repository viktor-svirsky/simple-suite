import SwiftUI

struct NoteListView: View {
    var body: some View {
        ContentUnavailableView(
            "No notes yet",
            systemImage: "square.and.pencil",
            description: Text("Tap + to create one.")
        )
        .navigationTitle("All Notes")
    }
}

#Preview { NoteListView() }
