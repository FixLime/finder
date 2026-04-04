import Foundation

class ScreenshotExceptionsService: ObservableObject {
    static let shared = ScreenshotExceptionsService()

    @Published var exceptions: Set<String> = []

    private let storageKey = "screenshotExceptions"

    private init() {
        loadExceptions()
    }

    private func loadExceptions() {
        let raw = UserDefaults.standard.string(forKey: storageKey) ?? ""
        exceptions = Set(raw.split(separator: ",").map { String($0).lowercased() })
    }

    private func save() {
        let raw = exceptions.joined(separator: ",")
        UserDefaults.standard.set(raw, forKey: storageKey)
        objectWillChange.send()
    }

    func addException(_ username: String) {
        let u = username.lowercased().trimmingCharacters(in: .whitespaces)
        guard !u.isEmpty else { return }
        exceptions.insert(u)
        save()
    }

    func removeException(_ username: String) {
        let u = username.lowercased().trimmingCharacters(in: .whitespaces)
        exceptions.remove(u)
        save()
    }

    func isException(_ username: String) -> Bool {
        exceptions.contains(username.lowercased().trimmingCharacters(in: .whitespaces))
    }
}
