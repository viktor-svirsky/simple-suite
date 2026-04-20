import Foundation
import SwiftData

enum ModelContainerFactory {
    static func make() throws -> ModelContainer {
        let schema = Schema([
            Note.self, Folder.self, Tag.self, Attachment.self,
        ])
        let configuration: ModelConfiguration

        #if SIMPLE_NOTES_CLOUDKIT_ENABLED
        configuration = ModelConfiguration(
            "SimpleNotes",
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .private("iCloud.com.simplesuite.notes")
        )
        #else
        configuration = ModelConfiguration(
            "SimpleNotes",
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .none
        )
        #endif

        return try ModelContainer(for: schema, configurations: [configuration])
    }

    static func inMemory() throws -> ModelContainer {
        try ModelContainer(
            for: Note.self, Folder.self, Tag.self, Attachment.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }
}
