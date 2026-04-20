import Foundation
import CoreData

final class SyncObserver {
    private let status: SyncStatus
    private var tokens: [NSObjectProtocol] = []

    init(status: SyncStatus) {
        self.status = status
    }

    func start() {
        #if SIMPLE_NOTES_CLOUDKIT_ENABLED
        observeCloudKitEvents()
        observeAccountChanges()
        refreshAccountStatus()
        #endif
    }

    func stop() {
        for token in tokens {
            NotificationCenter.default.removeObserver(token)
        }
        tokens.removeAll()
    }

    deinit {
        stop()
    }

    #if SIMPLE_NOTES_CLOUDKIT_ENABLED
    private func observeCloudKitEvents() {
        let token = NotificationCenter.default.addObserver(
            forName: NSPersistentCloudKitContainer.eventChangedNotification,
            object: nil,
            queue: .main
        ) { [weak self] note in
            guard
                let self,
                let event = note.userInfo?[NSPersistentCloudKitContainer.eventNotificationUserInfoKey]
                    as? NSPersistentCloudKitContainer.Event
            else { return }
            self.apply(event: event)
        }
        tokens.append(token)
    }

    private func apply(event: NSPersistentCloudKitContainer.Event) {
        if event.endDate == nil {
            status.state = .syncing
        } else if event.error != nil {
            status.state = .offline
        } else {
            status.state = .synced(lastSync: event.endDate ?? Date())
        }
    }

    private func observeAccountChanges() {
        let token = NotificationCenter.default.addObserver(
            forName: .NSUbiquityIdentityDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.refreshAccountStatus()
        }
        tokens.append(token)
    }

    private func refreshAccountStatus() {
        if FileManager.default.ubiquityIdentityToken == nil {
            status.state = .offline
        }
    }
    #endif
}
