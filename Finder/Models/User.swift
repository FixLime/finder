import Foundation

struct FinderUser: Codable, Identifiable, Hashable {
    let id: UUID
    var username: String
    var displayName: String
    var avatarIcon: String // SF Symbol name
    var avatarColor: AvatarColor
    var statusText: String
    var isOnline: Bool
    var lastSeen: Date?
    var isVerified: Bool
    var isUntrusted: Bool
    var isBanned: Bool
    var isDeleted: Bool
    var finderID: String
    var joinDate: Date

    // Настройки конфиденциальности
    var privacySettings: PrivacySettings

    var isCensored: Bool {
        isBanned || isDeleted
    }

    static var current: FinderUser {
        FinderUser(
            id: UUID(),
            username: "me",
            displayName: "Я",
            avatarIcon: "person.fill",
            avatarColor: .blue,
            statusText: "Использую Finder",
            isOnline: true,
            lastSeen: nil,
            isVerified: true,
            isUntrusted: false,
            isBanned: false,
            isDeleted: false,
            finderID: "FID-\(UUID().uuidString.prefix(8).uppercased())",
            joinDate: Date(),
            privacySettings: .default
        )
    }
}

enum AvatarColor: String, Codable, Hashable, CaseIterable {
    case blue, purple, green, orange, red, cyan, indigo, pink, gray

    var color: Color {
        switch self {
        case .blue: return .blue
        case .purple: return .purple
        case .green: return .green
        case .orange: return .orange
        case .red: return .red
        case .cyan: return .cyan
        case .indigo: return .indigo
        case .pink: return .pink
        case .gray: return .gray
        }
    }
}

import SwiftUI

struct PrivacySettings: Codable, Hashable {
    var showOnlineStatus: Bool
    var showLastSeen: Bool
    var showReadReceipts: Bool
    var allowScreenshots: Bool
    var autoDeleteMessages: AutoDeleteInterval
    var hideTypingIndicator: Bool
    var ghostMode: Bool // Уникальная фича — полная невидимость
    var phantomMessages: Bool // Сообщения исчезают после прочтения
    var stealthKeyboard: Bool // Не показывает "печатает..."
    var antiForward: Bool // Запрет пересылки сообщений
    var selfDestructProfile: Bool // Профиль видно только при активном чате
    var ipMasking: Bool // Маскировка IP
    var decoyPin: String? // Фейковый PIN показывает пустой аккаунт

    static let `default` = PrivacySettings(
        showOnlineStatus: true,
        showLastSeen: true,
        showReadReceipts: true,
        allowScreenshots: false,
        autoDeleteMessages: .never,
        hideTypingIndicator: false,
        ghostMode: false,
        phantomMessages: false,
        stealthKeyboard: false,
        antiForward: false,
        selfDestructProfile: false,
        ipMasking: false,
        decoyPin: nil
    )
}

enum AutoDeleteInterval: String, Codable, CaseIterable, Hashable {
    case never = "Никогда"
    case thirtySeconds = "30 секунд"
    case fiveMinutes = "5 минут"
    case oneHour = "1 час"
    case oneDay = "1 день"
    case oneWeek = "1 неделя"
    case oneMonth = "1 месяц"

    var localizedName: (ru: String, en: String) {
        switch self {
        case .never: return ("Никогда", "Never")
        case .thirtySeconds: return ("30 секунд", "30 seconds")
        case .fiveMinutes: return ("5 минут", "5 minutes")
        case .oneHour: return ("1 час", "1 hour")
        case .oneDay: return ("1 день", "1 day")
        case .oneWeek: return ("1 неделя", "1 week")
        case .oneMonth: return ("1 месяц", "1 month")
        }
    }
}
