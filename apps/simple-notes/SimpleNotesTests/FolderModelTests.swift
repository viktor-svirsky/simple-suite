import XCTest
import SwiftData
@testable import SimpleNotes

final class FolderModelTests: XCTestCase {
    private func container() throws -> ModelContainer {
        try ModelContainer(
            for: Note.self, Folder.self, Tag.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    func test_insertFolder_persists() throws {
        let c = try container()
        let ctx = ModelContext(c)
        let f = Folder(name: "Journal", sortOrder: 0)
        ctx.insert(f)
        try ctx.save()
        XCTAssertEqual(try ctx.fetchCount(FetchDescriptor<Folder>()), 1)
    }

    func test_defaultSortOrder_isZero() {
        XCTAssertEqual(Folder(name: "x").sortOrder, 0)
    }
}
