import SwiftUI
import WebRTC

// MARK: - WebRTC Video View
struct RTCVideoView: UIViewRepresentable {
    let track: RTCVideoTrack?

    func makeUIView(context: Context) -> UIView {
        #if arch(arm64)
        let renderer = RTCMTLVideoView(frame: .zero)
        renderer.videoContentMode = .scaleAspectFill
        renderer.clipsToBounds = true
        return renderer
        #else
        let renderer = RTCEAGLVideoView(frame: .zero)
        renderer.clipsToBounds = true
        return renderer
        #endif
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        guard let renderer = uiView as? (UIView & RTCVideoRenderer) else { return }
        context.coordinator.currentTrack?.remove(renderer)
        if let track = track {
            track.add(renderer)
            context.coordinator.currentTrack = track
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator {
        var currentTrack: RTCVideoTrack?
    }
}

// MARK: - Active Call View

struct ActiveCallView: View {
    @ObservedObject var callManager = CallManager.shared
    @ObservedObject var webRTC = WebRTCService.shared
    @EnvironmentObject var localization: LocalizationManager
    @Environment(\.dismiss) var dismiss

    @State private var showControls = true

    var body: some View {
        ZStack {
            // Background
            if callManager.activeCall?.isVideo == true {
                // Remote video (full screen)
                if let remoteTrack = webRTC.remoteVideoTrack {
                    RTCVideoView(track: remoteTrack)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                showControls.toggle()
                            }
                        }
                } else {
                    Color.black.ignoresSafeArea()
                    VStack {
                        Spacer()
                        ProgressView()
                            .tint(.white)
                        Text(localization.localized("Подключение видео...", "Connecting video..."))
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.6))
                            .padding(.top, 8)
                        Spacer()
                    }
                }

                // Local video (PiP)
                if let localTrack = webRTC.localVideoTrack {
                    VStack {
                        HStack {
                            Spacer()
                            RTCVideoView(track: localTrack)
                                .frame(width: 120, height: 160)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                )
                                .shadow(radius: 5)
                                .padding(.trailing, 16)
                                .padding(.top, 60)
                                .onTapGesture {
                                    callManager.switchCamera()
                                }
                        }
                        Spacer()
                    }
                }
            } else {
                // Audio call background
                LinearGradient(
                    colors: [.blue.opacity(0.8), .purple.opacity(0.6), .black],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            }

            // Controls overlay
            if showControls || callManager.activeCall?.isVideo != true {
                VStack(spacing: 0) {
                    Spacer()

                    if let call = callManager.activeCall {
                        if !call.isVideo || webRTC.remoteVideoTrack == nil {
                            AvatarView(user: call.user, size: 100)
                                .padding(.bottom, 16)
                        }

                        Text(call.user.displayName)
                            .font(.title.bold())
                            .foregroundStyle(.white)
                            .shadow(radius: 3)

                        Text(statusText)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.7))
                            .padding(.top, 4)

                        if callManager.callState == .connected {
                            Text(callManager.formattedDuration)
                                .font(.system(size: 17, design: .monospaced))
                                .foregroundStyle(.white.opacity(0.8))
                                .padding(.top, 8)
                        }
                    }

                    Spacer()
                    Spacer()

                    // Controls
                    HStack(spacing: 32) {
                        CallButton(
                            icon: callManager.isMuted ? "mic.slash.fill" : "mic.fill",
                            label: callManager.isMuted
                                ? localization.localized("Вкл.", "Unmute")
                                : localization.localized("Микрофон", "Mic"),
                            isActive: callManager.isMuted
                        ) {
                            callManager.toggleMute()
                        }

                        if callManager.activeCall?.isVideo == true {
                            CallButton(
                                icon: callManager.isCameraOn ? "video.fill" : "video.slash.fill",
                                label: localization.localized("Камера", "Camera"),
                                isActive: !callManager.isCameraOn
                            ) {
                                callManager.toggleCamera()
                            }

                            CallButton(
                                icon: "arrow.triangle.2.circlepath.camera",
                                label: localization.localized("Флип", "Flip"),
                                isActive: false
                            ) {
                                callManager.switchCamera()
                            }
                        } else {
                            CallButton(
                                icon: callManager.isSpeakerOn ? "speaker.wave.3.fill" : "speaker.fill",
                                label: localization.localized("Динамик", "Speaker"),
                                isActive: callManager.isSpeakerOn
                            ) {
                                callManager.toggleSpeaker()
                            }
                        }
                    }
                    .padding(.bottom, 40)

                    Button {
                        callManager.endCall()
                        dismiss()
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 70, height: 70)
                            Image(systemName: "phone.down.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(.white)
                        }
                    }
                    .padding(.bottom, 50)
                }
            }
        }
    }

    private var statusText: String {
        switch callManager.callState {
        case .calling:
            return localization.localized("Вызов...", "Calling...")
        case .ringing:
            return localization.localized("Звонит...", "Ringing...")
        case .connected:
            return callManager.activeCall?.isVideo == true
                ? localization.localized("Видеозвонок", "Video call")
                : localization.localized("Аудиозвонок", "Voice call")
        case .ended:
            return localization.localized("Завершён", "Ended")
        case .idle:
            return ""
        }
    }
}

// MARK: - Call Button
struct CallButton: View {
    let icon: String
    let label: String
    var isActive: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(isActive ? .white : .white.opacity(0.2))
                        .frame(width: 56, height: 56)
                    Image(systemName: icon)
                        .font(.system(size: 22))
                        .foregroundStyle(isActive ? .black : .white)
                }
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
    }
}

// MARK: - Incoming Call View
struct IncomingCallView: View {
    @ObservedObject var callManager = CallManager.shared
    @EnvironmentObject var localization: LocalizationManager
    @Environment(\.dismiss) var dismiss

    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [.green.opacity(0.7), .blue.opacity(0.6), .black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                if let incoming = callManager.incomingCall {
                    ZStack {
                        Circle()
                            .fill(.white.opacity(0.1))
                            .frame(width: 140, height: 140)
                            .scaleEffect(pulseScale)

                        Circle()
                            .fill(.white.opacity(0.15))
                            .frame(width: 120, height: 120)

                        Image(systemName: "person.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(.white)
                    }
                    .padding(.bottom, 24)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                            pulseScale = 1.3
                        }
                    }

                    Text(incoming.callerName)
                        .font(.title.bold())
                        .foregroundStyle(.white)

                    Text(incoming.isVideo
                         ? localization.localized("Видеозвонок", "Video Call")
                         : localization.localized("Аудиозвонок", "Voice Call"))
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
                    .padding(.top, 4)
                }

                Spacer()
                Spacer()

                HStack(spacing: 60) {
                    Button {
                        callManager.declineCall()
                        dismiss()
                    } label: {
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 70, height: 70)
                                Image(systemName: "phone.down.fill")
                                    .font(.system(size: 28))
                                    .foregroundStyle(.white)
                            }
                            Text(localization.localized("Отклонить", "Decline"))
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.8))
                        }
                    }

                    Button {
                        callManager.answerCall()
                    } label: {
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 70, height: 70)
                                Image(systemName: "phone.fill")
                                    .font(.system(size: 28))
                                    .foregroundStyle(.white)
                                    .rotationEffect(.degrees(-135))
                            }
                            Text(localization.localized("Принять", "Accept"))
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.8))
                        }
                    }
                }
                .padding(.bottom, 60)
            }
        }
    }
}
