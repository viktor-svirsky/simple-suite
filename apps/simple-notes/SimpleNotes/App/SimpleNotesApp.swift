import SwiftUI
import SwiftData

@main
struct SimpleNotesApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: [Note.self])
    }
}
