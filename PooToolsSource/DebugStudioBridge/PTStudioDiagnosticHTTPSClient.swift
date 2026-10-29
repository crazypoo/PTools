#if os(iOS) && DEBUG
import Foundation
#if SWIFT_PACKAGE
import PToolsStudioProtocolCore
#endif

private struct PTStudioDiagnosticPoll: Decodable {
    let schemaVersion: Int
    let commands: [PTStudioDiagnosticCommand]
}

/// Uses the same system-trusted CA + leaf SHA256 pin + Bearer as Network Bridge.
/// No URLProtocol hooks and no broad App Transport Security exceptions.
actor PTStudioDiagnosticHTTPSClient {
    private let endpoint: URL
    private let token: String
    private let session: URLSession
    private let pinDelegate: PTStudioCertificatePinDelegate

    init(endpoint: URL, credentials: PTStudioPairingCredentials) throws {
        guard endpoint.scheme == "https", endpoint.host != nil,
              endpoint.user == nil, endpoint.password == nil,
              endpoint.fragment == nil else { throw PTStudioBridgeError.unsupportedScheme }
        self.endpoint = endpoint
        token = credentials.bearerToken
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = []
        config.httpShouldSetCookies = false
        config.urlCache = nil
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.timeoutIntervalForRequest = 10
        let pin = PTStudioCertificatePinDelegate(expectedSHA256: credentials.leafCertificateSHA256)
        self.pinDelegate = pin
        session = URLSession(configuration: config, delegate: pin, delegateQueue: nil)
    }

    private func post<T: Encodable>(_ value: T, path: String) async throws -> Data {
        var components = URLComponents(url: endpoint, resolvingAgainstBaseURL: false)!
        components.path = path
        components.query = nil
        guard let url = components.url else { throw PTStudioBridgeError.unsupportedScheme }
        let data = try JSONEncoder().encode(value)
        guard data.count <= 512 * 1024 else { throw PTStudioBridgeError.transportRejected }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = data
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("1", forHTTPHeaderField: "X-PTStudio-Internal")
        request.setValue("Bearer " + token, forHTTPHeaderField: "Authorization")
        request.setValue(UUID().uuidString, forHTTPHeaderField: "X-PTStudio-Nonce")
        request.setValue(String(Int(Date().timeIntervalSince1970)), forHTTPHeaderField: "X-PTStudio-Sent-At")
        pinDelegate.clearRejection()
        do {
            let (body, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse,
                  (200..<300).contains(http.statusCode),
                  body.count <= 512 * 1024 else {
                throw PTStudioBridgeError.transportRejected
            }
            return body
        } catch {
            if let failure = pinDelegate.takeRejection() { throw failure }
            throw error
        }
    }

    func poll(sessionID: UUID) async throws -> [PTStudioDiagnosticCommand] {
        struct Request: Encodable { let sessionID: UUID }
        let data = try await post(Request(sessionID: sessionID), path: "/v2/diagnostics/poll")
        let response = try JSONDecoder().decode(PTStudioDiagnosticPoll.self, from: data)
        guard response.schemaVersion == 2, response.commands.count <= 4 else {
            throw PTStudioBridgeError.transportRejected
        }
        return response.commands
    }

    func reply(_ result: PTStudioDiagnosticReply) async throws {
        _ = try await post(result, path: "/v2/diagnostics/reply")
    }

    func close() {
        session.invalidateAndCancel()
    }
}
#endif
