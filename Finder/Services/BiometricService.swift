import LocalAuthentication
import SwiftUI

class BiometricService: ObservableObject {
    static let shared = BiometricService()

    @Published var isAvailable: Bool = false
    @Published var biometricType: LABiometryType = .none

    private let context = LAContext()

    private init() {
        checkAvailability()
    }

    func checkAvailability() {
        var error: NSError?
        isAvailable = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        biometricType = context.biometryType
    }

    func authenticate(completion: @escaping (Bool) -> Void) {
        let context = LAContext()
        context.localizedFallbackTitle = LocalizationManager.shared.isRussian ? "Использовать PIN" : "Use PIN"

        let reason = LocalizationManager.shared.isRussian
            ? "Авторизуйтесь для входа в Finder"
            : "Authenticate to access Finder"

        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, _ in
            DispatchQueue.main.async {
                completion(success)
            }
        }
    }

    var biometricName: String {
        switch biometricType {
        case .faceID: return "Face ID"
        case .touchID: return "Touch ID"
        case .opticID: return "Optic ID"
        case .none: return "Biometric"
        @unknown default: return "Biometric"
        }
    }

    var biometricIcon: String {
        switch biometricType {
        case .faceID: return "faceid"
        case .touchID: return "touchid"
        case .opticID: return "opticid"
        case .none: return "lock.shield"
        @unknown default: return "lock.shield"
        }
    }
}
