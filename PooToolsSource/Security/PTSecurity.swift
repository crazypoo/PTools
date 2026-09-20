// English: Native security facade for iOS 17+ based on CryptoKit and Security.framework.
// Español: Fachada de seguridad nativa para iOS 17+ basada en CryptoKit y Security.framework.
// 中文：基于 CryptoKit 和 Security.framework 的 iOS 17+ 原生安全门面。

import Foundation
import CryptoKit
import Security

public enum PTSecurityError: Error, LocalizedError, Sendable {
    case invalidInput
    case keychain(OSStatus)
    case itemNotFound
    case authenticationRequired
    case encodingFailed
    case encryptionFailed
    case decryptionFailed
    case signingFailed
    case verificationFailed

    public var errorDescription: String? {
        switch self {
        case .invalidInput: return "安全参数无效 / Invalid security input / Entrada de seguridad no válida"
        case .keychain(let status): return "钥匙串错误 \(status) / Keychain error \(status) / Error de Keychain \(status)"
        case .itemNotFound: return "钥匙串项目不存在 / Keychain item not found / Elemento de Keychain no encontrado"
        case .authenticationRequired: return "需要用户认证 / User authentication is required / Se requiere autenticación del usuario"
        case .encodingFailed: return "编码失败 / Encoding failed / Error de codificación"
        case .encryptionFailed: return "加密失败 / Encryption failed / Error de cifrado"
        case .decryptionFailed: return "解密失败 / Decryption failed / Error de descifrado"
        case .signingFailed: return "签名失败 / Signing failed / Error de firma"
        case .verificationFailed: return "验签失败 / Verification failed / Error de verificación"
        }
    }
}

public enum PTSecurityHashAlgorithm: Sendable {
    case sha256
    case sha384
    case sha512
}

public enum PTKeychainAccessibility: Sendable {
    case whenUnlockedThisDeviceOnly
    case afterFirstUnlockThisDeviceOnly
    case whenPasscodeSetThisDeviceOnly

    fileprivate var value: CFString {
        switch self {
        case .whenUnlockedThisDeviceOnly: return kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        case .afterFirstUnlockThisDeviceOnly: return kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        case .whenPasscodeSetThisDeviceOnly: return kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly
        }
    }
}

public struct PTKeychainOptions: Sendable {
    public let service: String
    public let account: String
    public let accessibility: PTKeychainAccessibility
    public let requiresBiometry: Bool

    public init(service: String,
                account: String,
                accessibility: PTKeychainAccessibility = .whenUnlockedThisDeviceOnly,
                requiresBiometry: Bool = false) {
        self.service = service
        self.account = account
        self.accessibility = accessibility
        self.requiresBiometry = requiresBiometry
    }
}

public enum PTSecurity {
    public static func save(_ data: Data, options: PTKeychainOptions) throws {
        guard !data.isEmpty, !options.service.isEmpty, !options.account.isEmpty else {
            throw PTSecurityError.invalidInput
        }

        var query = baseKeychainQuery(options: options)
        query[kSecValueData] = data
        if options.requiresBiometry {
            var accessControlError: Unmanaged<CFError>?
            guard let accessControl = SecAccessControlCreateWithFlags(nil,
                                                                       options.accessibility.value,
                                                                       .biometryCurrentSet,
                                                                       &accessControlError) else {
                _ = accessControlError?.takeRetainedValue()
                throw PTSecurityError.keychain(errSecParam)
            }
            query[kSecAttrAccessControl] = accessControl
            query.removeValue(forKey: kSecAttrAccessible)
        }

        let addStatus = SecItemAdd(query as CFDictionary, nil)
        guard addStatus == errSecDuplicateItem else {
            guard addStatus == errSecSuccess else { throw PTSecurityError.keychain(addStatus) }
            return
        }

        let updateQuery = baseKeychainQuery(options: options)
        let updateStatus = SecItemUpdate(updateQuery as CFDictionary, [kSecValueData: data] as CFDictionary)
        guard updateStatus == errSecSuccess else { throw PTSecurityError.keychain(updateStatus) }
    }

    public static func read(options: PTKeychainOptions) throws -> Data {
        guard !options.service.isEmpty, !options.account.isEmpty else {
            throw PTSecurityError.invalidInput
        }
        var query = baseKeychainQuery(options: options)
        query[kSecReturnData] = kCFBooleanTrue
        query[kSecMatchLimit] = kSecMatchLimitOne

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess else {
            if status == errSecItemNotFound { throw PTSecurityError.itemNotFound }
            if status == errSecInteractionNotAllowed || status == errSecAuthFailed || status == errSecUserCanceled {
                throw PTSecurityError.authenticationRequired
            }
            throw PTSecurityError.keychain(status)
        }
        guard let data = result as? Data else { throw PTSecurityError.encodingFailed }
        return data
    }

    public static func delete(options: PTKeychainOptions) throws {
        guard !options.service.isEmpty, !options.account.isEmpty else {
            throw PTSecurityError.invalidInput
        }
        let status = SecItemDelete(baseKeychainQuery(options: options) as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw PTSecurityError.keychain(status)
        }
    }

    public static func digest(_ data: Data, algorithm: PTSecurityHashAlgorithm = .sha256) -> Data {
        switch algorithm {
        case .sha256: return Data(SHA256.hash(data: data))
        case .sha384: return Data(SHA384.hash(data: data))
        case .sha512: return Data(SHA512.hash(data: data))
        }
    }

    public static func hmacSHA256(_ data: Data, key: Data) -> Data {
        Data(HMAC<SHA256>.authenticationCode(for: data, using: SymmetricKey(data: key)))
    }

    public static func encrypt(_ data: Data, key: Data) throws -> Data {
        guard !key.isEmpty else { throw PTSecurityError.invalidInput }
        do {
            let sealedBox = try AES.GCM.seal(data, using: SymmetricKey(data: key))
            guard let combined = sealedBox.combined else { throw PTSecurityError.encryptionFailed }
            return combined
        } catch let error as PTSecurityError {
            throw error
        } catch {
            throw PTSecurityError.encryptionFailed
        }
    }

    public static func decrypt(_ data: Data, key: Data) throws -> Data {
        guard !key.isEmpty else { throw PTSecurityError.invalidInput }
        do {
            return try AES.GCM.open(AES.GCM.SealedBox(combined: data), using: SymmetricKey(data: key))
        } catch {
            throw PTSecurityError.decryptionFailed
        }
    }

    public static func makeSigningKey() -> (privateKey: Data, publicKey: Data) {
        let privateKey = P256.Signing.PrivateKey()
        return (privateKey.rawRepresentation, privateKey.publicKey.x963Representation)
    }

    public static func sign(_ data: Data, privateKey: Data) throws -> Data {
        do {
            let key = try P256.Signing.PrivateKey(rawRepresentation: privateKey)
            return try key.signature(for: data).derRepresentation
        } catch {
            throw PTSecurityError.signingFailed
        }
    }

    public static func verify(_ signature: Data, data: Data, publicKey: Data) throws -> Bool {
        do {
            let key = try P256.Signing.PublicKey(x963Representation: publicKey)
            return key.isValidSignature(try P256.Signing.ECDSASignature(derRepresentation: signature), for: data)
        } catch {
            throw PTSecurityError.verificationFailed
        }
    }

    private static func baseKeychainQuery(options: PTKeychainOptions) -> [CFString: Any] {
        [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: options.service,
            kSecAttrAccount: options.account,
            kSecAttrAccessible: options.accessibility.value
        ]
    }
}
