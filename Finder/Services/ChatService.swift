import Foundation
import SwiftUI
import Combine

// MARK: - Call Record
struct CallRecord: Identifiable, Hashable {
    let id: UUID
    let user: FinderUser
    let timestamp: Date
    let isVideo: Bool
    let isOutgoing: Bool
    let isMissed: Bool
    let duration: Int? // seconds
}

class ChatService: ObservableObject {
    static let shared = ChatService()

    @Published var chats: [Chat] = []
    @Published var notes: [Note] = []
    @Published var callHistory: [CallRecord] = []
    @Published var isServerMode = false
    @Published var typingUsers: [String: String] = [:] // chatId -> userId

    private var cancellables = Set<AnyCancellable>()
    private let network = NetworkService.shared
    private let ws = WebSocketService.shared

    private init() {
        loadDemoData()
        setupWebSocketListeners()
    }

    // MARK: - Server Integration

    func connectToServer() {
        guard let token = network.authToken else { return }

        ws.connect(token: token)
        isServerMode = true

        // Load chats from server
        Task {
            do {
                let serverChats = try await network.getChats()
                let converted = serverChats.map { network.toChat($0) }
                await MainActor.run {
                    // Keep support chat, add server chats
                    let support = self.chats.filter { $0.isSupport }
                    self.chats = support + converted
                }
            } catch {
                print("[ChatService] Failed to load server chats: \(error)")
            }
        }
    }

    func disconnectFromServer() {
        ws.disconnect()
        isServerMode = false
        loadDemoData()
    }

