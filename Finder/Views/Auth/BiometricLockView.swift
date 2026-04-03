import SwiftUI

struct BiometricLockView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var localization: LocalizationManager

    @State private var appear = false
    @State private var showError = false
    @State private var attempts = 0
    @State private var isLocked = false
    @State private var pulseAnimation = false

    var body: some View {
        ZStack {
            FloatingOrbsBackground()
                .ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()

                // Biometric icon with pulse
                ZStack {
                    // Pulse rings
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .stroke(Color.blue.opacity(0.15), lineWidth: 1.5)
                            .frame(width: CGFloat(100 + i * 30), height: CGFloat(100 + i * 30))
                            .scaleEffect(pulseAnimation ? 1.1 : 0.95)
                            .opacity(pulseAnimation ? 0.0 : 0.6)
                            .animation(
                                .easeInOut(duration: 2.0)
                                .repeatForever(autoreverses: false)
                                .delay(Double(i) * 0.4),
                                value: pulseAnimation
                            )
                    }

                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.blue, .cyan],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 90, height: 90)
                        .shadow(color: .blue.opacity(0.4), radius: 20)

                    Image(systemName: BiometricService.shared.biometricIcon)
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                }
                .scaleEffect(appear ? 1 : 0.5)
                .opacity(appear ? 1 : 0)

                VStack(spacing: 8) {
                    Text(localization.localized("Биометрическая защита", "Biometric Protection"))
                        .font(.title2.bold())
                        .opacity(appear ? 1 : 0)

                    Text(localization.localized(
                        "Этот аккаунт привязан к вашей биометрии.\nПодтвердите личность для входа.",
                        "This account is bound to your biometrics.\nVerify your identity to continue."
                    ))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .opacity(appear ? 1 : 0)
                }

                Spacer()

                if showError {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption)
                        Text(localization.localized(
                            "Биометрия не распознана",
                            "Biometric not recognized"
                        ))
                        .font(.caption)
                    }
                    .foregroundStyle(.red)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                if isLocked {
                    Text(localization.localized(
                        "Слишком много попыток. Подождите 30 секунд.",
                        "Too many attempts. Wait 30 seconds."
                    ))
                    .font(.caption)
                    .foregroundStyle(.red)
                }

                if BiometricService.shared.isAvailable {
                    // Verify button
                    Button {
                        authenticateBiometric()
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: BiometricService.shared.biometricIcon)
                                .font(.system(size: 20))
                            Text(localization.localized(
                                "Подтвердить \(BiometricService.shared.biometricName)",
                                "Verify with \(BiometricService.shared.biometricName)"
                            ))
                            .font(.headline)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: isLocked ? [.gray, .gray] : [.blue, .cyan],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                        .shadow(color: isLocked ? .clear : .blue.opacity(0.3), radius: 10, y: 5)
                    }
                    .disabled(isLocked)
                    .padding(.horizontal, 32)
                } else {
                    // Biometric not available on this device
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(.orange)

                        Text(localization.localized(
                            "Биометрия недоступна",
                            "Biometrics Unavailable"
                        ))
                        .font(.headline)
                        .foregroundStyle(.orange)

                        Text(localization.localized(
                            "Этот аккаунт защищён биометрией, но на данном устройстве она не настроена. Настройте Face ID или Touch ID в системных настройках iPhone.",
                            "This account is protected by biometrics, but it's not set up on this device. Set up Face ID or Touch ID in iPhone system settings."
                        ))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    }
                    .padding(.horizontal, 32)
                }

                // Account info
                HStack(spacing: 6) {
                    Image(systemName: "lock.shield.fill")
                        .font(.caption2)
                    Text("@\(authService.currentUsername)")
                        .font(.caption)
                }
                .foregroundStyle(.secondary.opacity(0.6))
                .padding(.bottom, 50)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6).delay(0.2)) {
                appear = true
            }
            pulseAnimation = true
            // Auto-trigger biometric on appear
            if BiometricService.shared.isAvailable {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    authenticateBiometric()
                }
            }
        }
    }

    private func authenticateBiometric() {
        guard !isLocked else { return }

        BiometricService.shared.authenticate { success in
            if success {
                withAnimation(.spring(response: 0.3)) {
                    showError = false
                    authService.unlockWithBiometric()
                }
            } else {
                withAnimation {
                    showError = true
                }
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.error)
                attempts += 1

                if attempts >= 5 {
                    isLocked = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 30) {
                        isLocked = false
                        attempts = 0
                    }
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation { showError = false }
                }
            }
        }
    }
}
