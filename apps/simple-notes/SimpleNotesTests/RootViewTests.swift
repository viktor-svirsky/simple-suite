import XCTest
import SwiftUI
@testable import SimpleNotes

final class RootViewTests: XCTestCase {
    func test_rootView_canBeInstantiated() {
        let view = RootView()
        XCTAssertNotNil(view.body)
    }
}
