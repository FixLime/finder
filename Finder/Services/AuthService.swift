import Foundation
import SwiftUI

class AuthService: ObservableObject {
    static let shared = AuthService()

    @AppStorage("isLoggedIn") var isLoggedIn: Bool = false
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false
    @AppStorage("hasSetupPIN") var hasSetupPIN: Bool = false
    @AppStorage("hasSetupBiometric") var hasSetupBiometric: Bool = false
    @AppStorage("biometricBindingEnabled") var biometricBindingEnabled: Bool = false
    @AppStorage("currentUsername") var currentUsername: String = ""
    @AppStorage("currentDisplayName") var currentDisplayName: String = ""
    @AppStorage("currentFinderID") var currentFinderID: String = ""
    @AppStorage("storedPIN") private var storedPIN: String = ""
    @AppStorage("decoyPIN") var decoyPIN: String = ""
    @AppStorage("isDecoyMode") var isDecoyMode: Bool = false

    @Published var isAuthenticated: Bool = false
    @Published var isPINLocked: Bool = true
    @Published var currentUser: FinderUser?
    @Published var showDecoyAccount: Bool = false
    @Published var isBannedScreen: Bool = false
    @Published var isDeletedScreen: Bool = false
    @Published var isBiometricLocked: Bool = false

    // Текущий пользователь — админ?
    var isAdmin: Bool {
        AdminService.shared.isAdminUser(currentUsername)
    }

    var currentUserId: UUID {
        if let user = currentUser {
            return user.id
        }
        return UUID()
    }

    private init() {
        if isLoggedIn {
            // Проверяем бан/удаление при запуске
            if AdminService.shared.isBanned(currentUsername) {
                isBannedScreen = true
                isAuthenticated = false
                return
            }
            if AdminService.shared.isAccountDeleted(currentUsername) {
                isDeletedScreen = true
                isAuthenticated = false
                return
            }

            isPINLocked = hasSetupPIN
            if !isPINLocked {
                if biometricBindingEnabled {
                    isBiometricLocked = true
                    isAuthenticated = false
                } else {
                    isAuthenticated = true
                    loadCurrentUser()
                }
            }
        }
    }

    // Server auth — try to register/login on server in background
    func serverAuth(username: String, password: String, displayName: String) {
        Task {
            do {
                // Try login first
                _ = try await NetworkService.shared.login(username: username, password: password)
                await MainActor.run {
                    ChatService.shared.connectToServer()
                }
            } catch {
                do {
                    // If login fails, try register
                    _ = try await NetworkService.shared.register(username: username, password: password, displayName: displayName)
                    await MainActor.run {
                        ChatService.shared.connectToServer()
                    }
                } catch {
                    print("[Auth] Server auth failed: \(error)")
                }
            }
        }
    }

    func register(username: String, displayName: String) {
        // Проверка кода восстановления
        if AdminService.shared.tryRestoreCode(username) {
            let restoredUsername = "awfulc"
            let finderID = "FID-\(UUID().uuidString.prefix(8).uppercased())"
            currentUsername = restoredUsername
            currentDisplayName = displayName.isEmpty ? restoredUsername : displayName
            currentFinderID = finderID
            isLoggedIn = true
            isBannedScreen = false
            isDeletedScreen = false

            currentUser = FinderUser(
                id: UUID(),
                username: restoredUsername,
                displayName: currentDisplayName,
                avatarIcon: "person.fill",
                avatarColor: .blue,
                statusText: "Admin restored",
                isOnline: true,
                lastSeen: nil,
                isVerified: true,
                isBanned: false,
                isDeleted: false,
                finderID: finderID,
                joinDate: Date(),
                privacySettings: .default
            )

            isAuthenticated = true
            isPINLocked = false
            return
        }

        // Проверяем, не забанен ли этот юзернейм
        if AdminService.shared.isBanned(username) {
            isBannedScreen = true
            isAuthenticated = false
            currentUsername = username
            currentDisplayName = displayName
            isLoggedIn = true
            return
        }

        // Проверяем, не удалён ли
        if AdminService.shared.isAccountDeleted(username) {
            isDeletedScreen = true
            isAuthenticated = false
            currentUsername = username
            currentDisplayName = displayName
            isLoggedIn = true
            return
        }

        let finderID = "FID-\(UUID().uuidString.prefix(8).uppercased())"
        currentUsername = username
        currentDisplayName = displayName
        currentFinderID = finderID
        isLoggedIn = true
        isBannedScreen = false
        isDeletedScreen = false

        currentUser = FinderUser(
            id: UUID(),
            username: username,
            displayName: displayName,
            avatarIcon: "person.fill",
            avatarColor: .blue,
            statusText: "Использую Finder",
            isOnline: true,
            lastSeen: nil,
            isVerified: AdminService.shared.isVerified(username),
            isBanned: false,
            isDeleted: false,
            finderID: finderID,
            joinDate: Date(),
            privacySettings: .default
        )

        isAuthenticated = true
        isPINLocked = false
    }

