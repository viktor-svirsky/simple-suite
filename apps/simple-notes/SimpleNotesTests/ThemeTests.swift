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
        XCTAssertEqual(Theme.Font.sansName, "SF Pro Text")
        XCTAssertEqual(Theme.Font.monoName, "SF Mono")
    }

    func test_textStyle_mapsSizesToScalableTextStyles() {
        XCTAssertEqual(Theme.Font.textStyle(for: 11), .caption2)
        XCTAssertEqual(Theme.Font.textStyle(for: 12), .caption)
        XCTAssertEqual(Theme.Font.textStyle(for: 13), .footnote)
        XCTAssertEqual(Theme.Font.textStyle(for: 14), .subheadline)
        XCTAssertEqual(Theme.Font.textStyle(for: 15), .subheadline)
        XCTAssertEqual(Theme.Font.textStyle(for: 16), .callout)
        XCTAssertEqual(Theme.Font.textStyle(for: 17), .body)
    }
}
