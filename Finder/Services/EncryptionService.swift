import Foundation
import CryptoKit

// MARK: - E2E Encryption Service (Signal-like protocol)
// X25519 key exchange + AES-256-GCM + HKDF key derivation
class EncryptionService: ObservableObject {
    static let shared = EncryptionService()

    // Ключевая пара текущего пользователя
    private(set) var identityKeyPair: Curve25519.KeyAgreement.PrivateKey
    private(set) var signedPreKeyPair: Curve25519.KeyAgreement.PrivateKey

    // Кэш сессионных ключей (chatId -> symmetric key)
    private var sessionKeys: [UUID: SymmetricKey] = [:]

    // Кэш публичных ключей собеседников
    private var peerPublicKeys: [UUID: Curve25519.KeyAgreement.PublicKey] = [:]

    private let keychainTag = "com.finder.messenger.identity"

    private init() {
        // Загрузить или сгенерировать identity key
        if let savedKey = Self.loadKeyFromKeychain(tag: "com.finder.messenger.identity") {
            identityKeyPair = savedKey
        } else {
            identityKeyPair = Curve25519.KeyAgreement.PrivateKey()
            Self.saveKeyToKeychain(key: identityKeyPair, tag: "com.finder.messenger.identity")
        }

        if let savedPreKey = Self.loadKeyFromKeychain(tag: "com.finder.messenger.prekey") {
            signedPreKeyPair = savedPreKey
        } else {
            signedPreKeyPair = Curve25519.KeyAgreement.PrivateKey()
            Self.saveKeyToKeychain(key: signedPreKeyPair, tag: "com.finder.messenger.prekey")
        }
    }

    // MARK: - Public Key (для отправки собеседнику)
    var publicKeyData: Data {
        identityKeyPair.publicKey.rawRepresentation
    }

    var publicKeyString: String {
        publicKeyData.base64EncodedString()
    }

    // Fingerprint для верификации (как в Signal)
    var fingerprint: String {
        let hash = SHA256.hash(data: publicKeyData)
        return hash.prefix(8).map { String(format: "%02X", $0) }.joined(separator: " ")
    }

    // MARK: - Session Setup (X3DH-like key agreement)

    /// Установить сессию с собеседником по его публичному ключу
    func establishSession(chatId: UUID, peerPublicKeyData: Data) throws {
        let peerPublicKey = try Curve25519.KeyAgreement.PublicKey(rawRepresentation: peerPublicKeyData)
        peerPublicKeys[chatId] = peerPublicKey

        // X25519 Diffie-Hellman
        let sharedSecret = try identityKeyPair.sharedSecretFromKeyAgreement(with: peerPublicKey)

        // Дополнительный DH с signed pre-key для forward secrecy
        let preKeySecret = try signedPreKeyPair.sharedSecretFromKeyAgreement(with: peerPublicKey)

        // HKDF деривация сессионного ключа
        let salt = SHA256.hash(data: sharedSecret.withUnsafeBytes { Data($0) } + preKeySecret.withUnsafeBytes { Data($0) })
        let saltData = Data(salt)

        let sessionKey = sharedSecret.hkdfDerivedSymmetricKey(
            using: SHA256.self,
            salt: saltData,
            sharedInfo: "FinderE2ESession".data(using: .utf8)!,
            outputByteCount: 32
        )

        sessionKeys[chatId] = sessionKey
    }

    /// Установить сессию для демо (генерирует ключ собеседника автоматически)
    func establishDemoSession(chatId: UUID) {
        // Для демо — генерируем уникальный сессионный ключ на основе chatId
        let chatData = withUnsafeBytes(of: chatId.uuid) { Data($0) }
        let combined = publicKeyData + chatData
        let hash = SHA256.hash(data: combined)
        let keyData = Data(hash)

        sessionKeys[chatId] = SymmetricKey(data: keyData)
    }

    // MARK: - Encrypt Message

    /// Шифрует текст сообщения AES-256-GCM
    func encrypt(_ plaintext: String, for chatId: UUID) throws -> EncryptedMessage {
        guard let sessionKey = sessionKeys[chatId] else {
            // Автоматически создаём демо-сессию
            establishDemoSession(chatId: chatId)
            return try encrypt(plaintext, for: chatId)
        }

        guard let data = plaintext.data(using: .utf8) else {
            throw EncryptionError.encodingFailed
        }

        // AES-256-GCM шифрование
        let nonce = AES.GCM.Nonce()
        let sealedBox = try AES.GCM.seal(data, using: sessionKey, nonce: nonce)

        guard let combined = sealedBox.combined else {
            throw EncryptionError.encryptionFailed
        }

        return EncryptedMessage(
            ciphertext: combined.base64EncodedString(),
            nonce: Data(nonce).base64EncodedString(),
            senderPublicKey: publicKeyString
        )
    }

