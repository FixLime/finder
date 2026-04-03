import Foundation
import SwiftUI
import AVFoundation
import Combine
import CallKit

class CallManager: ObservableObject {
    static let shared = CallManager()

    @Published var activeCall: ActiveCall?
    @Published var incomingCall: IncomingCallInfo?
    @Published var callState: CallState = .idle
    @Published var callDuration: TimeInterval = 0
    @Published var isMuted = false
    @Published var isSpeakerOn = false
    @Published var isCameraOn = true

    private var durationTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    private let network = NetworkService.shared
    private let ws = WebSocketService.shared
    private let callKit = CallKitService.shared
    private let webRTC = WebRTCService.shared

    enum CallState: Equatable {
        case idle
        case calling
        case ringing
        case connected
        case ended
    }

    struct ActiveCall {
        let callId: String
        let chatId: String
        let user: FinderUser
        let isVideo: Bool
        let isOutgoing: Bool
    }

    struct IncomingCallInfo {
        let callId: String
        let chatId: String
        let isVideo: Bool
        let callerName: String
        let callerId: String
    }

    private init() {
        setupListeners()
        setupCallKitCallbacks()
    }

    private func setupCallKitCallbacks() {
        callKit.onAnswerCall = { [weak self] in
            DispatchQueue.main.async {
                self?.answerCall()
            }
        }
        callKit.onEndCall = { [weak self] in
            DispatchQueue.main.async {
                self?.endCallInternal()
            }
        }
    }

    private func setupListeners() {
        // Incoming call via WebSocket
        ws.incomingCall
            .receive(on: DispatchQueue.main)
            .sink { [weak self] info in
                guard let self = self else { return }

                let callInfo = IncomingCallInfo(
                    callId: info.callId,
                    chatId: info.chatId,
                    isVideo: info.isVideo,
                    callerName: info.from,
                    callerId: info.from
                )
                self.incomingCall = callInfo

                // Report to CallKit — shows on Dynamic Island & lock screen
                self.callKit.reportIncomingCall(
                    callerName: info.from,
                    isVideo: info.isVideo
                ) { [weak self] uuid in
                    if uuid != nil {
                        self?.callState = .ringing
                    }
                }
            }
            .store(in: &cancellables)

        // Call ended remotely
        ws.callEnded
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.callKit.reportCallEnded(reason: .remoteEnded)
                self?.endCallInternal()
            }
            .store(in: &cancellables)
    }

    // MARK: - Start Call (Outgoing)

    func startCall(user: FinderUser, chatId: UUID, isVideo: Bool) {
        let callId = UUID().uuidString
        let call = ActiveCall(
            callId: callId,
            chatId: chatId.uuidString,
            user: user,
            isVideo: isVideo,
            isOutgoing: true
        )
        activeCall = call
        callState = .calling

        // Report to CallKit for Dynamic Island
        _ = callKit.startOutgoingCall(to: user.displayName, isVideo: isVideo)

        // Start WebRTC
        webRTC.startCall(
            callId: callId,
            remoteUserId: user.id.uuidString,
            isVideo: isVideo
        )

        // Notify server
        Task {
            do {
                let serverCall = try await network.startCall(chatId: chatId.uuidString, isVideo: isVideo)
                await MainActor.run {
                    self.activeCall = ActiveCall(
                        callId: serverCall.id,
                        chatId: chatId.uuidString,
                        user: user,
                        isVideo: isVideo,
                        isOutgoing: true
                    )
                }
            } catch {
                print("[CallManager] Start call failed: \(error)")
            }
        }
    }

    // MARK: - Answer Call (Incoming)

    func answerCall() {
        guard let incoming = incomingCall else { return }

        let callerUser = FinderUser(
            id: UUID(uuidString: incoming.callerId) ?? UUID(),
            username: incoming.callerName,
            displayName: incoming.callerName,
            avatarIcon: "person.fill",
            avatarColor: .blue,
            statusText: "",
            isOnline: true,
            lastSeen: nil,
            isVerified: false,
            isBanned: false,
            isDeleted: false,
            finderID: "",
            joinDate: Date(),
            privacySettings: .default
        )

        activeCall = ActiveCall(
            callId: incoming.callId,
            chatId: incoming.chatId,
            user: callerUser,
            isVideo: incoming.isVideo,
            isOutgoing: false
        )

        incomingCall = nil
        callState = .connected

        // Start WebRTC answer
        webRTC.answerCall(
            callId: incoming.callId,
            remoteUserId: incoming.callerId,
            isVideo: incoming.isVideo
        )

        callKit.reportCallConnected()
        startDurationTimer()

        // Notify server
        Task {
            do {
                _ = try await network.endCall(callId: incoming.callId, status: "accepted", duration: nil)
            } catch {
                print("[CallManager] Answer call failed: \(error)")
            }
        }
    }

    // MARK: - Decline Call

    func declineCall() {
        guard let incoming = incomingCall else { return }
        incomingCall = nil
        callState = .idle

        callKit.reportCallEnded(reason: .declinedElsewhere)

        Task {
            do {
                _ = try await network.endCall(callId: incoming.callId, status: "rejected", duration: nil)
            } catch {
                print("[CallManager] Decline call failed: \(error)")
            }
        }
    }

    // MARK: - End Call (User initiated)

    func endCall() {
        callKit.endCall()
        endCallInternal()
    }

    private func endCallInternal() {
        guard let call = activeCall else {
            callState = .idle
            return
        }

        let duration = Int(callDuration)

        // End WebRTC
        webRTC.endCall()

        // Notify server
        Task {
            do {
                _ = try await network.endCall(callId: call.callId, status: "ended", duration: duration)
            } catch {
                print("[CallManager] End call failed: \(error)")
            }
        }

        // Add to call history
        let record = CallRecord(
            id: UUID(),
            user: call.user,
            timestamp: Date(),
            isVideo: call.isVideo,
            isOutgoing: call.isOutgoing,
            isMissed: false,
            duration: duration
        )
        ChatService.shared.callHistory.insert(record, at: 0)

        // Reset state
        durationTimer?.invalidate()
        durationTimer = nil
        activeCall = nil
        callState = .idle
        callDuration = 0
        isMuted = false
        isSpeakerOn = false
        isCameraOn = true
    }

    // MARK: - Controls

    func toggleMute() {
        isMuted.toggle()
        webRTC.toggleAudio()
        callKit.setMuted(isMuted)
    }

    func toggleSpeaker() {
        isSpeakerOn.toggle()
        let session = AVAudioSession.sharedInstance()
        do {
            if isSpeakerOn {
                try session.overrideOutputAudioPort(.speaker)
            } else {
                try session.overrideOutputAudioPort(.none)
            }
        } catch {
            print("Speaker toggle error: \(error)")
        }
    }

    func toggleCamera() {
        isCameraOn.toggle()
        webRTC.toggleVideo()
    }

    func switchCamera() {
        webRTC.switchCamera()
    }

    // MARK: - Private

    private func startDurationTimer() {
        callDuration = 0
        durationTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.callDuration += 1
            }
        }
    }

    var formattedDuration: String {
        let mins = Int(callDuration) / 60
        let secs = Int(callDuration) % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}
