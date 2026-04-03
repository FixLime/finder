import Foundation
import CallKit
import AVFoundation
import Combine

class CallKitService: NSObject, ObservableObject {
    static let shared = CallKitService()

    private let provider: CXProvider
    private let callController = CXCallController()
    private var activeCallUUID: UUID?
    private var cancellables = Set<AnyCancellable>()

    var onAnswerCall: (() -> Void)?
    var onEndCall: (() -> Void)?

    private override init() {
        let config = CXProviderConfiguration()
        config.supportsVideo = true
        config.maximumCallGroups = 1
        config.supportedHandleTypes = [.generic]
        config.includesCallsInRecents = true

        provider = CXProvider(configuration: config)

        super.init()
        provider.setDelegate(self, queue: nil)
    }

    // MARK: - Report Incoming Call

    func reportIncomingCall(
        callerName: String,
        isVideo: Bool,
        completion: @escaping (UUID?) -> Void
    ) {
        let callUUID = UUID()
        activeCallUUID = callUUID

        let update = CXCallUpdate()
        update.remoteHandle = CXHandle(type: .generic, value: callerName)
        update.localizedCallerName = callerName
        update.hasVideo = isVideo
        update.supportsHolding = false
        update.supportsGrouping = false
        update.supportsUngrouping = false
        update.supportsDTMF = false

        provider.reportNewIncomingCall(with: callUUID, update: update) { error in
            if let error = error {
                print("[CallKit] Report incoming call error: \(error.localizedDescription)")
                completion(nil)
            } else {
                print("[CallKit] Incoming call reported successfully")
                completion(callUUID)
            }
        }
    }

    // MARK: - Start Outgoing Call

    func startOutgoingCall(to handle: String, isVideo: Bool) -> UUID {
        let callUUID = UUID()
        activeCallUUID = callUUID

        let cxHandle = CXHandle(type: .generic, value: handle)
        let startAction = CXStartCallAction(call: callUUID, handle: cxHandle)
        startAction.isVideo = isVideo

        let transaction = CXTransaction(action: startAction)
        callController.request(transaction) { error in
            if let error = error {
                print("[CallKit] Start call error: \(error.localizedDescription)")
            }
        }

        // Update call info for system UI
        let update = CXCallUpdate()
        update.remoteHandle = cxHandle
        update.localizedCallerName = handle
        update.hasVideo = isVideo
        provider.reportCall(with: callUUID, updated: update)

        return callUUID
    }

    // MARK: - Report Call Connected

    func reportCallConnected() {
        guard let uuid = activeCallUUID else { return }
        provider.reportOutgoingCall(with: uuid, connectedAt: Date())
    }

    // MARK: - Report Call Ended

    func reportCallEnded(reason: CXCallEndedReason = .remoteEnded) {
        guard let uuid = activeCallUUID else { return }
        provider.reportCall(with: uuid, endedAt: Date(), reason: reason)
        activeCallUUID = nil
    }

    // MARK: - End Call (user initiated)

    func endCall() {
        guard let uuid = activeCallUUID else { return }
        let endAction = CXEndCallAction(call: uuid)
        let transaction = CXTransaction(action: endAction)
        callController.request(transaction) { error in
            if let error = error {
                print("[CallKit] End call error: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Mute

    func setMuted(_ muted: Bool) {
        guard let uuid = activeCallUUID else { return }
        let muteAction = CXSetMutedCallAction(call: uuid, muted: muted)
        let transaction = CXTransaction(action: muteAction)
        callController.request(transaction) { error in
            if let error = error {
                print("[CallKit] Mute error: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - CXProviderDelegate

extension CallKitService: CXProviderDelegate {
    func providerDidReset(_ provider: CXProvider) {
        print("[CallKit] Provider reset")
        activeCallUUID = nil
        onEndCall?()
    }

    func provider(_ provider: CXProvider, perform action: CXStartCallAction) {
        print("[CallKit] Start call action")

        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .voiceChat, options: [.allowBluetoothA2DP])
            try session.setActive(true)
        } catch {
            print("[CallKit] Audio session error: \(error)")
        }

        action.fulfill()
    }

    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        print("[CallKit] Answer call action")

        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .voiceChat, options: [.allowBluetoothA2DP])
            try session.setActive(true)
        } catch {
            print("[CallKit] Audio session error: \(error)")
        }

        onAnswerCall?()
        action.fulfill()
    }

    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        print("[CallKit] End call action")
        onEndCall?()
        activeCallUUID = nil
        action.fulfill()
    }

    func provider(_ provider: CXProvider, perform action: CXSetMutedCallAction) {
        print("[CallKit] Mute action: \(action.isMuted)")
        CallManager.shared.isMuted = action.isMuted
        WebRTCService.shared.toggleAudio()
        action.fulfill()
    }

    func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {
        print("[CallKit] Audio session activated")
    }

    func provider(_ provider: CXProvider, didDeactivate audioSession: AVAudioSession) {
        print("[CallKit] Audio session deactivated")
    }
}
