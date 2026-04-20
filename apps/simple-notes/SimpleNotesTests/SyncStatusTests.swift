import XCTest
@testable import SimpleNotes

final class SyncStatusTests: XCTestCase {
    func test_defaultInit_isDisabled() {
        let status = SyncStatus()
        XCTAssertEqual(status.state, .disabled)
    }

    func test_stateTransitions_viaMutation() {
        let status = SyncStatus(state: .offline)
        XCTAssertEqual(status.state, .offline)

        status.state = .syncing
        XCTAssertEqual(status.state, .syncing)

        let now = Date()
        status.state = .synced(lastSync: now)
        XCTAssertEqual(status.state, .synced(lastSync: now))

        status.state = .offline
        XCTAssertEqual(status.state, .offline)
    }

    func test_stateEquatability() {
        let d1 = Date(timeIntervalSince1970: 1000)
        let d2 = Date(timeIntervalSince1970: 2000)

        XCTAssertEqual(SyncStatus.State.disabled, .disabled)
        XCTAssertEqual(SyncStatus.State.offline, .offline)
        XCTAssertEqual(SyncStatus.State.syncing, .syncing)
        XCTAssertEqual(SyncStatus.State.synced(lastSync: d1), .synced(lastSync: d1))

        XCTAssertNotEqual(SyncStatus.State.disabled, .offline)
        XCTAssertNotEqual(SyncStatus.State.syncing, .synced(lastSync: d1))
        XCTAssertNotEqual(SyncStatus.State.synced(lastSync: d1), .synced(lastSync: d2))
    }

    func test_initial_whenFlagOff_isDisabled() {
        // Test suite runs under Debug (flag off). Initial must match that.
        #if SIMPLE_NOTES_CLOUDKIT_ENABLED
        XCTAssertEqual(SyncStatus.initial.state, .offline)
        #else
        XCTAssertEqual(SyncStatus.initial.state, .disabled)
        #endif
    }
}
