import UIKit

enum HapticService {
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }

    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }

    static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }

    static func lightTap() {
        impact(.light)
    }

    static func mediumTap() {
        impact(.medium)
    }

    static func heavyTap() {
        impact(.heavy)
    }

    static func success() {
        notification(.success)
    }

    static func warning() {
        notification(.warning)
    }

    static func error() {
        notification(.error)
    }

    // Паттерн для удаления
    static func destructionPattern() {
        heavyTap()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { mediumTap() }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { lightTap() }
    }

    // Паттерн для успеха
    static func successPattern() {
        lightTap()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { mediumTap() }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { success() }
    }
}
