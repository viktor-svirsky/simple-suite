import Foundation

@MainActor
final class EditorAutosaver {
    private let debounce: Duration
    private var pending: Task<Void, Never>?

    init(debounce: Duration = .milliseconds(500)) {
        self.debounce = debounce
    }

    func scheduleTouch(on note: Note) {
        pending?.cancel()
        pending = Task { [debounce] in
            do {
                try await Task.sleep(for: debounce)
            } catch {
                return
            }
            guard !Task.isCancelled else { return }
            note.touch()
        }
    }

    func cancel() {
        pending?.cancel()
        pending = nil
    }

    deinit {
        pending?.cancel()
    }
}
