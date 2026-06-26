import UIKit

@MainActor
enum Haptics {
    private static let notification = UINotificationFeedbackGenerator()
    private static let lightImpact  = UIImpactFeedbackGenerator(style: .light)
    private static let mediumImpact = UIImpactFeedbackGenerator(style: .medium)

    private static var isSimulator: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }

    /// Pre-calienta el motor háptico (~3-4s). Usar cuando vaya a venir un disparo crítico, como al detectar un QR.
    static func prepare() {
        guard !isSimulator else { return }
        notification.prepare()
        lightImpact.prepare()
        mediumImpact.prepare()
    }

    static func success() {
        guard !isSimulator else { return }
        notification.notificationOccurred(.success)
        notification.prepare()
    }

    static func error() {
        guard !isSimulator else { return }
        notification.notificationOccurred(.error)
        notification.prepare()
    }

    static func warning() {
        guard !isSimulator else { return }
        notification.notificationOccurred(.warning)
        notification.prepare()
    }

    static func light() {
        guard !isSimulator else { return }
        lightImpact.impactOccurred()
        lightImpact.prepare()
    }

    static func medium() {
        guard !isSimulator else { return }
        mediumImpact.impactOccurred()
        mediumImpact.prepare()
    }
}
