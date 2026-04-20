import XCTest
@testable import SimpleNotes

final class HapticsTests: XCTestCase {
    @MainActor
    func test_fire_doesNotCrashWithoutUI() {
        Haptics.fire(.pin)
        Haptics.fire(.delete)
        Haptics.fire(.success)
    }
}
