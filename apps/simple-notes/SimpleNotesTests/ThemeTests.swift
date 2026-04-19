import XCTest
import SwiftUI
@testable import SimpleNotes

final class ThemeTests: XCTestCase {
    func test_metrics_haveExpectedValues() {
        XCTAssertEqual(Theme.Metric.radius, 8)
        XCTAssertEqual(Theme.Metric.padding, 16)
        XCTAssertEqual(Theme.Metric.hairline, 0.5)
    }

    func test_fontNames_areDefined() {
        XCTAssertEqual(Theme.Font.serifName, "New York")
        XCTAssertEqual(Theme.Font.monoName, "SF Mono")
    }
}
