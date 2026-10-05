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
    private var isInvalidated = false
    private var bootstrapInstalled = false

    public init(webView: WKWebView,
                policy: PTWebSecurityPolicy = .init()) {
        self.webView = webView
        self.policy = policy
        super.init()
        webView.configuration.userContentController.addScriptMessageHandler(self,
                                                                             contentWorld: .page,
                                                                             name: Self.messageName)
    }

    public func installBootstrap(methods: Set<String> = []) {
        guard !isInvalidated, !bootstrapInstalled else { return }
        let script = PTWebScriptBootstrap(methods: methods).source()
        webView?.configuration.userContentController.addUserScript(
            WKUserScript(source: script, injectionTime: .atDocumentStart, forMainFrameOnly: policy.mainFrameOnly)
        )
        bootstrapInstalled = true
    }

    public func register(method: PTWebMethod, handler: @escaping PTWebHandler) {
        guard !isInvalidated else { return }
        handlers[method.name] = handler
    }

    public func unregister(method: PTWebMethod) { handlers[method.name] = nil }

    public func allowsNavigation(to url: URL) -> Bool {
        guard let scheme = url.scheme?.lowercased() else { return false }
        guard policy.allowedNavigationSchemes.contains(scheme) else { return false }
        guard !policy.allowedOrigins.isEmpty else { return true }
        guard let host = url.host else { return false }
        let port = url.port.map { ":\($0)" } ?? ""
        return policy.allowedOrigins.contains("\(scheme)://\(host)\(port)")
    }

    public func invalidate() {
        guard !isInvalidated else { return }
        isInvalidated = true
        handlers.removeAll()
        guard let webView else {
            self.webView = nil
            return
        }
        let controller = webView.configuration.userContentController
        controller.removeScriptMessageHandler(forName: Self.messageName, contentWorld: .page)
        self.webView = nil
    }

    public func callJavaScript(method: PTWebMethod, payload: Data = Data()) async throws -> Data {
        guard !isInvalidated else { throw PTWebBridgeError.unavailable }
        guard let webView else { throw PTWebBridgeError.unavailable }
        guard payload.count <= policy.maxPayloadBytes else { throw PTWebBridgeError.payloadTooLarge }
        let script = "window.PToolsBridge && window.PToolsBridge[\(jsonLiteral(method.name))](\(jsonLiteral(payload.base64EncodedString())))"
        let value = try await webView.evaluateJavaScript(script, in: nil, contentWorld: .page)
        if let dictionary = value as? [String: Any],
           let encodedPayload = dictionary["payload"] as? String,
           let data = Data(base64Encoded: encodedPayload) {
            return data
        }
        if let value = value as? String, let data = Data(base64Encoded: value) {
            return data
        }
        if let value = value as? [String: Any], JSONSerialization.isValidJSONObject(value) {
            return try JSONSerialization.data(withJSONObject: value)
        }
        return Data()
    }

    // English: Codable JavaScript calls avoid leaking dynamic dictionaries across the WebKit boundary.
    // Español: Las llamadas JavaScript Codable evitan pasar diccionarios dinámicos por el límite de WebKit.
    // 中文：Codable JavaScript 调用避免动态字典跨越 WebKit 边界。
    public func callAsyncJavaScript<Arguments: Encodable & Sendable,
                                    Response: Decodable & Sendable>(function: String,
                                                                      arguments: Arguments,
                                                                      as type: Response.Type) async throws -> Response {
        guard !isInvalidated else { throw PTWebBridgeError.unavailable }
        guard let webView else { throw PTWebBridgeError.unavailable }
        let encodedArguments = try JSONEncoder().encode(arguments)
        let object = try JSONSerialization.jsonObject(with: encodedArguments)
        let value = try await webView.callAsyncJavaScript("return (\(function))(argumentsValue);",
                                                           arguments: ["argumentsValue": object],
                                                           in: nil,
                                                           contentWorld: .page)
        let data: Data
        if let value = value as? String {
            data = try JSONEncoder().encode(value)
        } else if value == nil {
            data = Data("null".utf8)
        } else if let object = value, JSONSerialization.isValidJSONObject(object) {
            data = try JSONSerialization.data(withJSONObject: object)
        } else if let value = value as? NSNumber {
            data = try JSONSerialization.data(withJSONObject: value)
        } else {
            throw PTWebBridgeError.invalidPayload
        }
        return try JSONDecoder().decode(type, from: data)
    }

    public func userContentController(_ userContentController: WKUserContentController,
                                      didReceive message: WKScriptMessage,
                                      replyHandler: @escaping @MainActor @Sendable (Any?, String?) -> Void) {
        guard message.name == Self.messageName,
              !isInvalidated,
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
        let port = origin.port > 0 ? ":\(origin.port)" : ""
        let originValue = "\(origin.protocol)://\(origin.host)\(port)"
        if !policy.allowedOrigins.isEmpty, !policy.allowedOrigins.contains(originValue) {
            replyHandler(nil, String(describing: PTWebBridgeError.originNotAllowed))
            return
        }
        let payload: Data
        if let base64 = dictionary["payload"] as? String { payload = Data(base64Encoded: base64) ?? Data() }
        else { payload = Data() }
        guard payload.count <= policy.maxPayloadBytes else {
            replyHandler(nil, String(describing: PTWebBridgeError.payloadTooLarge))
            return
        }
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
        guard policy.legacyPromptEnabled else { throw PTWebBridgeError.legacyPromptDisabled }
        guard payload.count <= policy.maxPayloadBytes else { throw PTWebBridgeError.payloadTooLarge }
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
