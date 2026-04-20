import Foundation
import SwiftUI

@Observable
final class SyncStatus {
    enum State: Equatable {
        case disabled
        case offline
        case syncing
        case synced(lastSync: Date)
    }

    var state: State

    init(state: State = .disabled) {
        self.state = state
    }

    static var initial: SyncStatus {
        #if SIMPLE_NOTES_CLOUDKIT_ENABLED
        SyncStatus(state: .offline)
        #else
        SyncStatus(state: .disabled)
        #endif
    }
}

private struct SyncStatusKey: EnvironmentKey {
    static let defaultValue: SyncStatus = SyncStatus(state: .disabled)
}

extension EnvironmentValues {
    var syncStatus: SyncStatus {
        get { self[SyncStatusKey.self] }
        set { self[SyncStatusKey.self] = newValue }
    }
}
