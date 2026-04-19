import SwiftUI
import SwiftData

struct SidebarView: View {
    @Binding var selectedScope: NoteListScope

    @Query(sort: \Note.updatedAt, order: .reverse) private var allNotes: [Note]

    private var pinnedCount: Int { allNotes.filter(\.isPinned).count }

    private var scopeSelection: Binding<NoteListScope?> {
        Binding(
            get: { selectedScope },
            set: { if let new = $0 { selectedScope = new } }
        )
    }

    var body: some View {
        List(selection: scopeSelection) {
            Section("Library") {
                row("All Notes", count: allNotes.count, systemImage: "tray", scope: .all)
                row("Pinned", count: pinnedCount, systemImage: "pin", scope: .pinned)
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("simple notes")
    }

    private func row(_ title: String, count: Int, systemImage: String, scope: NoteListScope) -> some View {
        NavigationLink(value: scope) {
            HStack {
                Label(title, systemImage: systemImage)
                    .font(Theme.Font.sans(16))
                Spacer()
                Text("\(count)")
                    .font(Theme.Font.mono(12))
                    .foregroundStyle(Theme.Color.muted)
            }
        }
    }
}

#Preview {
    NavigationStack {
        SidebarView(selectedScope: .constant(.all))
    }
    .modelContainer(for: [Note.self], inMemory: true)
}
