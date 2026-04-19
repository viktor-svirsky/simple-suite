import SwiftUI
import SwiftData

@main
struct SimpleNotesApp: App {
    var body: some Scene {
        WindowGroup {
            Text("soon")
        }
        .modelContainer(for: [Note.self])
    }
}
