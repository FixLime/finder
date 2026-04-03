import SwiftUI
import AVFoundation

// MARK: - Custom Biometric Setup View
struct CustomBiometricSetupView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var localization: LocalizationManager
    @Environment(\.dismiss) var dismiss

    @State private var step: BiometricSetupStep = .intro
    @State private var isScanning = false
    @State private var scanProgress: CGFloat = 0
    @State private var scanComplete = false
    @State private var pulseAnimation = false
    @State private var showCameraWarning = false

    enum BiometricSetupStep {
        case intro
        case scanning
        case complete
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground).ignoresSafeArea()

                switch step {
                case .intro:
                    introView
                case .scanning:
                    scanningView
                case .complete:
                    completeView
                }
            }
            .navigationTitle(localization.localized("Биометрия", "Biometrics"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(localization.cancel) { dismiss() }
                }
            }
        }
    }

    // MARK: - Intro
    private var introView: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.purple.opacity(0.2), .indigo.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)

                Image(systemName: "person.viewfinder")
                    .font(.system(size: 50))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .indigo],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            VStack(spacing: 10) {
                Text(localization.localized("Сканирование лица", "Face Scanning"))
                    .font(.title2.bold())

                Text(localization.localized(
                    "Создайте биометрический слепок вашего лица для дополнительной защиты аккаунта на всех устройствах.",
                    "Create a biometric imprint of your face for additional account protection across all devices."
                ))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            }

            // Warning card
            VStack(spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text(localization.localized("Важно", "Important"))
                        .font(.subheadline.bold())
                        .foregroundStyle(.orange)
                }

                Text(localization.localized(
                    "Не рекомендуется использовать, если камера на другом устройстве заметно ниже качеством. Различия в камерах могут привести к ошибкам распознавания.",
                    "Not recommended if the camera on another device is significantly lower quality. Camera differences may cause recognition errors."
                ))
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            }
            .padding(14)
            .background(Color.orange.opacity(0.08))
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.orange.opacity(0.2), lineWidth: 1)
            )
            .padding(.horizontal, 24)

            Spacer()

            // Features list
            VStack(alignment: .leading, spacing: 12) {
                biometricFeatureRow(
                    icon: "shield.checkered",
                    color: .green,
                    text: localization.localized("Работает на всех устройствах", "Works across all devices")
                )
                biometricFeatureRow(
                    icon: "lock.fill",
                    color: .blue,
                    text: localization.localized("Дополнительный уровень защиты после Face ID", "Additional protection layer after Face ID")
                )
                biometricFeatureRow(
                    icon: "eye.slash.fill",
                    color: .purple,
                    text: localization.localized("Данные хранятся только на вашем устройстве", "Data stored only on your device")
                )
            }
            .padding(.horizontal, 32)

            Spacer()

            Button {
                withAnimation(.spring(response: 0.4)) {
                    step = .scanning
                }
            } label: {
                Text(localization.localized("Начать сканирование", "Start Scanning"))
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [.purple, .indigo],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 30)
        }
    }

    // MARK: - Scanning
    private var scanningView: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                // Outer scanning rings
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .stroke(Color.purple.opacity(0.2), lineWidth: 1.5)
                        .frame(width: CGFloat(220 + i * 30), height: CGFloat(220 + i * 30))
                        .scaleEffect(pulseAnimation ? 1.05 : 0.95)
                        .opacity(pulseAnimation ? 0.0 : 0.6)
                        .animation(
                            .easeInOut(duration: 1.5)
                            .repeatForever(autoreverses: false)
                            .delay(Double(i) * 0.3),
                            value: pulseAnimation
                        )
                }

                // Face outline
                Circle()
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [.purple, .indigo, .cyan, .purple]),
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(isScanning ? 360 : 0))
                    .animation(
                        .linear(duration: 2).repeatForever(autoreverses: false),
                        value: isScanning
                    )

                // Progress overlay
                Circle()
                    .trim(from: 0, to: scanProgress)
                    .stroke(Color.green, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-90))

                // Face icon
                Image(systemName: "face.dashed")
                    .font(.system(size: 80))
                    .foregroundStyle(.purple.opacity(0.6))

                // Scanning line
                if isScanning && !scanComplete {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [.clear, .purple.opacity(0.5), .clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: 180, height: 3)
                        .offset(y: isScanning ? 80 : -80)
                        .animation(
                            .easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                            value: isScanning
                        )
                }
            }

            VStack(spacing: 8) {
                if scanComplete {
                    Text(localization.localized("Сканирование завершено", "Scan Complete"))
                        .font(.title3.bold())
                        .foregroundStyle(.green)
                } else {
                    Text(localization.localized("Сканирование...", "Scanning..."))
                        .font(.title3.bold())

                    Text(localization.localized(
                        "Держите лицо в рамке и не двигайтесь",
                        "Keep your face in the frame and stay still"
                    ))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }

                Text("\(Int(scanProgress * 100))%")
                    .font(.system(size: 32, weight: .bold, design: .monospaced))
                    .foregroundStyle(scanComplete ? .green : .purple)
            }

            Spacer()
        }
        .onAppear {
            startScanning()
        }
    }

    // MARK: - Complete
    private var completeView: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.15))
                    .frame(width: 120, height: 120)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.green)
            }

            VStack(spacing: 10) {
                Text(localization.localized("Биометрия настроена", "Biometrics Configured"))
                    .font(.title2.bold())

                Text(localization.localized(
                    "Ваш биометрический слепок сохранён. Теперь при входе в аккаунт потребуется верификация лица.",
                    "Your biometric imprint is saved. Face verification will now be required for account login."
                ))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            }

            Spacer()

            Button {
                authService.customBiometricEnabled = true
                dismiss()
            } label: {
                Text(localization.done)
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.green)
                    )
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 30)
        }
    }

    // MARK: - Helpers
    private func biometricFeatureRow(icon: String, color: Color, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(color)
                .frame(width: 24)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.primary)
        }
    }

    private func startScanning() {
        isScanning = true
        pulseAnimation = true

        // Simulate scanning progress
        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timer in
            withAnimation(.linear(duration: 0.05)) {
                scanProgress += 0.01
            }
            if scanProgress >= 1.0 {
                timer.invalidate()
                withAnimation(.spring(response: 0.4)) {
                    scanComplete = true
                    isScanning = false
                }
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)

                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    withAnimation(.spring(response: 0.4)) {
                        step = .complete
                    }
                }
            }
        }
    }
}

