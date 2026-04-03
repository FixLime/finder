import Foundation

// MARK: - API Response Models

struct AuthResponse: Codable {
    let token: String
    let user: ServerUser
}

struct ServerUser: Codable {
    let id: String
    let username: String
    let display_name: String
    let avatar_url: String?
    let status_text: String?
    let is_online: Bool?
    let is_verified: Bool?
    let is_banned: Bool?
    let is_deleted: Bool?
    let finder_id: String?
    let created_at: String?
}

struct ServerChat: Codable {
    let id: String
    let is_group: Bool
    let is_channel: Bool?
    let group_name: String?
    let created_at: String?
    let members: [ServerUser]?
    let last_message: ServerMessage?
    let unread_count: Int?
}

struct ServerMessage: Codable {
    let id: String
    let chat_id: String
    let sender_id: String
    let text: String
    let message_type: String?
    let reply_to_id: String?
    let is_edited: Bool?
    let created_at: String?
    let sender: ServerUser?
}

struct ServerCall: Codable {
    let id: String
    let chat_id: String
    let caller_id: String
    let is_video: Bool
    let status: String
    let started_at: String?
    let ended_at: String?
    let duration: Int?
}

struct UploadResponse: Codable {
    let url: String
    let filename: String
}

struct APIError: Codable {
    let error: String
}

// MARK: - Network Service

class NetworkService: ObservableObject {
    static let shared = NetworkService()

    private let baseURL = "http://155.212.165.134:3000/api"
    @Published var authToken: String? {
        didSet {
            if let token = authToken {
                UserDefaults.standard.set(token, forKey: "serverAuthToken")
            } else {
                UserDefaults.standard.removeObject(forKey: "serverAuthToken")
            }
        }
    }
    @Published var serverUserId: String?
    @Published var isConnected = false

    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 60
        session = URLSession(configuration: config)

        decoder = JSONDecoder()
        encoder = JSONEncoder()

        // Restore saved token
        authToken = UserDefaults.standard.string(forKey: "serverAuthToken")
        serverUserId = UserDefaults.standard.string(forKey: "serverUserId")

