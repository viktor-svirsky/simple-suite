import XCTest
@testable import SimpleNotes

final class SmokeTests: XCTestCase {
    func test_appBundleLoads() {
        let bundle = Bundle(for: SmokeTests.self)
        XCTAssertNotNil(bundle)
    }
}
