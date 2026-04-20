import SwiftUI
import SwiftData

@main
struct SimpleNotesApp: App {
    let container: ModelContainer = {
        do {
            return try ModelContainerFactory.make()
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()

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
        .modelContainer(container)
    }
}