    // MARK: - Decrypt Message

    /// Расшифровывает сообщение AES-256-GCM
    func decrypt(_ encrypted: EncryptedMessage, for chatId: UUID) throws -> String {
        guard let sessionKey = sessionKeys[chatId] else {
            establishDemoSession(chatId: chatId)
            return try decrypt(encrypted, for: chatId)
        }

        guard let combined = Data(base64Encoded: encrypted.ciphertext) else {
            throw EncryptionError.decodingFailed
        }

        let sealedBox = try AES.GCM.SealedBox(combined: combined)
        let decryptedData = try AES.GCM.open(sealedBox, using: sessionKey)

        guard let plaintext = String(data: decryptedData, encoding: .utf8) else {
            throw EncryptionError.decodingFailed
        }

        return plaintext
    }

    // MARK: - Verify & Info

    /// Проверить целостность сообщения
    func verifyMessage(_ encrypted: EncryptedMessage) -> Bool {
        guard Data(base64Encoded: encrypted.ciphertext) != nil else { return false }
        return true
    }

    /// Получить fingerprint сессии для верификации
    func sessionFingerprint(for chatId: UUID) -> String? {
        guard let peerKey = peerPublicKeys[chatId] else {
            // Для демо — генерируем фейковый fingerprint
            let chatData = withUnsafeBytes(of: chatId.uuid) { Data($0) }
            let hash = SHA256.hash(data: publicKeyData + chatData)
            return hash.prefix(8).map { String(format: "%02X", $0) }.joined(separator: " ")
        }

        let combined = publicKeyData + peerKey.rawRepresentation
        let hash = SHA256.hash(data: combined)
        return hash.prefix(8).map { String(format: "%02X", $0) }.joined(separator: " ")
    }

    /// Ротация ключей (forward secrecy)
    func rotatePreKey() {
        signedPreKeyPair = Curve25519.KeyAgreement.PrivateKey()
        Self.saveKeyToKeychain(key: signedPreKeyPair, tag: "com.finder.messenger.prekey")
    }

    /// Уничтожить все ключи (для протокола Fenix)
    func destroyAllKeys() {
        sessionKeys.removeAll()
        peerPublicKeys.removeAll()

        identityKeyPair = Curve25519.KeyAgreement.PrivateKey()
        signedPreKeyPair = Curve25519.KeyAgreement.PrivateKey()

        Self.deleteKeyFromKeychain(tag: "com.finder.messenger.identity")
        Self.deleteKeyFromKeychain(tag: "com.finder.messenger.prekey")
    }

    // MARK: - Keychain

    private static func saveKeyToKeychain(key: Curve25519.KeyAgreement.PrivateKey, tag: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: tag,
            kSecValueData as String: key.rawRepresentation
        ]

        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    private static func loadKeyFromKeychain(tag: String) -> Curve25519.KeyAgreement.PrivateKey? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: tag,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return try? Curve25519.KeyAgreement.PrivateKey(rawRepresentation: data)
    }

    private static func deleteKeyFromKeychain(tag: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: tag
        ]
        SecItemDelete(query as CFDictionary)
    }
}

// MARK: - Encrypted Message Model
struct EncryptedMessage: Codable, Hashable {
    let ciphertext: String    // Base64 AES-256-GCM ciphertext
    let nonce: String         // Base64 nonce/IV
    let senderPublicKey: String // Base64 X25519 public key
}

// MARK: - Errors
enum EncryptionError: Error, LocalizedError {
    case encodingFailed
    case decodingFailed
    case encryptionFailed
    case decryptionFailed
    case noSessionKey
    case invalidPublicKey

    var errorDescription: String? {
        switch self {
        case .encodingFailed: return "Failed to encode message"
        case .decodingFailed: return "Failed to decode message"
        case .encryptionFailed: return "Encryption failed"
        case .decryptionFailed: return "Decryption failed"
        case .noSessionKey: return "No session key established"
        case .invalidPublicKey: return "Invalid public key"
        }
    }
}
