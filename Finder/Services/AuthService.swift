import Foundation
import SwiftUI
import CryptoKit

class AuthService: ObservableObject {
    static let shared = AuthService()

    @AppStorage("isLoggedIn") var isLoggedIn: Bool = false
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false
    @AppStorage("hasSetupPIN") var hasSetupPIN: Bool = false
    @AppStorage("hasSetupBiometric") var hasSetupBiometric: Bool = false
    @AppStorage("biometricBindingEnabled") var biometricBindingEnabled: Bool = false
    @AppStorage("customBiometricEnabled") var customBiometricEnabled: Bool = false
    @AppStorage("currentUsername") var currentUsername: String = ""
    @AppStorage("currentDisplayName") var currentDisplayName: String = ""
    @AppStorage("currentFinderID") var currentFinderID: String = ""
    @AppStorage("storedPIN") private var storedPIN: String = ""
    @AppStorage("decoyPIN") var decoyPIN: String = ""
    @AppStorage("isDecoyMode") var isDecoyMode: Bool = false

    // Registered accounts: [username: passwordHash]
    private var registeredAccounts: [String: String] {
        get { UserDefaults.standard.dictionary(forKey: "registeredAccounts") as? [String: String] ?? [:] }
        set { UserDefaults.standard.set(newValue, forKey: "registeredAccounts") }
    }

    @Published var isAuthenticated: Bool = false
    @Published var isPINLocked: Bool = true
    @Published var currentUser: FinderUser?
    @Published var showDecoyAccount: Bool = false
    @Published var isBannedScreen: Bool = false
    @Published var isDeletedScreen: Bool = false
    @Published var isBiometricLocked: Bool = false
    @Published var isCustomBiometricLocked: Bool = false

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
                } else if customBiometricEnabled {
                    isCustomBiometricLocked = true
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

    // MARK: - Password Auth

    private func hashPassword(_ password: String) -> String {
        let data = Data(password.utf8)
        let hash = SHA256.hash(data: data)
        return hash.map { String(format: "%02x", $0) }.joined()
    }

    func isUsernameRegistered(_ username: String) -> Bool {
        registeredAccounts[username.lowercased()] != nil
    }

    func loginWithPassword(username: String, password: String) -> Bool {
        let u = username.lowercased()
        guard let storedHash = registeredAccounts[u] else { return false }
        return hashPassword(password) == storedHash
    }

    func register(username: String, displayName: String, password: String) {
        // Store password hash
        var accounts = registeredAccounts
        accounts[username.lowercased()] = hashPassword(password)
        registeredAccounts = accounts

        register(username: username, displayName: displayName)

        // Server auth in background
        serverAuth(username: username, password: password, displayName: displayName)
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
                isUntrusted: false,
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
            isUntrusted: AdminService.shared.isUntrusted(username),
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
        customBiometricEnabled = false
        isBiometricLocked = false
        isCustomBiometricLocked = false

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
            } else if customBiometricEnabled {
                isCustomBiometricLocked = true
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
        if customBiometricEnabled {
            isCustomBiometricLocked = true
            isAuthenticated = false
        } else {
            isAuthenticated = true
            loadCurrentUser()
        }
    }

    func unlockCustomBiometric() {
        isCustomBiometricLocked = false
        isAuthenticated = true
        loadCurrentUser()
    }

    func logout() {
        isAuthenticated = false
        isPINLocked = true
        isBiometricLocked = false
        isCustomBiometricLocked = false
        currentUser = nil
    }

    // Мягкое удаление — аккаунт деактивируется, но данные сохраняются
    func softDeleteAccount() {
        let savedFinderID = currentFinderID
        let savedUsername = currentUsername

        // Сохраняем Finder ID для восстановления
        var deletedAccounts = UserDefaults.standard.dictionary(forKey: "deletedAccounts") as? [String: String] ?? [:]
        deletedAccounts[savedFinderID] = savedUsername
        UserDefaults.standard.set(deletedAccounts, forKey: "deletedAccounts")

        // Деактивируем
        isAuthenticated = false
        isPINLocked = false
        isDeletedScreen = true
        currentUser = nil
    }

    // Восстановление аккаунта по Finder ID
    func restoreAccount(finderID: String) -> Bool {
        let deletedAccounts = UserDefaults.standard.dictionary(forKey: "deletedAccounts") as? [String: String] ?? [:]

        if let _ = deletedAccounts[finderID], finderID == currentFinderID {
            isDeletedScreen = false
            isAuthenticated = true
            isPINLocked = false
            loadCurrentUser()

            // Убираем из удалённых
            var updated = deletedAccounts
            updated.removeValue(forKey: finderID)
            UserDefaults.standard.set(updated, forKey: "deletedAccounts")
            return true
        }
        return false
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
        customBiometricEnabled = false
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
                isUntrusted: AdminService.shared.isUntrusted(currentUsername),
                isBanned: false,
                isDeleted: false,
                finderID: currentFinderID,
                joinDate: Date(),
                privacySettings: .default
            )
        }
    }
}
