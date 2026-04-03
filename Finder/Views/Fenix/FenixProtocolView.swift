import SwiftUI

struct FenixProtocolView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var chatService: ChatService
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var localization: LocalizationManager
    @Environment(\.dismiss) var dismiss

    @State private var step: FenixStep = .warning
    @State private var confirmText = ""
    @State private var progress: Double = 0
    @State private var isDeleting = false
    @State private var showParticles = false
    @State private var deleteComplete = false
    @State private var appear = false
    @State private var flameScale: CGFloat = 1
    @State private var flameRotation: Double = 0
    @State private var currentDeleteStep = 0
    @State private var deleteStepText = ""
    @State private var deleteStepIcon = ""
    @State private var contentDissolve = false
    @State private var burnEdgeProgress: Double = 0
    @State private var hapticTimer: Timer?
    @State private var completedSteps: Set<Int> = []
    @State private var warningPulse = false
    @State private var glitchOffset: CGFloat = 0
    @State private var deletionGlow: Double = 0

    @StateObject private var particleSystem = ParticleSystem()

    private let deleteSteps: [(String, String, String, String)] = [
        ("trash.fill", "messages", "Уничтожение сообщений...", "Destroying messages..."),
        ("person.2.slash", "contacts", "Стирание контактов...", "Erasing contacts..."),
        ("photo.fill", "media", "Удаление медиафайлов...", "Deleting media files..."),
        ("key.fill", "keys", "Уничтожение ключей шифрования...", "Destroying encryption keys..."),
        ("person.crop.circle.badge.xmark", "profile", "Удаление профиля...", "Deleting profile..."),
        ("server.rack", "server", "Очистка серверов...", "Clearing servers..."),
        ("eye.slash.fill", "traces", "Уничтожение цифровых следов...", "Destroying digital traces..."),
        ("flame.fill", "final", "Финальная зачистка...", "Final cleanup..."),
        ("checkmark.shield.fill", "verify", "Верификация удаления...", "Verifying deletion...")
    ]

    enum FenixStep {
        case warning, confirm, deleting, complete
    }

    var body: some View {
        ZStack {
            // Dynamic background
            backgroundView

            // Particle overlay
            if showParticles {
                ParticleEffectView(system: particleSystem)
                    .ignoresSafeArea()
                    .zIndex(100)
            }

            // Burn edge effect during deletion
            if step == .deleting {
                BurnEdgeView(progress: burnEdgeProgress)
                    .ignoresSafeArea()
                    .zIndex(50)
            }

            // Content
            Group {
                switch step {
                case .warning:  warningView
                case .confirm:  confirmView
                case .deleting: deletingView
                case .complete: completeView
                }
            }
            .offset(x: glitchOffset, y: particleSystem.screenShake)
        }
        .statusBarHidden(step == .deleting || step == .complete)
        .onAppear {
            withAnimation(.spring(response: 0.6).delay(0.2)) {
                appear = true
            }
        }
        .onDisappear {
            hapticTimer?.invalidate()
        }
    }

    // MARK: - Background
    private var backgroundView: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            if step == .deleting || step == .complete {
                // Dark overlay during deletion
                Color.black.opacity(step == .deleting ? 0.4 : 0.8)
                    .ignoresSafeArea()
                    .transition(.opacity)
            }

            // Red glow during deletion
            if deletionGlow > 0 {
                RadialGradient(
                    colors: [
                        Color.red.opacity(deletionGlow * 0.3),
                        Color.orange.opacity(deletionGlow * 0.15),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: 500
                )
                .ignoresSafeArea()
            }
        }
    }

    // MARK: - Warning View
    private var warningView: some View {
        VStack(spacing: 24) {
            Spacer()

            // Animated flame with rings
            ZStack {
                // Outer glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.red.opacity(0.2), Color.orange.opacity(0.05), Color.clear],
                            center: .center, startRadius: 0, endRadius: 120
                        )
                    )
                    .frame(width: 240, height: 240)
                    .scaleEffect(flameScale)

                // Pulse rings
                ForEach(0..<4, id: \.self) { i in
                    PulseRing(color: .red.opacity(0.4 - Double(i) * 0.08))
                        .frame(width: CGFloat(90 + i * 35), height: CGFloat(90 + i * 35))
                }

                // Flame circle background
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.red.opacity(0.25), Color.orange.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 110, height: 110)
                    .blur(radius: 5)

                Image(systemName: "flame.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.red, .orange, .yellow],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .scaleEffect(flameScale)
                    .shadow(color: .red.opacity(0.5), radius: 20)
                    .shadow(color: .orange.opacity(0.3), radius: 40)
            }
            .scaleEffect(appear ? 1 : 0.3)
            .opacity(appear ? 1 : 0)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                    flameScale = 1.12
                }
            }

            Text(localization.fenixProtocol)
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.red, .orange],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .offset(y: appear ? 0 : 30)
                .opacity(appear ? 1 : 0)

            Text(localization.localized(
                "Полное и необратимое уничтожение всех данных",
                "Complete and irreversible destruction of all data"
            ))
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 40)
            .opacity(appear ? 1 : 0)

            // Warning items with staggered animation
            VStack(spacing: 10) {
                ForEach(Array(warningItems.enumerated()), id: \.offset) { index, item in
                    warningItemView(icon: item.0, text: item.1)
                        .opacity(appear ? 1 : 0)
                        .offset(x: appear ? 0 : -30)
                        .animation(.spring(response: 0.4).delay(Double(index) * 0.08 + 0.3), value: appear)
                }
            }
            .padding(.horizontal, 28)

            Spacer()

            VStack(spacing: 14) {
                Button {
                    triggerHaptic(.warning)
                    withAnimation(.spring(response: 0.4)) {
                        appear = false
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation(.spring(response: 0.5)) {
                            step = .confirm
                            appear = true
                        }
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 16))
                        Text(localization.localized("Активировать протокол", "Activate Protocol"))
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [.red, Color(red: 0.9, green: 0.3, blue: 0)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .shadow(color: .red.opacity(0.4), radius: 15, y: 5)
                    )
                }

                Button { dismiss() } label: {
                    Text(localization.cancel)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 8)
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 50)
        }
    }

    private var warningItems: [(String, String)] {
        [
            ("envelope.fill", localization.localized("Все сообщения будут уничтожены", "All messages will be destroyed")),
            ("person.2.fill", localization.localized("Все контакты будут стёрты", "All contacts will be erased")),
            ("key.fill", localization.localized("Ключи шифрования уничтожены", "Encryption keys destroyed")),
            ("person.crop.circle.badge.xmark", localization.localized("Профиль полностью удалён", "Profile completely deleted")),
            ("server.rack", localization.localized("Данные удалены с серверов", "Data deleted from servers")),
            ("exclamationmark.octagon.fill", localization.localized("Это действие НЕОБРАТИМО", "This action is IRREVERSIBLE"))
        ]
    }

    private func warningItemView(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.12))
                    .frame(width: 30, height: 30)
                Image(systemName: icon)
                    .font(.system(size: 13))
                    .foregroundStyle(.red)
            }
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.primary)
            Spacer()
        }
    }

    // MARK: - Confirm View
    private var confirmView: some View {
        VStack(spacing: 28) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.1))
                    .frame(width: 100, height: 100)
                    .scaleEffect(warningPulse ? 1.2 : 1.0)

                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.red, .orange],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    .shadow(color: .red.opacity(0.3), radius: 10)
            }
            .scaleEffect(appear ? 1 : 0.3)
            .opacity(appear ? 1 : 0)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                    warningPulse = true
                }
            }

            VStack(spacing: 8) {
                Text(localization.localized("Последнее предупреждение", "Final Warning"))
                    .font(.title2.bold())
                    .foregroundStyle(.red)

                Text(localization.localized(
                    "Введите FENIX для подтверждения уничтожения",
                    "Type FENIX to confirm destruction"
                ))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            }
            .offset(y: appear ? 0 : 20)
            .opacity(appear ? 1 : 0)

            // Input field
            VStack(spacing: 8) {
                TextField("FENIX", text: $confirmText)
                    .textInputAutocapitalization(.characters)
                    .multilineTextAlignment(.center)
                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                    .tracking(8)
                    .padding(.vertical, 16)
                    .padding(.horizontal, 24)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(
                                        confirmText.uppercased() == "FENIX"
                                        ? Color.red.opacity(0.6)
                                        : Color.white.opacity(0.2),
                                        lineWidth: 1
                                    )
                            )
                    )
                    .padding(.horizontal, 40)

                if confirmText.uppercased() == "FENIX" {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.red)
                        Text(localization.localized("Код подтверждён", "Code confirmed"))
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                    .transition(.opacity.combined(with: .scale))
                }
            }

            Spacer()

            VStack(spacing: 14) {
                Button {
                    if confirmText.uppercased() == "FENIX" {
                        triggerHaptic(.error)
                        startDeletion()
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "flame.fill")
                        Text(localization.localized("Уничтожить всё", "Destroy Everything"))
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        Capsule()
                            .fill(confirmText.uppercased() == "FENIX"
                                  ? LinearGradient(colors: [.red, Color(red: 0.8, green: 0, blue: 0)], startPoint: .leading, endPoint: .trailing)
                                  : LinearGradient(colors: [.gray, .gray], startPoint: .leading, endPoint: .trailing)
                            )
                            .shadow(color: confirmText.uppercased() == "FENIX" ? .red.opacity(0.4) : .clear, radius: 15, y: 5)
                    )
                }
                .disabled(confirmText.uppercased() != "FENIX")

                Button { dismiss() } label: {
                    Text(localization.cancel)
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 8)
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 50)
        }
    }

    // MARK: - Deleting View
    private var deletingView: some View {
        VStack(spacing: 20) {
            Spacer()

            ZStack {
                // Outer rotating ring
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        AngularGradient(
                            colors: [.red, .orange, .yellow, .orange, .red],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 5, lineCap: .round)
                    )
                    .frame(width: 140, height: 140)
                    .rotationEffect(.degrees(-90 + flameRotation))

                // Inner ring
                Circle()
                    .trim(from: 0.1, to: progress * 0.8)
                    .stroke(
                        Color.red.opacity(0.3),
                        style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [4, 4])
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(90 - flameRotation * 0.5))

                // Background circle
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.red.opacity(0.2), Color.orange.opacity(0.05), Color.clear],
                            center: .center, startRadius: 0, endRadius: 60
                        )
                    )
                    .frame(width: 110, height: 110)

                // Flame icon
                Image(systemName: "flame.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.red, .orange, .yellow],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .scaleEffect(flameScale)
                    .shadow(color: .red.opacity(0.6), radius: 15)
                    .shadow(color: .orange.opacity(0.3), radius: 30)
            }

            Text(localization.fenixProtocol)
                .font(.title2.bold())
                .foregroundStyle(
                    LinearGradient(colors: [.red, .orange], startPoint: .leading, endPoint: .trailing)
                )

            // Current step
            HStack(spacing: 8) {
                if !deleteStepIcon.isEmpty {
                    Image(systemName: deleteStepIcon)
                        .font(.system(size: 14))
                        .foregroundStyle(.orange)
                        .transition(.scale.combined(with: .opacity))
                }
                Text(deleteStepText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .animation(.spring(response: 0.3), value: deleteStepText)

            // Progress
            Text("\(Int(progress * 100))%")
                .font(.system(size: 48, weight: .heavy, design: .monospaced))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.red, .orange],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .contentTransition(.numericText())

            // Step indicators
            VStack(spacing: 6) {
                ForEach(Array(deleteSteps.enumerated()), id: \.offset) { index, step in
                    HStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(completedSteps.contains(index)
                                      ? Color.red.opacity(0.2)
                                      : (currentDeleteStep == index ? Color.orange.opacity(0.15) : Color.gray.opacity(0.1))
                                )
                                .frame(width: 26, height: 26)

                            if completedSteps.contains(index) {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(.red)
                            } else if currentDeleteStep == index {
                                ProgressView()
                                    .scaleEffect(0.6)
                                    .tint(.orange)
                            } else {
                                Image(systemName: step.0)
                                    .font(.system(size: 10))
                                    .foregroundStyle(.gray)
                            }
                        }

                        Text(localization.isRussian ? step.2 : step.3)
                            .font(.system(size: 12))
                            .foregroundStyle(
                                completedSteps.contains(index) ? .red :
                                    (currentDeleteStep == index ? .primary : .secondary)
                            )
                            .strikethrough(completedSteps.contains(index))

                        Spacer()
                    }
                    .padding(.horizontal, 40)
                    .opacity(completedSteps.contains(index) || currentDeleteStep >= index ? 1 : 0.4)
                }
            }
            .padding(.top, 8)

            Spacer()
        }
        .heatDistortion(intensity: progress)
    }

    // MARK: - Complete View
    private var completeView: some View {
        VStack(spacing: 28) {
            Spacer()

            ZStack {
                // Success glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.green.opacity(0.2), Color.clear],
                            center: .center, startRadius: 0, endRadius: 100
                        )
                    )
                    .frame(width: 200, height: 200)
                    .scaleEffect(appear ? 1 : 0)

                ForEach(0..<3, id: \.self) { i in
                    PulseRing(color: .green.opacity(0.3))
                        .frame(width: CGFloat(80 + i * 30), height: CGFloat(80 + i * 30))
                }

                Circle()
                    .fill(Color.green.opacity(0.1))
                    .frame(width: 90, height: 90)

                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.green, Color(red: 0, green: 0.8, blue: 0.4)],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    .shadow(color: .green.opacity(0.4), radius: 15)
            }
            .scaleEffect(appear ? 1 : 0.3)
            .opacity(appear ? 1 : 0)

            VStack(spacing: 10) {
                Text(localization.localized("Протокол завершён", "Protocol Complete"))
                    .font(.system(size: 26, weight: .bold, design: .rounded))

                Text(localization.localized(
                    "Все данные безвозвратно уничтожены.\nВаш цифровой след полностью стёрт.",
                    "All data permanently destroyed.\nYour digital footprint has been completely erased."
                ))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            }
            .opacity(appear ? 1 : 0)
            .offset(y: appear ? 0 : 20)

            // Stats
            VStack(spacing: 8) {
                completionStat(icon: "envelope.fill", text: localization.localized("Сообщения уничтожены", "Messages destroyed"))
                completionStat(icon: "key.fill", text: localization.localized("Ключи удалены", "Keys deleted"))
                completionStat(icon: "server.rack", text: localization.localized("Серверы очищены", "Servers cleared"))
                completionStat(icon: "eye.slash.fill", text: localization.localized("Следы стёрты", "Traces erased"))
            }
            .padding(16)
            .liquidGlassCard(cornerRadius: 16)
            .padding(.horizontal, 32)
            .opacity(appear ? 1 : 0)
            .animation(.spring(response: 0.5).delay(0.3), value: appear)

            Spacer()

            Button {
                dismiss()
            } label: {
                Text("OK")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [.green, Color(red: 0, green: 0.7, blue: 0.3)],
                                    startPoint: .leading, endPoint: .trailing
                                )
                            )
                            .shadow(color: .green.opacity(0.3), radius: 10, y: 5)
                    )
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 50)
            .opacity(appear ? 1 : 0)
            .animation(.spring(response: 0.5).delay(0.5), value: appear)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6)) {
                appear = true
            }
        }
    }

    private func completionStat(icon: String, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 14))
                .foregroundStyle(.green)
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .frame(width: 20)
            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
        }
    }

    // MARK: - Deletion Logic
    private func startDeletion() {
        withAnimation(.spring(response: 0.4)) {
            step = .deleting
        }

        // Continuous haptic feedback
        hapticTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { _ in
            triggerHaptic(.light)
        }

        // Start flame rotation
        withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
            flameRotation = 360
        }

        // Start flame pulse
        withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
            flameScale = 1.2
        }

        // Start glow
        withAnimation(.easeIn(duration: 1.5)) {
            deletionGlow = 1.0
        }

        isDeleting = true
        currentDeleteStep = 0
        progress = 0
        deleteStepText = localization.isRussian ? deleteSteps[0].2 : deleteSteps[0].3
        deleteStepIcon = deleteSteps[0].0

        animateDeleteStep()
    }

    private func animateDeleteStep() {
        guard currentDeleteStep < deleteSteps.count else {
            finishDeletion()
            return
        }

        let stepDuration = Double.random(in: 0.5...0.9)
        let stepProgress = Double(currentDeleteStep + 1) / Double(deleteSteps.count)

        withAnimation(.easeInOut(duration: stepDuration)) {
            progress = stepProgress
            deleteStepText = localization.isRussian
                ? deleteSteps[currentDeleteStep].2
                : deleteSteps[currentDeleteStep].3
            deleteStepIcon = deleteSteps[currentDeleteStep].0
        }

        // Burn edge progress
        withAnimation(.easeIn(duration: stepDuration)) {
            burnEdgeProgress = stepProgress * 0.7
        }

        // Glitch effect at random steps
        if Bool.random() {
            triggerGlitch()
        }

        let stepIndex = currentDeleteStep
        DispatchQueue.main.asyncAfter(deadline: .now() + stepDuration * 0.8) {
            withAnimation(.spring(response: 0.3)) {
                _ = completedSteps.insert(stepIndex)
            }
        }

        currentDeleteStep += 1

        DispatchQueue.main.asyncAfter(deadline: .now() + stepDuration + 0.15) {
            animateDeleteStep()
        }
    }

    private func triggerGlitch() {
        withAnimation(.linear(duration: 0.03)) { glitchOffset = CGFloat.random(in: -5...5) }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.03) {
            withAnimation(.linear(duration: 0.03)) { glitchOffset = CGFloat.random(in: -3...3) }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) {
            withAnimation(.linear(duration: 0.05)) { glitchOffset = 0 }
        }
    }

    private func finishDeletion() {
        hapticTimer?.invalidate()
        hapticTimer = nil

        // Execute actual deletion
        chatService.clearAllData()
        EncryptionService.shared.destroyAllKeys()
        RatingService.shared.resetRating()
        AdminService.shared.resetAll()
        authService.executeFenixProtocol()

        // Heavy haptic
        triggerHaptic(.error)

        // Launch massive particle effect
        showParticles = true
        let screenBounds = CGRect(x: 0, y: 0, width: 400, height: 900)
        particleSystem.emit(from: screenBounds, count: 500)

        // Additional burn particles
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.particleSystem.emitBurnEffect(from: screenBounds)
        }

        // Full burn
        withAnimation(.easeIn(duration: 0.5)) {
            burnEdgeProgress = 1.0
        }

        particleSystem.onComplete = { [self] in
            showParticles = false
            appear = false

            withAnimation(.easeOut(duration: 0.5)) {
                deletionGlow = 0
                burnEdgeProgress = 0
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.spring(response: 0.6)) {
                    step = .complete
                    appear = true
                }
            }
        }
    }

    private func triggerHaptic(_ style: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(style)
    }

    private func triggerHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
}
