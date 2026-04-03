import Foundation
import WebRTC
import Combine

class WebRTCService: NSObject, ObservableObject {
    static let shared = WebRTCService()

    @Published var localVideoTrack: RTCVideoTrack?
    @Published var remoteVideoTrack: RTCVideoTrack?
    @Published var isAudioEnabled = true
    @Published var isVideoEnabled = true

    private var peerConnection: RTCPeerConnection?
    private var peerConnectionFactory: RTCPeerConnectionFactory!
    private var localAudioTrack: RTCAudioTrack?
    private var videoCapturer: RTCCameraVideoCapturer?
    private var videoSource: RTCVideoSource?

    private var cancellables = Set<AnyCancellable>()
    private let ws = WebSocketService.shared

    private var currentCallId: String?
    private var remoteUserId: String?

    private override init() {
        super.init()
        setupFactory()
        setupSignalingListeners()
    }

    // MARK: - Setup

    private func setupFactory() {
        let encoderFactory = RTCDefaultVideoEncoderFactory()
        let decoderFactory = RTCDefaultVideoDecoderFactory()
        peerConnectionFactory = RTCPeerConnectionFactory(
            encoderFactory: encoderFactory,
            decoderFactory: decoderFactory
        )
    }

    private func setupSignalingListeners() {
        ws.webrtcSignal
            .receive(on: DispatchQueue.main)
            .sink { [weak self] signal in
                guard let self = self else { return }
                switch signal {
                case .webrtcOffer(let callId, let sdp, let from):
                    self.handleOffer(callId: callId, sdp: sdp, from: from)
                case .webrtcAnswer(_, let sdp, _):
                    self.handleAnswer(sdp: sdp)
                case .webrtcIceCandidate(_, let candidate, _):
                    self.handleIceCandidate(candidate)
                default:
                    break
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Create Peer Connection

    private func createPeerConnection() -> RTCPeerConnection? {
        let config = RTCConfiguration()
        config.iceServers = [
            RTCIceServer(urlStrings: ["stun:stun.l.google.com:19302"]),
            RTCIceServer(urlStrings: ["stun:stun1.l.google.com:19302"]),
            RTCIceServer(urlStrings: ["stun:stun2.l.google.com:19302"])
        ]
        config.sdpSemantics = .unifiedPlan
        config.continualGatheringPolicy = .gatherContinually

        let constraints = RTCMediaConstraints(
            mandatoryConstraints: nil,
            optionalConstraints: ["DtlsSrtpKeyAgreement": kRTCMediaConstraintsValueTrue]
        )

        let pc = peerConnectionFactory.peerConnection(
            with: config,
            constraints: constraints,
            delegate: self
        )

        return pc
    }

    // MARK: - Start Call (Outgoing)

    func startCall(callId: String, remoteUserId: String, isVideo: Bool) {
        self.currentCallId = callId
        self.remoteUserId = remoteUserId

        peerConnection = createPeerConnection()
        guard let pc = peerConnection else { return }

        // Add audio track
        let audioConstraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
        let audioSource = peerConnectionFactory.audioSource(with: audioConstraints)
        let audioTrack = peerConnectionFactory.audioTrack(with: audioSource, trackId: "audio0")
        localAudioTrack = audioTrack
        pc.add(audioTrack, streamIds: ["stream0"])

        // Add video track if video call
        if isVideo {
            videoSource = peerConnectionFactory.videoSource()
            let capturer = RTCCameraVideoCapturer(delegate: videoSource!)
            videoCapturer = capturer

            let videoTrack = peerConnectionFactory.videoTrack(with: videoSource!, trackId: "video0")
            DispatchQueue.main.async {
                self.localVideoTrack = videoTrack
            }
            pc.add(videoTrack, streamIds: ["stream0"])

            startCapture()
        }

        // Create offer
        let offerConstraints = RTCMediaConstraints(
            mandatoryConstraints: [
                kRTCMediaConstraintsOfferToReceiveAudio: kRTCMediaConstraintsValueTrue,
                kRTCMediaConstraintsOfferToReceiveVideo: isVideo ? kRTCMediaConstraintsValueTrue : kRTCMediaConstraintsValueFalse
            ],
            optionalConstraints: nil
        )

        pc.offer(for: offerConstraints) { [weak self] sdp, error in
            guard let self = self, let sdp = sdp, error == nil else {
                print("[WebRTC] Failed to create offer: \(error?.localizedDescription ?? "")")
                return
            }
            pc.setLocalDescription(sdp) { error in
                if let error = error {
                    print("[WebRTC] Set local description error: \(error.localizedDescription)")
                    return
                }
                self.ws.sendWebRTCOffer(
                    callId: callId,
                    sdp: sdp.sdp,
                    to: remoteUserId
                )
            }
        }
    }

    // MARK: - Answer Call (Incoming)

    func answerCall(callId: String, remoteUserId: String, isVideo: Bool) {
        self.currentCallId = callId
        self.remoteUserId = remoteUserId

        guard peerConnection != nil else { return }

        // Add local tracks
        let audioConstraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
        let audioSource = peerConnectionFactory.audioSource(with: audioConstraints)
        let audioTrack = peerConnectionFactory.audioTrack(with: audioSource, trackId: "audio0")
        localAudioTrack = audioTrack
        peerConnection?.add(audioTrack, streamIds: ["stream0"])

        if isVideo {
            videoSource = peerConnectionFactory.videoSource()
            let capturer = RTCCameraVideoCapturer(delegate: videoSource!)
            videoCapturer = capturer

            let videoTrack = peerConnectionFactory.videoTrack(with: videoSource!, trackId: "video0")
            DispatchQueue.main.async {
                self.localVideoTrack = videoTrack
            }
            peerConnection?.add(videoTrack, streamIds: ["stream0"])

            startCapture()
        }

        // Create answer
        let answerConstraints = RTCMediaConstraints(
            mandatoryConstraints: [
                kRTCMediaConstraintsOfferToReceiveAudio: kRTCMediaConstraintsValueTrue,
                kRTCMediaConstraintsOfferToReceiveVideo: isVideo ? kRTCMediaConstraintsValueTrue : kRTCMediaConstraintsValueFalse
            ],
            optionalConstraints: nil
        )

        peerConnection?.answer(for: answerConstraints) { [weak self] sdp, error in
            guard let self = self, let sdp = sdp, error == nil else { return }
            self.peerConnection?.setLocalDescription(sdp) { error in
                if let error = error {
                    print("[WebRTC] Set local description error: \(error)")
                    return
                }
                self.ws.sendWebRTCAnswer(
                    callId: callId,
                    sdp: sdp.sdp,
                    to: remoteUserId
                )
            }
        }
    }

    // MARK: - Handle Signaling

    private func handleOffer(callId: String, sdp: String, from: String) {
        self.currentCallId = callId
        self.remoteUserId = from

        if peerConnection == nil {
            peerConnection = createPeerConnection()
        }

        let remoteSDP = RTCSessionDescription(type: .offer, sdp: sdp)
        peerConnection?.setRemoteDescription(remoteSDP) { error in
            if let error = error {
                print("[WebRTC] Set remote description error: \(error)")
            } else {
                print("[WebRTC] Remote offer set successfully")
            }
        }
    }

    private func handleAnswer(sdp: String) {
        let remoteSDP = RTCSessionDescription(type: .answer, sdp: sdp)
        peerConnection?.setRemoteDescription(remoteSDP) { error in
            if let error = error {
                print("[WebRTC] Set remote answer error: \(error)")
            } else {
                print("[WebRTC] Remote answer set successfully")
            }
        }
    }

    private func handleIceCandidate(_ candidateString: String) {
        guard let data = candidateString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let sdp = json["candidate"] as? String,
              let sdpMLineIndex = json["sdpMLineIndex"] as? Int32,
              let sdpMid = json["sdpMid"] as? String else { return }

        let candidate = RTCIceCandidate(sdp: sdp, sdpMLineIndex: sdpMLineIndex, sdpMid: sdpMid)
        peerConnection?.add(candidate) { error in
            if let error = error {
                print("[WebRTC] Add ICE candidate error: \(error)")
            }
        }
    }

    // MARK: - Camera

    private func startCapture() {
        guard let capturer = videoCapturer else { return }

        let devices = RTCCameraVideoCapturer.captureDevices()
        guard let frontCamera = devices.first(where: { $0.position == .front }) ?? devices.first else {
            print("[WebRTC] No camera found")
            return
        }

        let formats = RTCCameraVideoCapturer.supportedFormats(for: frontCamera)
        let targetWidth: Int32 = 640
        let targetHeight: Int32 = 480

        let format = formats.sorted { f1, f2 in
            let dim1 = CMVideoFormatDescriptionGetDimensions(f1.formatDescription)
            let dim2 = CMVideoFormatDescriptionGetDimensions(f2.formatDescription)
            let diff1 = abs(dim1.width - targetWidth) + abs(dim1.height - targetHeight)
            let diff2 = abs(dim2.width - targetWidth) + abs(dim2.height - targetHeight)
            return diff1 < diff2
        }.first ?? formats.first!

        let fps = format.videoSupportedFrameRateRanges
            .max(by: { $0.maxFrameRate < $1.maxFrameRate })?.maxFrameRate ?? 30

        capturer.startCapture(with: frontCamera, format: format, fps: Int(min(fps, 30)))
    }

    func switchCamera() {
        guard let capturer = videoCapturer else { return }
        capturer.stopCapture()

        let devices = RTCCameraVideoCapturer.captureDevices()
        guard devices.count > 1 else { return }

        let currentPosition: AVCaptureDevice.Position = .front
        let newPosition: AVCaptureDevice.Position = currentPosition == .front ? .back : .front

        guard let newCamera = devices.first(where: { $0.position == newPosition }) else { return }

        let formats = RTCCameraVideoCapturer.supportedFormats(for: newCamera)
        guard let format = formats.first else { return }

        let fps = format.videoSupportedFrameRateRanges
            .max(by: { $0.maxFrameRate < $1.maxFrameRate })?.maxFrameRate ?? 30

        capturer.startCapture(with: newCamera, format: format, fps: Int(min(fps, 30)))
    }

    // MARK: - Controls

    func toggleAudio() {
        isAudioEnabled.toggle()
        localAudioTrack?.isEnabled = isAudioEnabled
    }

    func toggleVideo() {
        isVideoEnabled.toggle()
        localVideoTrack?.isEnabled = isVideoEnabled
        if !isVideoEnabled {
            videoCapturer?.stopCapture()
        } else {
            startCapture()
        }
    }

    // MARK: - End Call

    func endCall() {
        videoCapturer?.stopCapture()
        peerConnection?.close()
        peerConnection = nil

        DispatchQueue.main.async {
            self.localVideoTrack = nil
            self.remoteVideoTrack = nil
            self.isAudioEnabled = true
            self.isVideoEnabled = true
        }

        localAudioTrack = nil
        videoCapturer = nil
        videoSource = nil
        currentCallId = nil
        remoteUserId = nil
    }
}

// MARK: - RTCPeerConnectionDelegate

extension WebRTCService: RTCPeerConnectionDelegate {
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {
        print("[WebRTC] Signaling state: \(stateChanged.rawValue)")
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
        print("[WebRTC] Remote stream added")
        if let videoTrack = stream.videoTracks.first {
            DispatchQueue.main.async {
                self.remoteVideoTrack = videoTrack
            }
        }
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {
        print("[WebRTC] Remote stream removed")
    }

    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {
        print("[WebRTC] Should negotiate")
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
        print("[WebRTC] ICE connection state: \(newState.rawValue)")
        DispatchQueue.main.async {
            switch newState {
            case .connected, .completed:
                CallManager.shared.callState = .connected
            case .failed, .disconnected:
                print("[WebRTC] Connection lost")
            case .closed:
                CallManager.shared.endCall()
            default:
                break
            }
        }
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {
        print("[WebRTC] ICE gathering state: \(newState.rawValue)")
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        guard let callId = currentCallId, let remote = remoteUserId else { return }

        let candidateDict: [String: Any] = [
            "candidate": candidate.sdp,
            "sdpMLineIndex": candidate.sdpMLineIndex,
            "sdpMid": candidate.sdpMid ?? ""
        ]

        if let data = try? JSONSerialization.data(withJSONObject: candidateDict),
           let str = String(data: data, encoding: .utf8) {
            ws.sendICECandidate(callId: callId, candidate: str, to: remote)
        }
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {}

    func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {}
}
