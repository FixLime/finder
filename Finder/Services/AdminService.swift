import Foundation
import SwiftUI

class AdminService: ObservableObject {
    static let shared = AdminService()

    private let adminUsername = "awfulc"
    private let restoreCode = "awfulc_giveadmin22"

    // Список верифицированных юзернеймов
    @AppStorage("verifiedUsernames") private var verifiedUsernamesRaw: String = ""
    // Список забаненных юзернеймов
    @AppStorage("bannedUsernames") private var bannedUsernamesRaw: String = ""
    // Список удалённых юзернеймов
    @AppStorage("deletedUsernames") private var deletedUsernamesRaw: String = ""
    // Список недоверенных юзернеймов
    @AppStorage("untrustedUsernames") private var untrustedUsernamesRaw: String = ""

    @Published var verifiedUsernames: Set<String> = []
    @Published var bannedUsernames: Set<String> = []
    @Published var deletedUsernames: Set<String> = []
    @Published var untrustedUsernames: Set<String> = []

    private init() {
        loadData()
    }

    private func loadData() {
        verifiedUsernames = Set(verifiedUsernamesRaw.split(separator: ",").map { String($0) })
        bannedUsernames = Set(bannedUsernamesRaw.split(separator: ",").map { String($0) })
        deletedUsernames = Set(deletedUsernamesRaw.split(separator: ",").map { String($0) })
        untrustedUsernames = Set(untrustedUsernamesRaw.split(separator: ",").map { String($0) })
    }

    private func saveData() {
        verifiedUsernamesRaw = verifiedUsernames.joined(separator: ",")
        bannedUsernamesRaw = bannedUsernames.joined(separator: ",")
        deletedUsernamesRaw = deletedUsernames.joined(separator: ",")
        untrustedUsernamesRaw = untrustedUsernames.joined(separator: ",")
        objectWillChange.send()
    }

    // Динамическая проверка админа — НЕ сохраняется в AppStorage
    func isAdminUser(_ username: String) -> Bool {
        return username.lowercased() == adminUsername
    }

    // Проверка кода восстановления
    func tryRestoreCode(_ code: String) -> Bool {
        if code == restoreCode {
            bannedUsernames.remove(adminUsername)
            deletedUsernames.remove(adminUsername)
            saveData()
            return true
        }
        return false
    }

    // Верификация
    func verifyUser(_ username: String) {
        let u = username.lowercased().trimmingCharacters(in: .whitespaces)
        guard !u.isEmpty else { return }
        verifiedUsernames.insert(u)
        saveData()
    }

    func unverifyUser(_ username: String) {
        let u = username.lowercased().trimmingCharacters(in: .whitespaces)
        verifiedUsernames.remove(u)
        saveData()
    }

    func isVerified(_ username: String) -> Bool {
        verifiedUsernames.contains(username.lowercased().trimmingCharacters(in: .whitespaces))
    }

    // Бан
    func banUser(_ username: String) {
        let u = username.lowercased().trimmingCharacters(in: .whitespaces)
        guard !u.isEmpty else { return }
        bannedUsernames.insert(u)
        saveData()

        // Если забанили текущего пользователя — выкидываем
        if AuthService.shared.currentUsername.lowercased() == u {
            DispatchQueue.main.async {
                AuthService.shared.forceLogoutBanned()
            }
        }
    }

    func unbanUser(_ username: String) {
        let u = username.lowercased().trimmingCharacters(in: .whitespaces)
        bannedUsernames.remove(u)
        saveData()
    }

    func isBanned(_ username: String) -> Bool {
        bannedUsernames.contains(username.lowercased().trimmingCharacters(in: .whitespaces))
    }

    // Удаление аккаунта
    func deleteUserAccount(_ username: String) {
        let u = username.lowercased().trimmingCharacters(in: .whitespaces)
        guard !u.isEmpty else { return }
        deletedUsernames.insert(u)
        saveData()

        // Если удалили текущего пользователя — выкидываем
        if AuthService.shared.currentUsername.lowercased() == u {
            DispatchQueue.main.async {
                AuthService.shared.forceLogoutDeleted()
            }
        }
    }

    func restoreUserAccount(_ username: String) {
        let u = username.lowercased().trimmingCharacters(in: .whitespaces)
        deletedUsernames.remove(u)
        saveData()
    }

    func isAccountDeleted(_ username: String) -> Bool {
        deletedUsernames.contains(username.lowercased().trimmingCharacters(in: .whitespaces))
    }

    // Недоверенный
    func untrustUser(_ username: String) {
        let u = username.lowercased().trimmingCharacters(in: .whitespaces)
        guard !u.isEmpty else { return }
        untrustedUsernames.insert(u)
        saveData()
    }

    func trustUser(_ username: String) {
        let u = username.lowercased().trimmingCharacters(in: .whitespaces)
        untrustedUsernames.remove(u)
        saveData()
    }

    func isUntrusted(_ username: String) -> Bool {
        untrustedUsernames.contains(username.lowercased().trimmingCharacters(in: .whitespaces))
    }

    func resetAll() {
        verifiedUsernames.removeAll()
        bannedUsernames.removeAll()
        deletedUsernames.removeAll()
        untrustedUsernames.removeAll()
        saveData()
    }
}
