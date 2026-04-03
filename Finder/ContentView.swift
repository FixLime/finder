import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var localization: LocalizationManager
    @EnvironmentObject var chatService: ChatService

    var body: some View {
        Group {
            if !authService.hasCompletedOnboarding {
                OnboardingView()
                    .transition(.opacity)
            } else if authService.isBannedScreen {
                BannedAccountView()
                    .transition(.opacity)
            } else if authService.isDeletedScreen {
                DeletedAccountView()
                    .transition(.opacity)
            } else if authService.isPINLocked && authService.hasSetupPIN {
                PinCodeLoginView()
                    .transition(.opacity)
            } else if authService.isBiometricLocked && authService.biometricBindingEnabled {
                BiometricLockView()
                    .transition(.opacity)
            } else if authService.isCustomBiometricLocked && authService.customBiometricEnabled {
                CustomBiometricVerifyView()
                    .transition(.opacity)
            } else if authService.isDecoyMode {
                DecoyAccountView()
                    .transition(.opacity)
            } else if authService.isAuthenticated {
                MainTabView()
                    .transition(.opacity)
            } else {
                // Не залогинен — показываем онбординг
                OnboardingView()
                    .transition(.opacity)
            }
        }
        .animation(.spring(response: 0.5), value: authService.hasCompletedOnboarding)
        .animation(.spring(response: 0.5), value: authService.isPINLocked)
        .animation(.spring(response: 0.5), value: authService.isBiometricLocked)
        .animation(.spring(response: 0.5), value: authService.isCustomBiometricLocked)
        .animation(.spring(response: 0.5), value: authService.isAuthenticated)
        .animation(.spring(response: 0.5), value: authService.isBannedScreen)
        .animation(.spring(response: 0.5), value: authService.isDeletedScreen)
    }
}

// MARK: - Banned Account Screen
struct BannedAccountView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var localization: LocalizationManager
    @EnvironmentObject var chatService: ChatService
    @State private var restoreCode = ""
    @State private var showRestore = false
    @State private var shakeOffset: CGFloat = 0

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.1))
                    .frame(width: 120, height: 120)

                Image(systemName: "nosign")
                    .font(.system(size: 56))
                    .foregroundStyle(.red)
            }

            VStack(spacing: 8) {
                Text(localization.localized("Аккаунт заблокирован", "Account Banned"))
                    .font(.title2.bold())
                    .foregroundStyle(.red)

                Text("@\(authService.currentUsername)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(localization.localized(
                    "Ваш аккаунт был заблокирован администратором.\nДоступ к мессенджеру ограничен.",
                    "Your account has been banned by an administrator.\nAccess to the messenger is restricted."
                ))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .padding(.top, 8)
            }

            Spacer()

            if showRestore {
                VStack(spacing: 12) {
                    Text(localization.localized("Код восстановления", "Restore Code"))
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)

                    TextField(localization.localized("Введите код", "Enter code"), text: $restoreCode)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .multilineTextAlignment(.center)
                        .font(.system(size: 18, design: .monospaced))
                        .padding(14)
                        .liquidGlassCard(cornerRadius: 12)
                        .padding(.horizontal, 40)
                        .offset(x: shakeOffset)

                    Button {
                        if AdminService.shared.tryRestoreCode(restoreCode) {
                            authService.switchAccount(username: "awfulc", displayName: "awfulc")
                            chatService.loadDemoData()
                        } else {
                            // Shake animation
                            withAnimation(.default) {
                                shakeOffset = 10
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                withAnimation(.default) { shakeOffset = -10 }
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                withAnimation(.default) { shakeOffset = 0 }
                            }
                            HapticService.error()
                        }
                    } label: {
                        Text(localization.localized("Восстановить", "Restore"))
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                Capsule().fill(restoreCode.isEmpty ? Color.gray : Color.blue)
                            )
                    }
                    .disabled(restoreCode.isEmpty)
                    .padding(.horizontal, 40)
                }
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }

            VStack(spacing: 12) {
                Button {
                    withAnimation { showRestore.toggle() }
                } label: {
                    Text(localization.localized("Есть код восстановления", "Have a restore code"))
                        .font(.subheadline)
                        .foregroundStyle(.blue)
                }

                Button {
                    // Выйти полностью — показать регистрацию
                    authService.executeFenixProtocol()
                } label: {
                    Text(localization.localized("Создать новый аккаунт", "Create new account"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.bottom, 50)
        }
    }
}

// MARK: - Deleted Account Screen
struct DeletedAccountView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var localization: LocalizationManager
    @State private var restoreCode = ""
    @State private var showRestore = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: 120, height: 120)

                Image(systemName: "person.crop.circle.badge.xmark")
                    .font(.system(size: 50))
                    .foregroundStyle(.gray)
            }

            VStack(spacing: 8) {
                Text(localization.localized("Аккаунт удалён", "Account Deleted"))
                    .font(.title2.bold())

                Text("@\(authService.currentUsername)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(localization.localized(
                    "Ваш аккаунт был удалён.\nВсе данные стёрты.",
                    "Your account has been deleted.\nAll data has been erased."
                ))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .padding(.top, 8)
            }

            Spacer()

            if showRestore {
                VStack(spacing: 12) {
                    TextField(localization.localized("Код восстановления", "Restore code"), text: $restoreCode)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .multilineTextAlignment(.center)
                        .font(.system(size: 18, design: .monospaced))
                        .padding(14)
                        .liquidGlassCard(cornerRadius: 12)
                        .padding(.horizontal, 40)

                    Button {
                        if AdminService.shared.tryRestoreCode(restoreCode) {
                            authService.switchAccount(username: "awfulc", displayName: "awfulc")
                        }
                    } label: {
                        Text(localization.localized("Восстановить", "Restore"))
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Capsule().fill(restoreCode.isEmpty ? Color.gray : Color.blue))
                    }
                    .disabled(restoreCode.isEmpty)
                    .padding(.horizontal, 40)
                }
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }

            VStack(spacing: 12) {
                Button {
                    withAnimation { showRestore.toggle() }
                } label: {
                    Text(localization.localized("Есть код восстановления", "Have a restore code"))
                        .font(.subheadline)
                        .foregroundStyle(.blue)
                }

                Button {
                    authService.executeFenixProtocol()
                } label: {
                    Text(localization.localized("Создать новый аккаунт", "Create new account"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.bottom, 50)
        }
    }
}

// MARK: - Decoy Account
struct DecoyAccountView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var localization: LocalizationManager

    var body: some View {
        NavigationStack {
            VStack {
                Spacer()

                Image(systemName: "bubble.left.and.bubble.right")
                    .font(.system(size: 50))
                    .foregroundStyle(.secondary.opacity(0.5))

                Text(localization.localized("Нет чатов", "No chats"))
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .padding(.top, 12)

                Text(localization.localized(
                    "Начните общение, найдя пользователя",
                    "Start chatting by finding a user"
                ))
                .font(.subheadline)
                .foregroundStyle(.secondary.opacity(0.7))

                Spacer()
            }
            .navigationTitle(localization.chats)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        authService.logout()
                        authService.isDecoyMode = false
                    } label: {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .foregroundStyle(.red)
                    }
                }
            }
        }
    }
}
