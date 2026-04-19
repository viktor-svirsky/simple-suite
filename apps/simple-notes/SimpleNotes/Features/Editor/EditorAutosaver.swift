import Foundation

@MainActor
final class EditorAutosaver {
    private let debounce: Duration
    private var pending: Task<Void, Never>?
    private var onFlushAction: (@MainActor () -> Void)?

    init(debounce: Duration = .milliseconds(500)) {
        self.debounce = debounce
    }

    func onFlush(_ action: @escaping @MainActor () -> Void) {
        onFlushAction = action
    }

    func scheduleTouch(on note: Note) {
        pending?.cancel()
        pending = Task { [debounce, weak self] in
            do {
                try await Task.sleep(for: debounce)
            } catch {
                return
            }
            guard !Task.isCancelled else { return }
            note.touch()
            self?.onFlushAction?()
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
