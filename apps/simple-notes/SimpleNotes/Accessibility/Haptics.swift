import UIKit

enum Haptics {
    enum Kind {
        case pin, delete, success
    }

    @MainActor
    static func fire(_ kind: Kind) {
        switch kind {
        case .pin:
            let g = UIImpactFeedbackGenerator(style: .soft)
            g.prepare()
            g.impactOccurred()
        case .delete:
            let g = UINotificationFeedbackGenerator()
            g.prepare()
            g.notificationOccurred(.warning)
        case .success:
            let g = UINotificationFeedbackGenerator()
            g.prepare()
            g.notificationOccurred(.success)
        }
    }
}