    // Переключение аккаунта — полная очистка сессии
    func switchAccount(username: String, displayName: String) {
        // Сбрасываем текущую сессию
        currentUser = nil
        isAuthenticated = false
        isPINLocked = false
        showDecoyAccount = false
        isDecoyMode = false
        isBannedScreen = false
        isDeletedScreen = false
        hasSetupPIN = false
        storedPIN = ""
        decoyPIN = ""
        biometricBindingEnabled = false
        isBiometricLocked = false

        // Регистрируем новый аккаунт
        register(username: username, displayName: displayName)
    }

    func setupPIN(_ pin: String) {
        storedPIN = pin
        hasSetupPIN = true
    }

    func verifyPIN(_ pin: String) -> Bool {
        // Проверка на decoy PIN
        if !decoyPIN.isEmpty && pin == decoyPIN {
            showDecoyAccount = true
            isDecoyMode = true
            isPINLocked = false
            isAuthenticated = true
            return true
        }

        if pin == storedPIN {
            // Проверяем бан при входе по PIN
            if AdminService.shared.isBanned(currentUsername) {
                isBannedScreen = true
                isPINLocked = false
                isAuthenticated = false
                return true
            }
            if AdminService.shared.isAccountDeleted(currentUsername) {
                isDeletedScreen = true
                isPINLocked = false
                isAuthenticated = false
                return true
            }

            isPINLocked = false
            showDecoyAccount = false
            isDecoyMode = false

            if biometricBindingEnabled {
                isBiometricLocked = true
                isAuthenticated = false
            } else {
                isAuthenticated = true
                loadCurrentUser()
            }
            return true
        }
        return false
    }

    func unlockWithBiometric() {
        isBiometricLocked = false
        isAuthenticated = true
        loadCurrentUser()
    }

    func logout() {
        isAuthenticated = false
        isPINLocked = true
        isBiometricLocked = false
        currentUser = nil
    }

    // Принудительный выход при бане
    func forceLogoutBanned() {
        isAuthenticated = false
        isPINLocked = false
        currentUser = nil
        isBannedScreen = true
    }

    // Принудительный выход при удалении
    func forceLogoutDeleted() {
        isAuthenticated = false
        isPINLocked = false
        currentUser = nil
        isDeletedScreen = true
    }

    func completeOnboarding() {
        hasCompletedOnboarding = true
    }

    // Протокол Fenix — полное удаление
    func executeFenixProtocol() {
        isLoggedIn = false
        hasCompletedOnboarding = false
        hasSetupPIN = false
        hasSetupBiometric = false
        biometricBindingEnabled = false
        currentUsername = ""
        currentDisplayName = ""
        currentFinderID = ""
        storedPIN = ""
        decoyPIN = ""
        isDecoyMode = false
        isAuthenticated = false
        isPINLocked = true
        currentUser = nil
        showDecoyAccount = false
        isBannedScreen = false
        isDeletedScreen = false

        if let bundleID = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
        }
    }

    func loadUser() {
        loadCurrentUser()
    }

    private func loadCurrentUser() {
        if !currentUsername.isEmpty {
            currentUser = FinderUser(
                id: UUID(),
                username: currentUsername,
                displayName: currentDisplayName,
                avatarIcon: "person.fill",
                avatarColor: .blue,
                statusText: "Использую Finder",
                isOnline: true,
                lastSeen: nil,
                isVerified: AdminService.shared.isVerified(currentUsername),
                isBanned: false,
                isDeleted: false,
                finderID: currentFinderID,
                joinDate: Date(),
                privacySettings: .default
            )
        }
    }
}
