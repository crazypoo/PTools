// English: Keep request construction and compatibility entry points outside the Network facade.
// Español: Mantiene la construcción de solicitudes y las entradas compatibles fuera de la fachada Network.
// 中文：将请求构造和兼容入口从 Network 门面中独立出来。

import Foundation
@preconcurrency import Alamofire
#if SWIFT_PACKAGE
import ptools
import PToolsCore
import PToolsModelCore
import PToolsNetworkModelCore
#endif

extension Network {
    /// English: Shared immutable context used by typed and legacy request entry points.
    /// Español: Contexto inmutable compartido por las entradas tipadas y heredadas.
    /// 中文：类型化和旧版请求入口共用的不可变上下文。
    internal struct PTNetworkRequestContext {
        let url: String
        let method: HTTPMethod
        let headers: HTTPHeaders
    }

    internal class func makeRequestContext(urlStr: URLConvertible,
                                            needGobal: Bool,
                                            method: HTTPMethod,
                                            header: HTTPHeaders?,
                                            jsonRequest: Bool,
                                            cachePolicy: PTNetworkCachePolicy?) async throws -> PTNetworkRequestContext {
        let url = try await createURLRequest(urlStr: urlStr, needGobal: needGobal)
        let headers = prepareRequestHeaders(header: header,
                                            jsonRequest: jsonRequest,
                                            cachePolicy: cachePolicy)
        return PTNetworkRequestContext(url: url, method: method, headers: headers)
    }

    // English: Build a context from the instance snapshot so custom Network objects do not fall back to the singleton.
    // Español: Construye el contexto desde la instantánea de la instancia para que las redes personalizadas no vuelvan al singleton.
    // 中文：使用实例快照构建请求上下文，避免自定义 Network 实例回退到单例。
    internal func makeInstanceRequestContext(urlStr: URLConvertible,
                                             needGobal: Bool,
                                             method: HTTPMethod,
                                             header: HTTPHeaders?,
                                             jsonRequest: Bool,
                                             cachePolicy: PTNetworkCachePolicy?) async throws -> PTNetworkRequestContext {
        let originalURL = try urlStr.asURL().absoluteString
        let configuration = config
        let environment = PTNetworkRequestEnvironment(configuration: configuration)
        let url: String
        if let endpointResolver {
            url = try await endpointResolver.resolve(endpoint: originalURL, environment: environment).absoluteString
        } else if originalURL.hasPrefix("http") || !needGobal {
            url = originalURL
        } else {
            url = environment.serverAddress + originalURL
        }
        var headers = Self.prepareRequestHeaders(header: header,
                                                  jsonRequest: jsonRequest,
                                                  cachePolicy: cachePolicy,
                                                  configuration: configuration)
        if let headerProvider {
            let dynamicHeaders = await headerProvider.headers()
            for (key, value) in dynamicHeaders where headers[key] == nil {
                headers[key] = value
            }
        }
        if let credentialProvider,
           headers["token"] == nil,
           let credential = await credentialProvider.credential(),
           !credential.isEmpty {
            headers["token"] = credential
            headers["device"] = "iOS"
        }
        return PTNetworkRequestContext(url: url, method: method, headers: headers)
    }

    /// English: Encode parameters exactly once before the request reaches the shared executor.
    /// Español: Codifica los parámetros una sola vez antes de llegar al ejecutor compartido.
    /// 中文：在请求进入统一执行器前只编码一次参数。
    internal class func encodeParameters(_ parameters: Parameters?,
                                         into request: URLRequest,
                                         encoder: ParameterEncoding,
                                         jsonRequest: Bool) throws -> URLRequest {
        guard let parameters, !parameters.isEmpty else { return request }

        // English: JSON headers take precedence so parameters are not silently omitted from the body.
        // Español: Los encabezados JSON tienen prioridad para que los parámetros no desaparezcan del cuerpo.
        // 中文：JSON 请求头优先，避免参数被静默遗漏在请求体之外。
        let contentType = request.value(forHTTPHeaderField: "Content-Type")?.lowercased() ?? ""
        let shouldEncodeAsJSON = jsonRequest || contentType.contains("application/json")
        let effectiveEncoder: ParameterEncoding = shouldEncodeAsJSON ? JSONEncoding.default : encoder
        return try effectiveEncoder.encode(request, with: parameters)
    }

    public typealias UploadResponseParser<T> = @Sendable (String, HTTPURLResponse?, Data?) throws -> PTBaseStructModel<T>