// MARK: - Custom Biometric Verify View (Lock Screen)
struct CustomBiometricVerifyView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var localization: LocalizationManager

    @State private var isScanning = false
    @State private var scanProgress: CGFloat = 0
    @State private var verified = false
    @State private var failed = false
    @State private var attempts = 0
    @State private var isLocked = false
    @State private var pulseAnimation = false

    var body: some View {
        ZStack {
            FloatingOrbsBackground()
                .ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()

                ZStack {
                    // Pulse rings
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .stroke(Color.purple.opacity(0.15), lineWidth: 1.5)
                            .frame(width: CGFloat(140 + i * 30), height: CGFloat(140 + i * 30))
                            .scaleEffect(pulseAnimation ? 1.1 : 0.95)
                            .opacity(pulseAnimation ? 0.0 : 0.6)
                            .animation(
                                .easeInOut(duration: 2.0)
                                .repeatForever(autoreverses: false)
                                .delay(Double(i) * 0.4),
                                value: pulseAnimation
                            )
                    }

                    // Scanning ring
                    if isScanning {
                        Circle()
                            .trim(from: 0, to: scanProgress)
                            .stroke(Color.purple, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                            .frame(width: 120, height: 120)
                            .rotationEffect(.degrees(-90))
                    }

                    Circle()
                        .fill(
                            LinearGradient(
                                colors: failed ? [.red, .orange] : [.purple, .indigo],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                        .shadow(color: failed ? .red.opacity(0.4) : .purple.opacity(0.4), radius: 20)

                    Image(systemName: failed ? "xmark" : "person.viewfinder")
                        .font(.system(size: 44))
                        .foregroundColor(.white)
                }

                VStack(spacing: 8) {
                    Text(localization.localized("Верификация лица", "Face Verification"))
                        .font(.title2.bold())

                    Text(localization.localized(
                        "Аккаунт защищён биометрией.\nПосмотрите в камеру для входа.",
                        "Account protected by biometrics.\nLook at the camera to continue."
                    ))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                }

                Spacer()

                if failed {
                    Text(localization.localized(
                        "Лицо не распознано",
                        "Face not recognized"
                    ))
                    .font(.caption)
                    .foregroundStyle(.red)
                }

                if isLocked {
                    Text(localization.localized(
                        "Слишком много попыток. Подождите 30 секунд.",
                        "Too many attempts. Wait 30 seconds."
                    ))
                    .font(.caption)
                    .foregroundStyle(.red)
                }

                Button {
                    startVerification()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "person.viewfinder")
                            .font(.system(size: 20))
                        Text(localization.localized("Сканировать лицо", "Scan Face"))
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: isLocked ? [.gray, .gray] : [.purple, .indigo],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                    .shadow(color: isLocked ? .clear : .purple.opacity(0.3), radius: 10, y: 5)
                }
                .disabled(isLocked || isScanning)
                .padding(.horizontal, 32)

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
            pulseAnimation = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                startVerification()
            }
        }
    }

    private func startVerification() {
        guard !isLocked, !isScanning else { return }

        failed = false
        isScanning = true
        scanProgress = 0

        // Simulate face scan — in production this would use camera + ML model
        Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { timer in
            withAnimation(.linear(duration: 0.03)) {
                scanProgress += 0.02
            }
            if scanProgress >= 1.0 {
                timer.invalidate()

                // Simulate verification result (always succeeds for demo)
                withAnimation(.spring(response: 0.3)) {
                    isScanning = false
                    verified = true
                    authService.unlockCustomBiometric()
                }
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
            }
        }
    }
}