        checkConnection()
    }

    // MARK: - Connection Check

    func checkConnection() {
        Task {
            do {
                let (_, response) = try await session.data(from: URL(string: "\(baseURL)/health")!)
                if let http = response as? HTTPURLResponse, http.statusCode == 200 {
                    await MainActor.run { isConnected = true }
                }
            } catch {
                await MainActor.run { isConnected = false }
            }
        }
    }

    // MARK: - Auth

    func register(username: String, password: String, displayName: String) async throws -> AuthResponse {
        let body: [String: Any] = [
            "username": username,
            "password": password,
            "display_name": displayName
        ]
        let response: AuthResponse = try await post("/register", body: body)
        await MainActor.run {
            self.authToken = response.token
            self.serverUserId = response.user.id
            UserDefaults.standard.set(response.user.id, forKey: "serverUserId")
            self.isConnected = true
        }
        return response
    }

    func login(username: String, password: String) async throws -> AuthResponse {
        let body: [String: Any] = [
            "username": username,
            "password": password
        ]
        let response: AuthResponse = try await post("/login", body: body)
        await MainActor.run {
            self.authToken = response.token
            self.serverUserId = response.user.id
            UserDefaults.standard.set(response.user.id, forKey: "serverUserId")
            self.isConnected = true
        }
        return response
    }

    // MARK: - Users

    func searchUsers(query: String) async throws -> [ServerUser] {
        return try await get("/users/search?q=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query)")
    }

    func getUser(id: String) async throws -> ServerUser {
        return try await get("/users/\(id)")
    }

    func updateProfile(displayName: String?, statusText: String?) async throws -> ServerUser {
        var body: [String: Any] = [:]
        if let name = displayName { body["display_name"] = name }
        if let status = statusText { body["status_text"] = status }
        return try await put("/users/me", body: body)
    }

    // MARK: - Chats

    func getChats() async throws -> [ServerChat] {
        return try await get("/chats")
    }

    func createChat(participantIds: [String], isGroup: Bool = false, groupName: String? = nil) async throws -> ServerChat {
        var body: [String: Any] = [
            "participant_ids": participantIds,
            "is_group": isGroup
        ]
        if let name = groupName { body["group_name"] = name }
        return try await post("/chats", body: body)
    }

    // MARK: - Messages

    func getMessages(chatId: String, limit: Int = 50, offset: Int = 0) async throws -> [ServerMessage] {
        return try await get("/chats/\(chatId)/messages?limit=\(limit)&offset=\(offset)")
    }

    func sendMessage(chatId: String, text: String, messageType: String = "text", replyToId: String? = nil) async throws -> ServerMessage {
        var body: [String: Any] = [
            "text": text,
            "message_type": messageType
        ]
        if let replyId = replyToId { body["reply_to_id"] = replyId }
        return try await post("/chats/\(chatId)/messages", body: body)
    }

    // MARK: - Files

    func uploadFile(data: Data, filename: String, mimeType: String) async throws -> UploadResponse {
        guard let url = URL(string: "\(baseURL)/upload") else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        addAuthHeader(&request)

        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var bodyData = Data()
        bodyData.append("--\(boundary)\r\n".data(using: .utf8)!)
        bodyData.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        bodyData.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        bodyData.append(data)
        bodyData.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = bodyData

        let (responseData, response) = try await session.data(for: request)
        try validateResponse(response)
        return try decoder.decode(UploadResponse.self, from: responseData)
    }

    // MARK: - Calls

    func startCall(chatId: String, isVideo: Bool) async throws -> ServerCall {
        let body: [String: Any] = [
            "chat_id": chatId,
            "is_video": isVideo
        ]
        return try await post("/calls", body: body)
    }

    func endCall(callId: String, status: String, duration: Int?) async throws -> ServerCall {
        var body: [String: Any] = ["status": status]
        if let dur = duration { body["duration"] = dur }
        return try await put("/calls/\(callId)", body: body)
    }

    // MARK: - Admin

    func adminBanUser(userId: String) async throws {
        let _: [String: String] = try await post("/admin/ban", body: ["user_id": userId])
    }

    func adminUnbanUser(userId: String) async throws {
        let _: [String: String] = try await post("/admin/unban", body: ["user_id": userId])
    }

    // MARK: - Generic HTTP Methods

    private func get<T: Decodable>(_ path: String) async throws -> T {
        guard let url = URL(string: "\(baseURL)\(path)") else {
            throw NetworkError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        addAuthHeader(&request)

        let (data, response) = try await session.data(for: request)
        try validateResponse(response)
        return try decoder.decode(T.self, from: data)
    }

    private func post<T: Decodable>(_ path: String, body: [String: Any]) async throws -> T {
        guard let url = URL(string: "\(baseURL)\(path)") else {
            throw NetworkError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        addAuthHeader(&request)
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)
        try validateResponse(response)
        return try decoder.decode(T.self, from: data)
    }

    private func put<T: Decodable>(_ path: String, body: [String: Any]) async throws -> T {
        guard let url = URL(string: "\(baseURL)\(path)") else {
            throw NetworkError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        addAuthHeader(&request)
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)
        try validateResponse(response)
        return try decoder.decode(T.self, from: data)
    }

    private func addAuthHeader(_ request: inout URLRequest) {
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
    }

    private func validateResponse(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        switch http.statusCode {
        case 200...299: return
        case 401: throw NetworkError.unauthorized
        case 403: throw NetworkError.forbidden
        case 404: throw NetworkError.notFound
        case 409: throw NetworkError.conflict
        case 500...599: throw NetworkError.serverError(http.statusCode)
        default: throw NetworkError.httpError(http.statusCode)
        }
    }

    // MARK: - Converters

    func toFinderUser(_ server: ServerUser) -> FinderUser {
        FinderUser(
            id: UUID(uuidString: server.id) ?? UUID(),
            username: server.username,
            displayName: server.display_name,
            avatarIcon: "person.fill",
            avatarColor: .blue,
            statusText: server.status_text ?? "",
            isOnline: server.is_online ?? false,
            lastSeen: nil,
            isVerified: server.is_verified ?? false,
            isBanned: server.is_banned ?? false,
            isDeleted: server.is_deleted ?? false,
            finderID: server.finder_id ?? "FID-\(server.id.prefix(8).uppercased())",
            joinDate: ISO8601DateFormatter().date(from: server.created_at ?? "") ?? Date(),
            privacySettings: .default
        )
    }

    func toMessage(_ server: ServerMessage) -> Message {
        let msgType: Message.MessageType = {
            switch server.message_type {
            case "image": return .image
            case "voice": return .voice
            case "system": return .system
            default: return .text
            }
        }()

        return Message(
            id: UUID(uuidString: server.id) ?? UUID(),
            senderId: UUID(uuidString: server.sender_id) ?? UUID(),
            chatId: UUID(uuidString: server.chat_id) ?? UUID(),
            text: server.text,
            timestamp: ISO8601DateFormatter().date(from: server.created_at ?? "") ?? Date(),
            isRead: true,
            isDelivered: true,
            isEdited: server.is_edited ?? false,
            replyToId: server.reply_to_id.flatMap { UUID(uuidString: $0) },
            messageType: msgType,
            isPhantom: false,
            selfDestructTime: nil,
            isForwardable: true
        )
    }

    func toChat(_ server: ServerChat) -> Chat {
        let participants = (server.members ?? []).map { toFinderUser($0) }
        let messages = server.last_message.map { [toMessage($0)] } ?? []

        return Chat(
            id: UUID(uuidString: server.id) ?? UUID(),
            participants: participants,
            messages: messages,
            isGroup: server.is_group,
            groupName: server.group_name,
            isPinned: false,
            isMuted: false,
            isArchived: false,
            isNotes: false,
            unreadCount: server.unread_count ?? 0,
            isChannel: server.is_channel ?? false
        )
    }

    func clearAuth() {
        authToken = nil
        serverUserId = nil
        UserDefaults.standard.removeObject(forKey: "serverUserId")
        isConnected = false
    }
}

// MARK: - Errors

enum NetworkError: LocalizedError {
    case invalidURL
    case invalidResponse
    case unauthorized
    case forbidden
    case notFound
    case conflict
    case serverError(Int)
    case httpError(Int)
    case decodingError

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .invalidResponse: return "Invalid response"
        case .unauthorized: return "Unauthorized"
        case .forbidden: return "Forbidden"
        case .notFound: return "Not found"
        case .conflict: return "Conflict"
        case .serverError(let code): return "Server error: \(code)"
        case .httpError(let code): return "HTTP error: \(code)"
        case .decodingError: return "Decoding error"
        }
    }
}