    internal class func _internalRequestApi(needGobal: Bool,
                                           urlStr: URLConvertible,
                                           method: HTTPMethod,
                                           header: HTTPHeaders?,
                                           parameters: Parameters?,
                                           cachePolicy: PTNetworkCachePolicy?,
                                           encoder: ParameterEncoding,
                                           jsonRequest: Bool) async throws -> PTNetworkResponseSnapshot {
        let context = try await makeRequestContext(urlStr: urlStr,
                                                   needGobal: needGobal,
                                                   method: method,
                                                   header: header,
                                                   jsonRequest: jsonRequest,
                                                   cachePolicy: cachePolicy)
        logRequestStart(url: context.url, parameters: parameters, headers: context.headers, method: context.method)

        var urlRequest = try URLRequest(url: context.url, method: context.method, headers: context.headers)
        urlRequest = try encodeParameters(parameters,
                                          into: urlRequest,
                                          encoder: encoder,
                                          jsonRequest: jsonRequest)
        return try await execute(url: context.url, request: urlRequest)
    }

    internal class func _internalRequestBodyAPI(needGobal: Bool,
                                               urlStr: String,
                                               body: Data,
                                               header: HTTPHeaders?,
                                               method: HTTPMethod,
                                               cachePolicy: PTNetworkCachePolicy?) async throws -> PTNetworkResponseSnapshot {
        let context = try await makeRequestContext(urlStr: urlStr,
                                                   needGobal: needGobal,
                                                   method: method,
                                                   header: header,
                                                   jsonRequest: false,
                                                   cachePolicy: cachePolicy)
        var newHeader = context.headers
        if newHeader["Content-Type"] == nil { newHeader["Content-Type"] = "text/plain" }

        var dictionary: [String: any Any & Sendable] = [:]
        if let jsonObject = try? JSONSerialization.jsonObject(with: body, options: []),
           let jsonDictionary = jsonObject as? [String: any Any & Sendable] {
            dictionary = jsonDictionary
        }
        logRequestStart(url: context.url, parameters: dictionary, headers: newHeader, method: context.method)

        var urlRequest = try URLRequest(url: context.url, method: context.method, headers: newHeader)
        urlRequest.httpBody = body
        return try await execute(url: context.url, request: urlRequest, uploadBody: body)
    }

    internal class func _internalLegacyRequestApi(needGobal: Bool,
                                                 urlStr: URLConvertible,
                                                 method: HTTPMethod,
                                                 header: HTTPHeaders?,
                                                 parameters: Parameters?,
                                                 cachePolicy: PTNetworkCachePolicy?,
                                                 encoder: ParameterEncoding,
                                                 jsonRequest: Bool) async throws -> PTNetworkResponseSnapshot {
        let context = try await makeRequestContext(urlStr: urlStr,
                                                   needGobal: needGobal,
                                                   method: method,
                                                   header: header,
                                                   jsonRequest: jsonRequest,
                                                   cachePolicy: cachePolicy)
        logRequestStart(url: context.url, parameters: parameters, headers: context.headers, method: context.method)
        var urlRequest = try URLRequest(url: context.url, method: context.method, headers: context.headers)
        urlRequest = try encodeParameters(parameters,
                                          into: urlRequest,
                                          encoder: encoder,
                                          jsonRequest: jsonRequest)
        return try await executeLegacy(url: context.url, request: urlRequest)
    }

    internal class func _internalLegacyRequestBodyAPI(needGobal: Bool,
                                                     urlStr: String,
                                                     body: Data,
                                                     header: HTTPHeaders?,
                                                     method: HTTPMethod,
                                                     cachePolicy: PTNetworkCachePolicy?) async throws -> PTNetworkResponseSnapshot {
        let context = try await makeRequestContext(urlStr: urlStr,
                                                   needGobal: needGobal,
                                                   method: method,
                                                   header: header,
                                                   jsonRequest: false,
                                                   cachePolicy: cachePolicy)
        var newHeader = context.headers
        if newHeader["Content-Type"] == nil { newHeader["Content-Type"] = "text/plain" }
        var dictionary: [String: any Any & Sendable] = [:]
        if let jsonObject = try? JSONSerialization.jsonObject(with: body, options: []),
           let jsonDictionary = jsonObject as? [String: any Any & Sendable] {
            dictionary = jsonDictionary
        }
        logRequestStart(url: context.url, parameters: dictionary, headers: newHeader, method: context.method)
        var urlRequest = try URLRequest(url: context.url, method: context.method, headers: newHeader)
        urlRequest.httpBody = body
        return try await executeLegacy(url: context.url, request: urlRequest, uploadBody: body)
    }
}
