// English: Real App Attest and DeviceCheck capability adapter; no fake success is returned.
// Español: Adaptador real de App Attest y DeviceCheck; nunca devuelve un éxito falso.
// 中文：真实的 App Attest 与 DeviceCheck 能力适配器，不伪造成功结果。

import Foundation
#if canImport(DeviceCheck)
import DeviceCheck
#endif

public enum PTAppIntegrityCapability: Sendable, Equatable {
    case unsupported
    case appAttest
    case deviceCheck
}

public enum PTAppIntegrityError: Error, Sendable, Equatable {
    case unsupported
    case unavailable
    case failed(String)
}

public actor PTAppIntegrityService {
    #if canImport(DeviceCheck)
    private let appAttest = DCAppAttestService.shared
    private let deviceCheck = DCDevice.current
    #endif

    public init() {}

    public nonisolated var capability: PTAppIntegrityCapability {
        #if canImport(DeviceCheck)
        if DCAppAttestService.shared.isSupported { return .appAttest }
        if DCDevice.current.isSupported { return .deviceCheck }
        #endif
        return .unsupported
    }

    #if canImport(DeviceCheck)
    public func generateKey() async throws -> String {
        guard appAttest.isSupported else { throw PTAppIntegrityError.unsupported }
        return try await withCheckedThrowingContinuation { continuation in
            appAttest.generateKey { keyID, error in
                if let error { continuation.resume(throwing: PTAppIntegrityError.failed(error.localizedDescription)) }
                else if let keyID { continuation.resume(returning: keyID) }
                else { continuation.resume(throwing: PTAppIntegrityError.unavailable) }
            }
        }
    }

    public func attest(keyID: String, clientDataHash: Data) async throws -> Data {
        guard appAttest.isSupported else { throw PTAppIntegrityError.unsupported }
        return try await withCheckedThrowingContinuation { continuation in
            appAttest.attestKey(keyID, clientDataHash: clientDataHash) { attestation, error in
                if let error { continuation.resume(throwing: PTAppIntegrityError.failed(error.localizedDescription)) }
                else if let attestation { continuation.resume(returning: attestation) }
                else { continuation.resume(throwing: PTAppIntegrityError.unavailable) }
            }
        }
    }

    public func assertion(keyID: String, clientDataHash: Data) async throws -> Data {
        guard appAttest.isSupported else { throw PTAppIntegrityError.unsupported }
        return try await withCheckedThrowingContinuation { continuation in
            appAttest.generateAssertion(keyID, clientDataHash: clientDataHash) { assertion, error in
                if let error { continuation.resume(throwing: PTAppIntegrityError.failed(error.localizedDescription)) }
                else if let assertion { continuation.resume(returning: assertion) }
                else { continuation.resume(throwing: PTAppIntegrityError.unavailable) }
            }
        }
    }

    public func deviceCheckToken() async throws -> Data {
        guard deviceCheck.isSupported else { throw PTAppIntegrityError.unsupported }
        return try await withCheckedThrowingContinuation { continuation in
            deviceCheck.generateToken { token, error in
                if let error { continuation.resume(throwing: PTAppIntegrityError.failed(error.localizedDescription)) }
                else if let token { continuation.resume(returning: token) }
                else { continuation.resume(throwing: PTAppIntegrityError.unavailable) }
            }
        }
    }
    #endif
}
