// English: Main-actor WebKit bridge using reply handlers, content worlds, and origin checks.
// Español: Puente WebKit en MainActor con respuestas, mundos de contenido y comprobación de origen.
// 中文：基于 MainActor 的 WebKit Bridge，支持 reply、Content World 和来源校验。

import Foundation
import WebKit
#if SWIFT_PACKAGE
import PToolsWebCore
#endif

@MainActor
public final class PTWebBridge: NSObject, WKScriptMessageHandlerWithReply {
    public static let messageName = "PToolsBridge"
    private weak var webView: WKWebView?
    private let policy: PTWebSecurityPolicy
    private var handlers: [String: PTWebHandler] = [:]

    public init(webView: WKWebView,
                policy: PTWebSecurityPolicy = .init()) {
        self.webView = webView
        self.policy = policy
        super.init()
        webView.configuration.userContentController.addScriptMessageHandler(self,
                                                                             contentWorld: .page,
                                                                             name: Self.messageName)
    }

    public func register(method: PTWebMethod, handler: @escaping PTWebHandler) {
        handlers[method.name] = handler
    }

    public func unregister(method: PTWebMethod) { handlers[method.name] = nil }

    public func callJavaScript(method: PTWebMethod, payload: Data = Data()) async throws -> Data {
        guard let webView else { throw PTWebBridgeError.unavailable }
        let script = "window.PToolsBridge && window.PToolsBridge[\(jsonLiteral(method.name))](\(jsonLiteral(payload.base64EncodedString())))"
        let value = try await webView.evaluateJavaScript(script, in: nil, contentWorld: .page)
        if let value = value as? String, let data = Data(base64Encoded: value) {
            return data
        }
        if let value = value as? [String: Any], JSONSerialization.isValidJSONObject(value) {
            return try JSONSerialization.data(withJSONObject: value)
        }
        return Data()
    }

    public func userContentController(_ userContentController: WKUserContentController,
                                      didReceive message: WKScriptMessage,
                                      replyHandler: @escaping @MainActor @Sendable (Any?, String?) -> Void) {
        guard message.name == Self.messageName,
              let dictionary = message.body as? [String: Any],
              let methodName = dictionary["method"] as? String,
              policy.allowedMethods.isEmpty || policy.allowedMethods.contains(methodName),
              let handler = handlers[methodName] else {
            replyHandler(nil, String(describing: PTWebBridgeError.methodNotAllowed))
            return
        }
        if policy.mainFrameOnly, message.frameInfo.isMainFrame == false {
            replyHandler(nil, String(describing: PTWebBridgeError.originNotAllowed))
            return
        }
        let origin = message.frameInfo.securityOrigin
        let originValue = "\(origin.protocol)://\(origin.host)"
        if !policy.allowedOrigins.isEmpty, !policy.allowedOrigins.contains(originValue) {
            replyHandler(nil, String(describing: PTWebBridgeError.originNotAllowed))
            return
        }
        let payload: Data
        if let base64 = dictionary["payload"] as? String { payload = Data(base64Encoded: base64) ?? Data() }
        else { payload = Data() }
        let request = PTWebRequest(method: PTWebMethod(methodName), payload: payload)
        Task { @MainActor in
            do {
                let response = try await perform(handler: handler, request: request)
                replyHandler(["requestID": response.requestID.uuidString,
                              "payload": response.payload.base64EncodedString()], nil)
            } catch {
                replyHandler(nil, String(describing: error))
            }
        }
    }

    public func handleLegacyPrompt(method: String, payload: Data = Data()) async throws -> Data {
        guard let handler = handlers[method] else { throw PTWebBridgeError.methodNotAllowed }
        let request = PTWebRequest(method: PTWebMethod(method), payload: payload)
        return try await perform(handler: handler, request: request).payload
    }

    private func perform(handler: @escaping PTWebHandler,
                         request: PTWebRequest) async throws -> PTWebResponse {
        let timeout = policy.timeout
        return try await withThrowingTaskGroup(of: PTWebResponse.self) { group in
            group.addTask { try await handler(request) }
            group.addTask {
                try await Task.sleep(for: timeout)
                throw PTWebBridgeError.timedOut
            }
            defer { group.cancelAll() }
            guard let response = try await group.next() else {
                throw PTWebBridgeError.unavailable
            }
            return response
        }
    }

    private func jsonLiteral(_ string: String) -> String {
        let data = (try? JSONEncoder().encode(string)) ?? Data("\"\"".utf8)
        return String(data: data, encoding: .utf8) ?? "\"\""
    }
}
