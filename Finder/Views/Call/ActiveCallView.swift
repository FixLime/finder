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
    @State private var wavePhase: CGFloat = 0
    @State private var appear = false

    var body: some View {
        ZStack {
            // Background
            if callManager.activeCall?.isVideo == true {
                videoBackground
            } else {
                audioBackground
            }

            // Controls overlay
            if showControls || callManager.activeCall?.isVideo != true {
                VStack(spacing: 0) {
                    // Top bar — encryption badge
                    HStack {
                        HStack(spacing: 6) {
                            Image(systemName: "lock.shield.fill")
                                .font(.system(size: 11))
                            Text(localization.localized("Зашифрован", "Encrypted"))
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundStyle(.white.opacity(0.6))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(.white.opacity(0.1)))

                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 60)

                    Spacer()

                    if let call = callManager.activeCall {
                        // Avatar (audio only or video connecting)
                        if !call.isVideo || webRTC.remoteVideoTrack == nil {
                            ZStack {
                                // Animated rings
                                ForEach(0..<3, id: \.self) { i in
                                    Circle()
                                        .stroke(.white.opacity(0.1), lineWidth: 1.5)
                                        .frame(
                                            width: CGFloat(130 + i * 25),
                                            height: CGFloat(130 + i * 25)
                                        )
                                        .scaleEffect(callManager.callState == .connected ? 1.0 :
                                            (wavePhase > 0 ? 1.1 : 0.95))
                                        .opacity(callManager.callState == .connected ? 0.3 : 0.6)
                                        .animation(
                                            .easeInOut(duration: 1.5)
                                            .repeatForever(autoreverses: true)
                                            .delay(Double(i) * 0.3),
                                            value: wavePhase
                                        )
                                }

                                AvatarView(user: call.user, size: 110)
                                    .shadow(color: .black.opacity(0.3), radius: 15)
                            }
                            .padding(.bottom, 20)
                        }

                        // Name
                        HStack(spacing: 6) {
                            Text(call.user.displayName)
                                .font(.system(size: 28, weight: .bold))
                                .foregroundStyle(.white)
                                .shadow(color: .black.opacity(0.3), radius: 3)

                            if call.user.isVerified {
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.system(size: 16))
                                    .foregroundStyle(.blue)
                            }
                        }

                        // Status
                        HStack(spacing: 6) {
                            if callManager.callState == .calling || callManager.callState == .ringing {
                                ProgressView()
                                    .tint(.white.opacity(0.7))
                                    .scaleEffect(0.7)
                            }
                            Text(statusText)
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.7))
                        }
                        .padding(.top, 4)

                        // Duration
                        if callManager.callState == .connected {
                            Text(callManager.formattedDuration)
                                .font(.system(size: 18, weight: .medium, design: .monospaced))
                                .foregroundStyle(.white.opacity(0.9))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 6)
                                .background(Capsule().fill(.white.opacity(0.1)))
                                .padding(.top, 10)
                        }
                    }

                    Spacer()
                    Spacer()

                    // Control buttons
                    controlButtons
                        .padding(.bottom, 30)

                    // End call
                    Button {
                        callManager.endCall()
                        dismiss()
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 72, height: 72)
                                .shadow(color: .red.opacity(0.4), radius: 10, y: 5)

                            Image(systemName: "phone.down.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(.white)
                        }
                    }
                    .padding(.bottom, 50)
                }
                .opacity(appear ? 1 : 0)
            }
        }
        .onAppear {
            wavePhase = 1
            withAnimation(.easeOut(duration: 0.5)) {
                appear = true
            }
        }
    }

    // MARK: - Video Background
    private var videoBackground: some View {
        ZStack {
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

            // Local video PiP
            if let localTrack = webRTC.localVideoTrack {
                VStack {
                    HStack {
                        Spacer()
                        RTCVideoView(track: localTrack)
                            .frame(width: 120, height: 170)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(.white.opacity(0.2), lineWidth: 1)
                            )
                            .shadow(color: .black.opacity(0.5), radius: 10)
                            .padding(.trailing, 16)
                            .padding(.top, 60)
                            .onTapGesture {
                                callManager.switchCamera()
                            }
                    }
                    Spacer()
                }
            }
        }
    }

    // MARK: - Audio Background
    private var audioBackground: some View {
        ZStack {
            // Mesh gradient-like background
            LinearGradient(
                colors: [
                    Color(red: 0.1, green: 0.1, blue: 0.3),
                    Color(red: 0.15, green: 0.05, blue: 0.25),
                    Color(red: 0.05, green: 0.05, blue: 0.15)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Animated blurred circles
            Circle()
                .fill(Color.blue.opacity(0.15))
                .frame(width: 300, height: 300)
                .blur(radius: 80)
                .offset(x: -50, y: -200)

            Circle()
                .fill(Color.purple.opacity(0.15))
                .frame(width: 250, height: 250)
                .blur(radius: 60)
                .offset(x: 100, y: 200)

            Circle()
                .fill(Color.cyan.opacity(0.1))
                .frame(width: 200, height: 200)
                .blur(radius: 70)
                .offset(x: -80, y: 100)
        }
    }

    // MARK: - Control Buttons
    private var controlButtons: some View {
        HStack(spacing: 24) {
            // Mute
            CallControlButton(
                icon: callManager.isMuted ? "mic.slash.fill" : "mic.fill",
                label: callManager.isMuted
                    ? localization.localized("Вкл.", "Unmute")
                    : localization.localized("Микрофон", "Mic"),
                isActive: callManager.isMuted
            ) {
                callManager.toggleMute()
            }

            if callManager.activeCall?.isVideo == true {
                // Camera toggle
                CallControlButton(
                    icon: callManager.isCameraOn ? "video.fill" : "video.slash.fill",
                    label: localization.localized("Камера", "Camera"),
                    isActive: !callManager.isCameraOn
                ) {
                    callManager.toggleCamera()
                }

                // Flip camera
                CallControlButton(
                    icon: "arrow.triangle.2.circlepath.camera",
                    label: localization.localized("Флип", "Flip"),
                    isActive: false
                ) {
                    callManager.switchCamera()
                }
            } else {
                // Speaker
                CallControlButton(
                    icon: callManager.isSpeakerOn ? "speaker.wave.3.fill" : "speaker.fill",
                    label: localization.localized("Динамик", "Speaker"),
                    isActive: callManager.isSpeakerOn
                ) {
                    callManager.toggleSpeaker()
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

// MARK: - Call Control Button
struct CallControlButton: View {
    let icon: String
    let label: String
    var isActive: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            action()
        }) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(isActive ? .white : .white.opacity(0.15))
                        .frame(width: 60, height: 60)
                        .overlay(
                            Circle()
                                .stroke(.white.opacity(0.2), lineWidth: 1)
                        )

                    Image(systemName: icon)
                        .font(.system(size: 22))
                        .foregroundStyle(isActive ? .black : .white)
                }

                Text(label)
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.7))
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
    @State private var ringPhase: CGFloat = 0
    @State private var appear = false

    var body: some View {
        ZStack {
            // Background
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.05, green: 0.15, blue: 0.1),
                        Color(red: 0.1, green: 0.1, blue: 0.2),
                        Color(red: 0.05, green: 0.05, blue: 0.1)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                Circle()
                    .fill(Color.green.opacity(0.1))
                    .frame(width: 400, height: 400)
                    .blur(radius: 100)
                    .offset(y: -100)
                    .scaleEffect(pulseScale * 0.8)
            }

            VStack(spacing: 0) {
                // Top bar
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 11))
                        Text(localization.localized("Зашифрованный звонок", "Encrypted call"))
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundStyle(.white.opacity(0.5))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(.white.opacity(0.08)))

                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                .opacity(appear ? 1 : 0)

                Spacer()

                if let incoming = callManager.incomingCall {
                    // Animated avatar
                    ZStack {
                        // Ring waves
                        ForEach(0..<4, id: \.self) { i in
                            Circle()
                                .stroke(.white.opacity(0.05), lineWidth: 1.5)
                                .frame(
                                    width: CGFloat(140 + i * 30),
                                    height: CGFloat(140 + i * 30)
                                )
                                .scaleEffect(pulseScale)
                                .opacity(2.0 - pulseScale)
                                .animation(
                                    .easeInOut(duration: 1.5)
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(i) * 0.2),
                                    value: pulseScale
                                )
                        }

                        // Glow ring
                        Circle()
                            .stroke(
                                AngularGradient(
                                    gradient: Gradient(colors: [.green.opacity(0.5), .cyan.opacity(0.3), .green.opacity(0.5)]),
                                    center: .center
                                ),
                                lineWidth: 3
                            )
                            .frame(width: 130, height: 130)
                            .rotationEffect(.degrees(ringPhase))

                        Circle()
                            .fill(.white.opacity(0.1))
                            .frame(width: 120, height: 120)

                        Image(systemName: "person.fill")
                            .font(.system(size: 46))
                            .foregroundStyle(.white)
                    }
                    .padding(.bottom, 28)
                    .scaleEffect(appear ? 1 : 0.7)
                    .opacity(appear ? 1 : 0)

                    // Name
                    HStack(spacing: 6) {
                        Text(incoming.callerName)
                            .font(.system(size: 30, weight: .bold))
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.3), radius: 3)
                    }
                    .opacity(appear ? 1 : 0)

                    // Call type
                    HStack(spacing: 6) {
                        Image(systemName: incoming.isVideo ? "video.fill" : "phone.fill")
                            .font(.system(size: 13))
                        Text(incoming.isVideo
                             ? localization.localized("Входящий видеозвонок", "Incoming Video Call")
                             : localization.localized("Входящий аудиозвонок", "Incoming Voice Call"))
                        .font(.subheadline)
                    }
                    .foregroundStyle(.white.opacity(0.6))
                    .padding(.top, 6)
                    .opacity(appear ? 1 : 0)
                }

                Spacer()
                Spacer()

                // Answer/Decline buttons
                HStack(spacing: 70) {
                    // Decline
                    Button {
                        callManager.declineCall()
                        dismiss()
                    } label: {
                        VStack(spacing: 10) {
                            ZStack {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 72, height: 72)
                                    .shadow(color: .red.opacity(0.4), radius: 10, y: 5)

                                Image(systemName: "phone.down.fill")
                                    .font(.system(size: 28))
                                    .foregroundStyle(.white)
                            }
                            Text(localization.localized("Отклонить", "Decline"))
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.white.opacity(0.7))
                        }
                    }

                    // Accept
                    Button {
                        callManager.answerCall()
                    } label: {
                        VStack(spacing: 10) {
                            ZStack {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 72, height: 72)
                                    .shadow(color: .green.opacity(0.4), radius: 10, y: 5)

                                Image(systemName: "phone.fill")
                                    .font(.system(size: 28))
                                    .foregroundStyle(.white)
                                    .rotationEffect(.degrees(-135))
                            }
                            Text(localization.localized("Принять", "Accept"))
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.white.opacity(0.7))
                        }
                    }
                }
                .opacity(appear ? 1 : 0)
                .offset(y: appear ? 0 : 30)
                .padding(.bottom, 60)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                pulseScale = 1.25
            }
            withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                ringPhase = 360
            }
            withAnimation(.spring(response: 0.6).delay(0.1)) {
                appear = true
            }
        }
    }
}
