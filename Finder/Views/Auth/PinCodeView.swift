import SwiftUI

// MARK: - PIN Code Setup (during registration)
struct PinCodeSetupView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var localization: LocalizationManager

    @State private var pin = ""
    @State private var confirmPin = ""
    @State private var isConfirming = false
    @State private var showError = false
    @State private var shake = false

    let onComplete: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(Color.indigo.opacity(0.15))
                    .frame(width: 80, height: 80)
                Image(systemName: "lock.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(.indigo)
            }

            Text(isConfirming
                 ? localization.localized("Подтвердите PIN", "Confirm PIN")
                 : localization.localized("Создайте PIN-код", "Create PIN code"))
            .font(.title2.bold())

            Text(localization.localized(
                "4-значный код для защиты аккаунта",
                "4-digit code to protect your account"
            ))
            .font(.subheadline)
            .foregroundStyle(.secondary)

            // PIN dots
            HStack(spacing: 20) {
                ForEach(0..<4, id: \.self) { index in
                    Circle()
                        .fill(index < currentPin.count ? Color.indigo : Color.gray.opacity(0.3))
                        .frame(width: 18, height: 18)
                        .scaleEffect(index < currentPin.count ? 1.2 : 1)
                        .animation(.spring(response: 0.2), value: currentPin.count)
                }
            }
            .offset(x: shake ? -10 : 0)
            .animation(.default.repeatCount(3, autoreverses: true).speed(6), value: shake)
            .padding(.vertical, 8)

            // Number pad
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 16) {
                ForEach(1...9, id: \.self) { number in
                    PinButton(number: "\(number)") {
                        addDigit("\(number)")
                    }
                }
                PinButton(number: "", isPlaceholder: true) {}
                PinButton(number: "0") {
                    addDigit("0")
                }
                PinButton(number: "⌫", isDelete: true) {
                    deleteDigit()
                }
            }
            .padding(.horizontal, 40)
        }
    }

    private var currentPin: String {
        isConfirming ? confirmPin : pin
    }

    private func addDigit(_ digit: String) {
        if isConfirming {
            guard confirmPin.count < 4 else { return }
            confirmPin += digit
            if confirmPin.count == 4 {
                verifyPins()
            }
        } else {
            guard pin.count < 4 else { return }
            pin += digit
            if pin.count == 4 {
                withAnimation(.spring(response: 0.3)) {
                    isConfirming = true
                }
            }
        }
    }

    private func deleteDigit() {
        if isConfirming {
            guard !confirmPin.isEmpty else { return }
            confirmPin.removeLast()
        } else {
            guard !pin.isEmpty else { return }
            pin.removeLast()
        }
    }

    private func verifyPins() {
        if pin == confirmPin {
            authService.setupPIN(pin)
            onComplete()
        } else {
            shake.toggle()
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                confirmPin = ""
            }
        }
    }
}

// MARK: - PIN Code Login
struct PinCodeLoginView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var localization: LocalizationManager

    @State private var pin = ""
    @State private var shake = false
    @State private var attempts = 0
    @State private var isLocked = false
    @State private var appear = false

    var body: some View {
        ZStack {
            FloatingOrbsBackground()
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                // Logo
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.blue, .cyan],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                        .shadow(color: .blue.opacity(0.3), radius: 15)

                    Text("F")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                .scaleEffect(appear ? 1 : 0.5)
                .opacity(appear ? 1 : 0)

                Text("Finder")
                    .font(.title.bold())
                    .opacity(appear ? 1 : 0)

                Text(localization.localized("Введите PIN-код", "Enter PIN code"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                // PIN dots
                HStack(spacing: 20) {
                    ForEach(0..<4, id: \.self) { index in
                        Circle()
                            .fill(index < pin.count ? Color.blue : Color.gray.opacity(0.3))
                            .frame(width: 18, height: 18)
                            .scaleEffect(index < pin.count ? 1.2 : 1)
                            .animation(.spring(response: 0.2), value: pin.count)
                    }
                }
                .offset(x: shake ? -10 : 0)
                .animation(.default.repeatCount(3, autoreverses: true).speed(6), value: shake)

                if isLocked {
                    Text(localization.localized("Слишком много попыток. Подождите.", "Too many attempts. Please wait."))
                        .font(.caption)
                        .foregroundStyle(.red)
                }

                Spacer()

                // Biometric button
                if authService.hasSetupBiometric {
                    Button {
                        authenticateWithBiometric()
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: BiometricService.shared.biometricIcon)
                                .font(.system(size: 40))
                                .foregroundStyle(.blue)
                            Text(BiometricService.shared.biometricName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.bottom, 16)
                }

                // Number pad
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 16) {
                    ForEach(1...9, id: \.self) { number in
                        PinButton(number: "\(number)") {
                            addDigit("\(number)")
                        }
                    }
                    PinButton(number: "", isPlaceholder: true) {}
                    PinButton(number: "0") {
                        addDigit("0")
                    }
                    PinButton(number: "⌫", isDelete: true) {
                        deleteDigit()
                    }
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6).delay(0.2)) {
                appear = true
            }
            if authService.hasSetupBiometric {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    authenticateWithBiometric()
                }
            }
        }
    }

    private func addDigit(_ digit: String) {
        guard !isLocked, pin.count < 4 else { return }
        pin += digit
        if pin.count == 4 {
            verifyPin()
        }
    }

    private func deleteDigit() {
        guard !pin.isEmpty else { return }
        pin.removeLast()
    }

    private func verifyPin() {
        if authService.verifyPIN(pin) {
            // Success - handled by AuthService
        } else {
            shake.toggle()
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
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                pin = ""
            }
        }
    }

    private func authenticateWithBiometric() {
        BiometricService.shared.authenticate { success in
            if success {
                authService.isPINLocked = false
                authService.isBiometricLocked = false
                if authService.customBiometricEnabled {
                    authService.isCustomBiometricLocked = true
                    authService.isAuthenticated = false
                } else {
                    authService.isAuthenticated = true
                    authService.loadUser()
                }
            }
        }
    }
}

// MARK: - PIN Button Component
struct PinButton: View {
    let number: String
    var isPlaceholder: Bool = false
    var isDelete: Bool = false
    let action: () -> Void

    var body: some View {
        if isPlaceholder {
            Color.clear.frame(height: 65)
        } else {
            Button(action: {
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
                action()
            }) {
                Text(number)
                    .font(isDelete ? .title2 : .title)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                    .frame(width: 65, height: 65)
                    .background {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .overlay {
                                Circle()
                                    .fill(Color.white.opacity(0.1))
                            }
                            .overlay {
                                Circle()
                                    .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                            }
                    }
            }
        }
    }
}
