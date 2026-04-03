import Foundation

struct Chat: Codable, Identifiable, Hashable {
    let id: UUID
    var participants: [FinderUser]
    var messages: [Message]
    var isGroup: Bool
    var isChannel: Bool
    var groupName: String?
    var isPinned: Bool
    var isMuted: Bool
    var isArchived: Bool
    var isNotes: Bool
    var isSupport: Bool
    var unreadCount: Int

    init(id: UUID, participants: [FinderUser], messages: [Message], isGroup: Bool, groupName: String? = nil, isPinned: Bool = false, isMuted: Bool = false, isArchived: Bool = false, isNotes: Bool = false, unreadCount: Int = 0, isChannel: Bool = false, isSupport: Bool = false) {
        self.id = id
        self.participants = participants
        self.messages = messages
        self.isGroup = isGroup
        self.isChannel = isChannel
        self.groupName = groupName
        self.isPinned = isPinned
        self.isMuted = isMuted
        self.isArchived = isArchived
        self.isNotes = isNotes
        self.isSupport = isSupport
        self.unreadCount = unreadCount
    }

    var lastMessage: Message? {
        messages.sorted { $0.timestamp > $1.timestamp }.first
    }

    var displayName: String {
        if isNotes { return "Заметки" }
        if isSupport { return "Finder Support" }
        if isGroup || isChannel { return groupName ?? (isChannel ? "Канал" : "Группа") }
        return participants.first { $0.id != AuthService.shared.currentUserId }?.displayName ?? "Неизвестный"
    }

    var otherUser: FinderUser? {
        participants.first { $0.id != AuthService.shared.currentUserId }
    }

    var isVerifiedChat: Bool {
        if isNotes { return true }
        if isSupport { return true }
        if isGroup || isChannel {
            if let name = groupName {
                return AdminService.shared.isVerified(name)
            }
            return false
        }
        return participants.contains { $0.isVerified || AdminService.shared.isVerified($0.username) }
    }
}

struct Note: Codable, Identifiable, Hashable {
    let id: UUID
    var text: String
    var timestamp: Date
    var isPinned: Bool
    var category: NoteCategory

    enum NoteCategory: String, Codable, CaseIterable, Hashable {
        case general = "Общее"
        case important = "Важное"
        case ideas = "Идеи"
        case links = "Ссылки"
        case passwords = "Пароли"
    }
}
