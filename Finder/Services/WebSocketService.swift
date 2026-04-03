import Foundation
import Combine

// MARK: - WebSocket Message Types

enum WSIncoming {
    case message(ServerMessage)
    case typing(chatId: String, userId: String)
    case read(chatId: String, userId: String, messageId: String)
    case userOnline(userId: String)
    case userOffline(userId: String)
    case webrtcOffer(callId: String, sdp: String, from: String)
    case webrtcAnswer(callId: String, sdp: String, from: String)
    case webrtcIceCandidate(callId: String, candidate: String, from: String)
    case callIncoming(callId: String, chatId: String, isVideo: Bool, from: String)
    case callEnded(callId: String)
    case unknown
}

class WebSocketService: ObservableObject {
    static let shared = WebSocketService()

    private let wsURL = "ws://155.212.165.134:3001"
    private var webSocket: URLSessionWebSocketTask?
    private var session: URLSession?
    private var pingTimer: Timer?

    @Published var isConnected = false

    // Event publishers
    let messageReceived = PassthroughSubject<ServerMessage, Never>()
    let typingReceived = PassthroughSubject<(chatId: String, userId: String), Never>()
    let readReceived = PassthroughSubject<(chatId: String, userId: String, messageId: String), Never>()
    let userStatusChanged = PassthroughSubject<(userId: String, isOnline: Bool), Never>()
    let webrtcSignal = PassthroughSubject<WSIncoming, Never>()
    let incomingCall = PassthroughSubject<(callId: String, chatId: String, isVideo: Bool, from: String), Never>()
    let callEnded = PassthroughSubject<String, Never>()

    private var reconnectAttempts = 0
    private let maxReconnectAttempts = 10

    private init() {}

    // MARK: - Connect

    func connect(token: String) {
        guard let url = URL(string: wsURL) else { return }

        let config = URLSessionConfiguration.default
        session = URLSession(configuration: config)
        webSocket = session?.webSocketTask(with: url)
        webSocket?.resume()

        // Authenticate
        let authMsg: [String: String] = ["type": "auth", "token": token]
        send(authMsg)

        startReceiving()
        startPing()

        reconnectAttempts = 0
        DispatchQueue.main.async { self.isConnected = true }
    }

    func disconnect() {
        pingTimer?.invalidate()
        pingTimer = nil
        webSocket?.cancel(with: .normalClosure, reason: nil)
        webSocket = nil
        DispatchQueue.main.async { self.isConnected = false }
    }

    // MARK: - Send

    func sendMessage(chatId: String, text: String, messageType: String = "text") {
        let msg: [String: String] = [
            "type": "message",
            "chat_id": chatId,
            "text": text,
            "message_type": messageType
        ]
        send(msg)
    }

    func sendTyping(chatId: String) {
        send(["type": "typing", "chat_id": chatId])
    }

    func sendRead(chatId: String, messageId: String) {
        send(["type": "read", "chat_id": chatId, "message_id": messageId])
    }

    // MARK: - WebRTC Signaling

    func sendWebRTCOffer(callId: String, sdp: String, to: String) {
        send([
            "type": "webrtc-offer",
            "call_id": callId,
            "sdp": sdp,
            "to": to
        ])
    }

    func sendWebRTCAnswer(callId: String, sdp: String, to: String) {
        send([
            "type": "webrtc-answer",
            "call_id": callId,
            "sdp": sdp,
            "to": to
        ])
    }

    func sendICECandidate(callId: String, candidate: String, to: String) {
        send([
            "type": "ice-candidate",
            "call_id": callId,
            "candidate": candidate,
            "to": to
        ])
    }

    // MARK: - Internal

    private func send(_ dict: [String: String]) {
        guard let data = try? JSONSerialization.data(withJSONObject: dict),
              let str = String(data: data, encoding: .utf8) else { return }

        webSocket?.send(.string(str)) { error in
            if let error = error {
                print("[WS] Send error: \(error.localizedDescription)")
            }
        }
    }

    private func startReceiving() {
        webSocket?.receive { [weak self] result in
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    self?.handleMessage(text)
                case .data(let data):
                    if let text = String(data: data, encoding: .utf8) {
                        self?.handleMessage(text)
                    }
                @unknown default:
                    break
                }
                // Continue receiving
                self?.startReceiving()

            case .failure(let error):
                print("[WS] Receive error: \(error.localizedDescription)")
                DispatchQueue.main.async { self?.isConnected = false }
                self?.attemptReconnect()
            }
        }
    }

    private func handleMessage(_ text: String) {
        guard let data = text.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = json["type"] as? String else { return }

        DispatchQueue.main.async { [self] in
            switch type {
            case "message":
                if let msgData = try? JSONSerialization.data(withJSONObject: json["message"] ?? json),
                   let serverMsg = try? JSONDecoder().decode(ServerMessage.self, from: msgData) {
                    messageReceived.send(serverMsg)
                }

            case "typing":
                if let chatId = json["chat_id"] as? String,
                   let userId = json["user_id"] as? String {
                    typingReceived.send((chatId: chatId, userId: userId))
                }

            case "read":
                if let chatId = json["chat_id"] as? String,
                   let userId = json["user_id"] as? String,
                   let messageId = json["message_id"] as? String {
                    readReceived.send((chatId: chatId, userId: userId, messageId: messageId))
                }

            case "user-online":
                if let userId = json["user_id"] as? String {
                    userStatusChanged.send((userId: userId, isOnline: true))
                }

            case "user-offline":
                if let userId = json["user_id"] as? String {
                    userStatusChanged.send((userId: userId, isOnline: false))
                }

            case "webrtc-offer":
                if let callId = json["call_id"] as? String,
                   let sdp = json["sdp"] as? String,
                   let from = json["from"] as? String {
                    webrtcSignal.send(.webrtcOffer(callId: callId, sdp: sdp, from: from))
                }

            case "webrtc-answer":
                if let callId = json["call_id"] as? String,
                   let sdp = json["sdp"] as? String,
                   let from = json["from"] as? String {
                    webrtcSignal.send(.webrtcAnswer(callId: callId, sdp: sdp, from: from))
                }

            case "ice-candidate":
                if let callId = json["call_id"] as? String,
                   let candidate = json["candidate"] as? String,
                   let from = json["from"] as? String {
                    webrtcSignal.send(.webrtcIceCandidate(callId: callId, candidate: candidate, from: from))
                }

            case "call-incoming":
                if let callId = json["call_id"] as? String,
                   let chatId = json["chat_id"] as? String,
                   let isVideo = json["is_video"] as? Bool,
                   let from = json["from"] as? String {
                    incomingCall.send((callId: callId, chatId: chatId, isVideo: isVideo, from: from))
                }

            case "call-ended":
                if let callId = json["call_id"] as? String {
                    callEnded.send(callId)
                }

            default:
                break
            }
        }
    }

    private func startPing() {
        pingTimer?.invalidate()
        pingTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.webSocket?.sendPing { error in
                if let error = error {
                    print("[WS] Ping error: \(error.localizedDescription)")
                    DispatchQueue.main.async { self?.isConnected = false }
                    self?.attemptReconnect()
                }
            }
        }
    }

    private func attemptReconnect() {
        guard reconnectAttempts < maxReconnectAttempts else {
            print("[WS] Max reconnect attempts reached")
            return
        }

        reconnectAttempts += 1
        let delay = min(Double(reconnectAttempts) * 2, 30)

        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let token = NetworkService.shared.authToken else { return }
            print("[WS] Reconnecting... attempt \(self?.reconnectAttempts ?? 0)")
            self?.connect(token: token)
        }
    }
}
