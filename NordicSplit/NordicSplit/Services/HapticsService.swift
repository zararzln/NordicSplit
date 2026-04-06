import UIKit

/// Thin wrapper around UIImpactFeedbackGenerator so views don't import UIKit directly.
struct HapticsService {

    func light() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    func medium() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    func error() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }
}
