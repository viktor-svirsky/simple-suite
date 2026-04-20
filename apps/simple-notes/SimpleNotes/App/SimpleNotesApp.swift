import SwiftUI
import SwiftData

@main
struct SimpleNotesApp: App {
    init() {
        SentryConfig.start(
            environment: SentryConfig.environment,
            release: SentryConfig.release
        )
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: [Note.self, Folder.self, Tag.self, Attachment.self])
    }
}
