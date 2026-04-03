import SwiftUI

struct FinderIDSetupView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var localization: LocalizationManager
    @EnvironmentObject var chatService: ChatService

    @State private var username = ""
    @State private var displayName = ""
    @State private var step: SetupStep = .username
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var generatedFinderID = ""
    @State private var appear = false

    enum SetupStep {
        case username
        case displayName
        case finderIDReveal
        case pinSetup
        case biometric
    }

    var body: some View {
        ZStack {
            FloatingOrbsBackground()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar
                HStack {
                    if step != .username {
                        Button {
                            withAnimation(.spring(response: 0.4)) {
                                goBack()
                            }
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.title3)
                                .foregroundStyle(.primary)
                                .padding(10)
                                .liquidGlassCard(cornerRadius: 12)
                        }
                    }
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 8)

                Spacer()

                // Content
                Group {
                    switch step {
                    case .username:
                        usernameStep
                    case .displayName:
                        displayNameStep
                    case .finderIDReveal:
                        finderIDRevealStep
                    case .pinSetup:
                        PinCodeSetupView(onComplete: {
                            withAnimation(.spring(response: 0.5)) {
                                step = .biometric
                                appear = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    withAnimation(.spring(response: 0.5)) { appear = true }
                                }
                            }
                        })
                        .environmentObject(authService)
                        .environmentObject(localization)
                    case .biometric:
                        biometricStep
                    }
                }

                Spacer()
            }
        }
        .alert(errorMessage, isPresented: $showError) {
            Button("OK") {}
        }
        .onAppear {
            withAnimation(.spring(response: 0.5).delay(0.2)) {
                appear = true
            }
        }
    }

    // MARK: - Steps

    private var usernameStep: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.15))
                    .frame(width: 80, height: 80)
                Image(systemName: "at")
                    .font(.system(size: 36, weight: .medium))
                    .foregroundStyle(.blue)
            }
            .scaleEffect(appear ? 1 : 0.5)
            .opacity(appear ? 1 : 0)

            Text(localization.localized("Создайте имя пользователя", "Create your username"))
                .font(.title2.bold())
                .offset(y: appear ? 0 : 20)
                .opacity(appear ? 1 : 0)

            Text(localization.localized(
                "Это ваш уникальный идентификатор в Finder.\nБез номера телефона, без почты.",
                "This is your unique Finder identifier.\nNo phone number, no email."
            ))
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .offset(y: appear ? 0 : 20)
            .opacity(appear ? 1 : 0)

            TextField(localization.localized("Имя пользователя", "Username"), text: $username)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .liquidGlassTextField()
                .padding(.horizontal, 32)
                .offset(y: appear ? 0 : 20)
                .opacity(appear ? 1 : 0)

            Button {
                validateUsername()
            } label: {
                Text(localization.next)
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .liquidGlassButton()
            }
            .padding(.horizontal, 32)
            .opacity(username.count >= 3 ? 1 : 0.5)
            .disabled(username.count < 3)
        }
    }

    private var displayNameStep: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(Color.purple.opacity(0.15))
                    .frame(width: 80, height: 80)
                Image(systemName: "person.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(.purple)
            }
            .scaleEffect(appear ? 1 : 0.5)
            .opacity(appear ? 1 : 0)

            Text(localization.localized("Как вас зовут?", "What's your name?"))
                .font(.title2.bold())
                .offset(y: appear ? 0 : 20)
                .opacity(appear ? 1 : 0)

            Text(localization.localized(
                "Это имя увидят другие пользователи",
                "This name will be visible to others"
            ))
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .offset(y: appear ? 0 : 20)
            .opacity(appear ? 1 : 0)

            TextField(localization.localized("Отображаемое имя", "Display name"), text: $displayName)
                .liquidGlassTextField()
                .padding(.horizontal, 32)
                .offset(y: appear ? 0 : 20)
                .opacity(appear ? 1 : 0)

            Button {
                createAccount()
            } label: {
                Text(localization.next)
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .liquidGlassButton()
            }
            .padding(.horizontal, 32)
            .opacity(displayName.count >= 2 ? 1 : 0.5)
            .disabled(displayName.count < 2)
        }
    }

    private var finderIDRevealStep: some View {
        VStack(spacing: 24) {
            FingerprintView(color: .cyan)
                .frame(width: 100, height: 100)
                .scaleEffect(appear ? 1 : 0.5)
                .opacity(appear ? 1 : 0)

            Text(localization.localized("Ваш FinderID", "Your FinderID"))
                .font(.title2.bold())
                .offset(y: appear ? 0 : 20)
                .opacity(appear ? 1 : 0)

            Text(generatedFinderID)
                .font(.system(size: 22, weight: .bold, design: .monospaced))
                .foregroundStyle(.cyan)
                .padding()
                .liquidGlassCard(cornerRadius: 16)
                .padding(.horizontal, 32)
                .offset(y: appear ? 0 : 20)
                .opacity(appear ? 1 : 0)

            Text(localization.localized(
                "Запомните ваш FinderID.\nОн понадобится для входа в аккаунт.",
                "Remember your FinderID.\nYou'll need it to log in."
            ))
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .offset(y: appear ? 0 : 20)
            .opacity(appear ? 1 : 0)

            Button {
                withAnimation(.spring(response: 0.5)) {
                    step = .pinSetup
                    appear = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(.spring(response: 0.5)) { appear = true }
                    }
                }
            } label: {
                Text(localization.continueText)
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .liquidGlassButton()
            }
            .padding(.horizontal, 32)
        }
    }

    private var biometricStep: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.15))
                    .frame(width: 80, height: 80)
                Image(systemName: BiometricService.shared.biometricIcon)
                    .font(.system(size: 36))
                    .foregroundStyle(.green)
            }
            .scaleEffect(appear ? 1 : 0.5)
            .opacity(appear ? 1 : 0)

            Text(localization.localized(
                "Настроить \(BiometricService.shared.biometricName)?",
                "Set up \(BiometricService.shared.biometricName)?"
            ))
            .font(.title2.bold())
            .offset(y: appear ? 0 : 20)
            .opacity(appear ? 1 : 0)

            Text(localization.localized(
                "Быстрый и безопасный вход\nс помощью биометрии",
                "Quick and secure login\nusing biometrics"
            ))
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .offset(y: appear ? 0 : 20)
            .opacity(appear ? 1 : 0)

            VStack(spacing: 12) {
                Button {
                    setupBiometric()
                } label: {
                    Text(localization.localized("Настроить", "Set Up"))
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .liquidGlassButton()
                }

                Button {
                    completeSetup()
                } label: {
                    Text(localization.localized("Пропустить", "Skip"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 32)
        }
    }

    // MARK: - Actions

    private func validateUsername() {
        let trimmed = username.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard trimmed.count >= 3 else {
            errorMessage = localization.localized("Минимум 3 символа", "Minimum 3 characters")
            showError = true
            return
        }
        guard trimmed.allSatisfy({ $0.isLetter || $0.isNumber || $0 == "_" }) else {
            errorMessage = localization.localized(
                "Только буквы, цифры и подчёркивания",
                "Only letters, numbers and underscores"
            )
            showError = true
            return
        }
        username = trimmed
        withAnimation(.spring(response: 0.5)) {
            step = .displayName
            appear = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.5)) { appear = true }
            }
        }
    }

    private func createAccount() {
        authService.register(username: username, displayName: displayName)
        generatedFinderID = authService.currentFinderID
        withAnimation(.spring(response: 0.5)) {
            step = .finderIDReveal
            appear = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.5)) { appear = true }
            }
        }
    }

    private func setupBiometric() {
        BiometricService.shared.authenticate { success in
            if success {
                authService.hasSetupBiometric = true
            }
            completeSetup()
        }
    }

    private func completeSetup() {
        authService.completeOnboarding()
    }

    private func goBack() {
        appear = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            switch step {
            case .displayName: step = .username
            case .finderIDReveal: step = .displayName
            case .pinSetup: step = .finderIDReveal
            case .biometric: step = .pinSetup
            default: break
            }
            withAnimation(.spring(response: 0.5)) { appear = true }
        }
    }
}
