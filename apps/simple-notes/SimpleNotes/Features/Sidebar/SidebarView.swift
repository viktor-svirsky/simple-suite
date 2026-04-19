import SwiftUI

struct SidebarItem: Identifiable {
    let id = UUID()
    let title: String
    let count: Int
    let systemImage: String?
}

struct SidebarView: View {
    // Mock data until NoteList wires @Query (M3).
    let folders: [SidebarItem] = [
        .init(title: "Journal", count: 43, systemImage: "book.closed"),
        .init(title: "Work", count: 28, systemImage: "briefcase"),
        .init(title: "Reading", count: 19, systemImage: "books.vertical"),
    ]
    let tags: [SidebarItem] = [
        .init(title: "#idea", count: 14, systemImage: nil),
        .init(title: "#todo", count: 22, systemImage: nil),
        .init(title: "#book", count: 9, systemImage: nil),
    ]

    var body: some View {
        List {
            Section("Library") {
                row("All Notes", count: 128, systemImage: "tray")
                row("Pinned", count: 4, systemImage: "pin")
                row("Trash", count: 12, systemImage: "trash")
            }

            Section("Folders") {
                ForEach(folders) { item in
                    row(item.title, count: item.count, systemImage: item.systemImage)
                }
            }

            Section("Tags") {
                ForEach(tags) { item in
                    HStack {
                        Text(item.title)
                            .font(Theme.Font.mono(15))
                            .foregroundStyle(Theme.Color.muted)
                        Spacer()
                        Text("\(item.count)")
                            .font(Theme.Font.mono(12))
                            .foregroundStyle(Theme.Color.muted)
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("simple notes")
        .safeAreaInset(edge: .bottom) { syncFooter }
    }

    private func row(_ title: String, count: Int, systemImage: String?) -> some View {
        HStack {
            if let systemImage {
                Label(title, systemImage: systemImage)
                    .font(Theme.Font.sans(16))
            } else {
                Text(title).font(Theme.Font.sans(16))
            }
            Spacer()
            Text("\(count)")
                .font(Theme.Font.mono(12))
                .foregroundStyle(Theme.Color.muted)
        }
    }

    private var syncFooter: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color.green)
                .frame(width: 6, height: 6)
            Text("Synced · 2m ago")
                .font(Theme.Font.sans(12))
                .foregroundStyle(Theme.Color.muted)
        }
        .padding(.horizontal, Theme.Metric.padding)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Color.bg)
        .overlay(Rectangle().frame(height: Theme.Metric.hairline).foregroundStyle(Theme.Color.hairline), alignment: .top)
    }
}

#Preview { NavigationStack { SidebarView() } }