    private func setupWebSocketListeners() {
        // New messages from WebSocket
        ws.messageReceived
            .receive(on: DispatchQueue.main)
            .sink { [weak self] serverMsg in
                guard let self = self else { return }
                let message = self.network.toMessage(serverMsg)
                if let chatId = UUID(uuidString: serverMsg.chat_id),
                   let index = self.chats.firstIndex(where: { $0.id == chatId }) {
                    self.chats[index].messages.append(message)
                    if !message.isFromCurrentUser {
                        self.chats[index].unreadCount += 1
                    }
                }
            }
            .store(in: &cancellables)

        // Typing indicators
        ws.typingReceived
            .receive(on: DispatchQueue.main)
            .sink { [weak self] info in
                self?.typingUsers[info.chatId] = info.userId
                // Clear after 3 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    if self?.typingUsers[info.chatId] == info.userId {
                        self?.typingUsers.removeValue(forKey: info.chatId)
                    }
                }
            }
            .store(in: &cancellables)

        // Read receipts
        ws.readReceived
            .receive(on: DispatchQueue.main)
            .sink { [weak self] info in
                guard let self = self,
                      let chatId = UUID(uuidString: info.chatId),
                      let chatIndex = self.chats.firstIndex(where: { $0.id == chatId }) else { return }
                // Mark messages as read
                for i in 0..<self.chats[chatIndex].messages.count {
                    self.chats[chatIndex].messages[i].isRead = true
                }
                self.chats[chatIndex].unreadCount = 0
            }
            .store(in: &cancellables)

        // User online/offline
        ws.userStatusChanged
            .receive(on: DispatchQueue.main)
            .sink { [weak self] info in
                guard let self = self,
                      let userId = UUID(uuidString: info.userId) else { return }
                for chatIndex in 0..<self.chats.count {
                    for pIndex in 0..<self.chats[chatIndex].participants.count {
                        if self.chats[chatIndex].participants[pIndex].id == userId {
                            self.chats[chatIndex].participants[pIndex].isOnline = info.isOnline
                        }
                    }
                }
            }
            .store(in: &cancellables)
    }

    func loadDemoData() {
        var demoChats: [Chat] = []

        // Finder Support
        let supportUser = FinderUser(
            id: UUID(),
            username: "finder_support",
            displayName: "Finder Support",
            avatarIcon: "headphones",
            avatarColor: .blue,
            statusText: "Мы всегда на связи",
            isOnline: true,
            lastSeen: nil,
            isVerified: true,
            isUntrusted: false,
            isBanned: false,
            isDeleted: false,
            finderID: "FID-SUPPORT",
            joinDate: Date().addingTimeInterval(-31536000),
            privacySettings: .default
        )

        let supportChatId = UUID()
        let supportChat = Chat(
            id: supportChatId,
            participants: [supportUser],
            messages: [
                Message(id: UUID(), senderId: supportUser.id, chatId: supportChatId, text: "Здравствуйте! Добро пожаловать в Finder. Чем можем помочь?", timestamp: Date().addingTimeInterval(-60), isRead: true, isDelivered: true, isEdited: false, replyToId: nil, messageType: .text, isPhantom: false, selfDestructTime: nil, isForwardable: true)
            ],
            isGroup: false,
            groupName: nil,
            isPinned: true,
            isMuted: false,
            isArchived: false,
            isNotes: false,
            unreadCount: 1,
            isSupport: true
        )
        demoChats.append(supportChat)

        chats = demoChats
        callHistory = []
    }

    func sendMessage(to chatId: UUID, text: String) {
        guard let index = chats.firstIndex(where: { $0.id == chatId }) else { return }

        let encryptionService = EncryptionService.shared
        var displayText = text
        var encryptedPayload: EncryptedMessage?

        do {
            let encrypted = try encryptionService.encrypt(text, for: chatId)
            encryptedPayload = encrypted
            displayText = text
        } catch {
            print("Encryption failed: \(error.localizedDescription)")
        }

        let message = Message(
            id: UUID(),
            senderId: AuthService.shared.currentUserId,
            chatId: chatId,
            text: displayText,
            timestamp: Date(),
            isRead: false,
            isDelivered: true,
            isEdited: false,
            replyToId: nil,
            messageType: .text,
            isPhantom: false,
            selfDestructTime: nil,
            isForwardable: true,
            encryptedPayload: encryptedPayload
        )
        chats[index].messages.append(message)

        RatingService.shared.addPoints(1)

        // Send via server if connected
        if isServerMode {
            let chatIdStr = chatId.uuidString
            ws.sendMessage(chatId: chatIdStr, text: text)
            // Also send via REST API for persistence
            Task {
                do {
                    _ = try await network.sendMessage(chatId: chatIdStr, text: text)
                } catch {
                    print("[ChatService] Server send failed: \(error)")
                }
            }
        } else {
            // Авто-ответ только в офлайн-режиме
            if !chats[index].isNotes && !chats[index].isSupport {
                let chatIndex = index
                DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 1...3)) { [weak self] in
                    guard let self = self, chatIndex < self.chats.count else { return }

                    let replies = [
                        "Интересно!", "Согласен", "Расскажи подробнее",
                        "Хорошо, понял", "Ок!", "Звучит здорово!",
                        "Давай обсудим позже", "Ладно", "Отлично!",
                        "Не уверен...", "Можно и так", "Точно!"
                    ]
                    let replyText = replies.randomElement() ?? "Ок"

                    let replyerId: UUID
                    if self.chats[chatIndex].isGroup {
                        replyerId = self.chats[chatIndex].participants.randomElement()?.id ?? UUID()
                    } else {
                        replyerId = self.chats[chatIndex].participants.first?.id ?? UUID()
                    }

                    var replyEncrypted: EncryptedMessage?
                    do {
                        replyEncrypted = try encryptionService.encrypt(replyText, for: chatId)
                    } catch {}

                    let reply = Message(
                        id: UUID(),
                        senderId: replyerId,
                        chatId: chatId,
                        text: replyText,
                        timestamp: Date(),
                        isRead: false,
                        isDelivered: true,
                        isEdited: false,
                        replyToId: nil,
                        messageType: .text,
                        isPhantom: false,
                        selfDestructTime: nil,
                        isForwardable: true,
                        encryptedPayload: replyEncrypted
                    )
                    self.chats[chatIndex].messages.append(reply)
                }
            }
        }
    }

    func deleteChat(_ chatId: UUID) {
        chats.removeAll { $0.id == chatId }
    }

    func addNote(_ text: String, category: Note.NoteCategory = .general) {
        let note = Note(id: UUID(), text: text, timestamp: Date(), isPinned: false, category: category)
        notes.insert(note, at: 0)
    }

    func deleteNote(_ noteId: UUID) {
        notes.removeAll { $0.id == noteId }
    }

    func clearAllData() {
        chats = []
        notes = []
        callHistory = []
    }

    // MARK: - Create Group

    func createGroup(name: String, participants: [FinderUser]) -> Chat {
        let chatId = UUID()
        let systemMessage = Message.system("Группа \"\(name)\" создана", chatId: chatId)
        let chat = Chat(
            id: chatId,
            participants: participants,
            messages: [systemMessage],
            isGroup: true,
            groupName: name,
            isPinned: false,
            isMuted: false,
            isArchived: false,
            isNotes: false,
            unreadCount: 0
        )
        chats.append(chat)
        return chat
    }

    // MARK: - Create Channel

    func createChannel(name: String) -> Chat {
        let chatId = UUID()
        let systemMessage = Message.system("Канал \"\(name)\" создан", chatId: chatId)
        let chat = Chat(
            id: chatId,
            participants: [],
            messages: [systemMessage],
            isGroup: false,
            groupName: name,
            isPinned: false,
            isMuted: false,
            isArchived: false,
            isNotes: false,
            unreadCount: 0,
            isChannel: true
        )
        chats.append(chat)
        return chat
    }

    // MARK: - Search by Username

    @Published var searchResults: [FinderUser] = []
    @Published var isSearching = false

    func searchUsers(query: String) -> [FinderUser] {
        guard !query.isEmpty else { return [] }
        if isServerMode {
            return searchResults
        }
        let q = query.lowercased()
        return Self.demoUsers.filter {
            $0.username.lowercased().contains(q) ||
            $0.displayName.lowercased().contains(q)
        }
    }

    func searchUsersOnServer(query: String) {
        guard !query.isEmpty else {
            searchResults = []
            isSearching = false
            return
        }
        guard isServerMode else { return }
        isSearching = true
        Task {
            do {
                let serverUsers = try await network.searchUsers(query: query)
                let users = serverUsers.map { network.toFinderUser($0) }
                    .filter { $0.id != AuthService.shared.currentUserId && !$0.isCensored }
                await MainActor.run {
                    self.searchResults = users
                    self.isSearching = false
                }
            } catch {
                print("[ChatService] Server search failed: \(error)")
                await MainActor.run {
                    self.searchResults = []
                    self.isSearching = false
                }
            }
        }
    }

    func startChat(with user: FinderUser) -> Chat {
        if let existing = chats.first(where: {
            !$0.isGroup && !$0.isChannel && !$0.isNotes && !$0.isSupport &&
            $0.participants.contains(where: { $0.username == user.username })
        }) {
            return existing
        }

        let chatId = UUID()
        let chat = Chat(
            id: chatId,
            participants: [user],
            messages: [],
            isGroup: false,
            groupName: nil,
            isPinned: false,
            isMuted: false,
            isArchived: false,
            isNotes: false,
            unreadCount: 0
        )
        chats.append(chat)

        // Create on server if connected
        if isServerMode {
            createServerChat(with: user)
        }

        return chat
    }

    // MARK: - Server Methods

    func sendTyping(chatId: UUID) {
        guard isServerMode else { return }
        ws.sendTyping(chatId: chatId.uuidString)
    }

    func markAsReadOnServer(chatId: UUID, messageId: UUID) {
        guard isServerMode else { return }
        ws.sendRead(chatId: chatId.uuidString, messageId: messageId.uuidString)
    }

    func loadMessages(for chatId: UUID) {
        guard isServerMode else { return }
        Task {
            do {
                let serverMessages = try await network.getMessages(chatId: chatId.uuidString)
                let messages = serverMessages.map { network.toMessage($0) }
                await MainActor.run {
                    if let index = self.chats.firstIndex(where: { $0.id == chatId }) {
                        self.chats[index].messages = messages
                    }
                }
            } catch {
                print("[ChatService] Failed to load messages: \(error)")
            }
        }
    }

    func createServerChat(with user: FinderUser) {
        guard isServerMode else { return }
        Task {
            do {
                let serverChat = try await network.createChat(participantIds: [user.id.uuidString])
                let chat = network.toChat(serverChat)
                await MainActor.run {
                    self.chats.append(chat)
                }
            } catch {
                print("[ChatService] Failed to create chat: \(error)")
            }
        }
    }

    func createServerGroup(name: String, participants: [FinderUser]) {
        guard isServerMode else { return }
        Task {
            do {
                let ids = participants.map { $0.id.uuidString }
                let serverChat = try await network.createChat(participantIds: ids, isGroup: true, groupName: name)
                let chat = network.toChat(serverChat)
                await MainActor.run {
                    self.chats.append(chat)
                }
            } catch {
                print("[ChatService] Failed to create group: \(error)")
            }
        }
    }

    // MARK: - Demo Data (3 тестовых: обычный, удалённый, забаненный)

    static let demoUsers: [FinderUser] = [
        FinderUser(id: UUID(), username: "test_user", displayName: "Test User", avatarIcon: "person.fill", avatarColor: .blue, statusText: "Тестирую Finder", isOnline: true, lastSeen: nil, isVerified: false, isUntrusted: false, isBanned: false, isDeleted: false, finderID: "FID-TEST0001", joinDate: Date().addingTimeInterval(-604800), privacySettings: .default),
        FinderUser(id: UUID(), username: "deleted_user", displayName: "Deleted Account", avatarIcon: "person.fill", avatarColor: .gray, statusText: "", isOnline: false, lastSeen: Date().addingTimeInterval(-604800), isVerified: false, isUntrusted: false, isBanned: false, isDeleted: true, finderID: "FID-DEL00001", joinDate: Date().addingTimeInterval(-432000), privacySettings: .default),
        FinderUser(id: UUID(), username: "banned_user", displayName: "Banned Account", avatarIcon: "person.fill", avatarColor: .gray, statusText: "", isOnline: false, lastSeen: Date().addingTimeInterval(-1209600), isVerified: false, isUntrusted: false, isBanned: true, isDeleted: false, finderID: "FID-BAN00001", joinDate: Date().addingTimeInterval(-864000), privacySettings: .default)
    ]

    static func generateDemoMessages(for user: FinderUser, chatId: UUID, currentUserId: UUID) -> [Message] {
        let conversations: [[String]] = [
            ["Привет! Как дела?", "Привет! Всё отлично, спасибо!", "Пробовал новый Finder?", "Да, крутой мессенджер!", "Шифрование на высоте", "Согласен!"],
            ["Эй, видел обновление?", "Ещё нет, что нового?", "Добавили протокол Fenix!", "Вау, это серьёзно!", "Да, можно всё удалить одним нажатием"],
            ["Привет! Как включить Ghost Mode?", "Заходи в Профиль, Конфиденциальность", "Спасибо! А он реально скрывает онлайн?", "Да, и набор текста, и прочтение", "Отлично, мне это нужно"]
        ]

        let conversation = conversations.randomElement() ?? conversations[0]
        var messages: [Message] = []
        let baseTime = Date().addingTimeInterval(-Double(conversation.count) * 600)

        for (index, text) in conversation.enumerated() {
            let isFromUser = index % 2 == 0
            let message = Message(
                id: UUID(),
                senderId: isFromUser ? user.id : currentUserId,
                chatId: chatId,
                text: text,
                timestamp: baseTime.addingTimeInterval(Double(index) * 600),
                isRead: index < conversation.count - 1,
                isDelivered: true,
                isEdited: false,
                replyToId: nil,
                messageType: .text,
                isPhantom: false,
                selfDestructTime: nil,
                isForwardable: true
            )
            messages.append(message)
        }

        return messages
    }
}
