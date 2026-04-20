import XCTest
import SwiftData
@testable import SimpleNotes

final class ModelContainerFactoryTests: XCTestCase {
    func test_inMemoryFactory_returnsWorkingContainer() throws {
        let container = try ModelContainerFactory.inMemory()
        let context = ModelContext(container)
        context.insert(Note(body: "x"))
        try context.save()
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<Note>()), 1)
    }

    func test_inMemoryFactory_supportsAllModelTypes() throws {
        let container = try ModelContainerFactory.inMemory()
        let context = ModelContext(container)
        context.insert(Folder(name: "Inbox"))
        context.insert(Tag(name: "swift"))
        context.insert(Attachment(filename: "a.txt", data: Data([0x61])))
        context.insert(Note(body: "hello"))
        try context.save()
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<Folder>()), 1)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<Tag>()), 1)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<Attachment>()), 1)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<Note>()), 1)
    }
}
