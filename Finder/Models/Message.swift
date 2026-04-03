import Foundation

struct Message: Codable, Identifiable, Hashable {
    let id: UUID
    let senderId: UUID
    let chatId: UUID
    var text: String
    let timestamp: Date
    var isRead: Bool
    var isDelivered: Bool
    var isEdited: Bool
    var replyToId: UUID?
    var messageType: MessageType
    var isPhantom: Bool // Исчезает после прочтения
    var selfDestructTime: TimeInterval? // Таймер самоуничтожения
    var isForwardable: Bool
    var encryptedPayload: EncryptedMessage?

    enum MessageType: String, Codable, Hashable {
        case text
        case image
        case voice
        case system
        case note
    }

    var isFromCurrentUser: Bool {
        senderId == AuthService.shared.currentUserId
    }

    static func system(_ text: String, chatId: UUID) -> Message {
        Message(
            id: UUID(),
            senderId: UUID(),
            chatId: chatId,
            text: text,
            timestamp: Date(),
            isRead: true,
            isDelivered: true,
            isEdited: false,
            replyToId: nil,
            messageType: .system,
            isPhantom: false,
            selfDestructTime: nil,
            isForwardable: false,
            encryptedPayload: nil
        )
    }
}
