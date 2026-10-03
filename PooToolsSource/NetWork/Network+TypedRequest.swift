// Network+TypedRequest.swift
// English: Typed request and Codable upload entry points share the canonical Network executor.
// Español: Las entradas tipadas y las cargas Codable comparten el ejecutor canónico de Network.
// 中文：类型化请求和 Codable 上传入口统一复用 Network 的执行器。

import UIKit
@preconcurrency import Alamofire

extension Network {
    // English: Canonical instance request entry point using the instance's configuration, session, and plugins.
    // Español: Entrada canónica de solicitudes de instancia que usa la configuración, sesión y plugins de la instancia.
    // 中文：实例化请求的统一入口，始终使用实例自己的配置、Session 和插件。
    public func performCodableRequest<T: Codable & Sendable>(
        needGobal: Bool = true,
        urlStr: URLConvertible,
        method: HTTPMethod = .post,
        header: HTTPHeaders? = nil,
        parameters: Parameters? = nil,
        cachePolicy: PTNetworkCachePolicy? = nil,
        modelType: T.Type? = nil,
        encoder: ParameterEncoding = URLEncoding.default,
        jsonRequest: Bool = false) async throws -> PTBaseStructModel<T> {
        let context = try await makeInstanceRequestContext(urlStr: urlStr,
                                                            needGobal: needGobal,
                                                            method: method,
                                                            header: header,
                                                            jsonRequest: jsonRequest,
                                                            cachePolicy: cachePolicy)
        Self.logRequestStart(url: context.url,
                             parameters: parameters,
                             headers: context.headers,
                             method: context.method)
        var urlRequest = try URLRequest(url: context.url,
                                        method: context.method,
                                        headers: context.headers)
        urlRequest = try Self.encodeParameters(parameters,
                                               into: urlRequest,
                                               encoder: encoder,
                                               jsonRequest: jsonRequest)
        let snapshot = try await executeRequest(url: context.url, request: urlRequest)
        return try Self.parseCodableResponse(snapshot, modelType: modelType)
    }
    
    // MARK: - ================= 6. 🌟 强类型解析层：Codable/PTModel 统一接口 =================
    
    internal static func parseCodableResponse<T: Codable & Sendable>(_ snapshot: PTNetworkResponseSnapshot,
                                                                      modelType: T.Type?) throws -> PTBaseStructModel<T> {
        var (result, jsonString) = try validateAndPreprocessResponse(snapshot) as (PTBaseStructModel<T>, String)
        if !jsonString.isEmpty, let modelType = modelType {
            do {
                let model = try PTModelDecoder(policy: .compatible).decode(modelType,
                                                                          from: Data(jsonString.utf8))
                result.customerModel = model
            } catch {
                throw PTNetworkError.decode(error.localizedDescription)
            }
        }
        return result
    }

    internal static func progressValue(from snapshot: PTProgressSnapshot) -> Progress {
        let total = max(snapshot.totalUnitCount, 1)
        let progress = Progress(totalUnitCount: total)
        progress.completedUnitCount = min(max(snapshot.completedUnitCount, 0), total)
        return progress
    }

    private static func codableUploadStream<T: Codable & Sendable>(
        source: AsyncThrowingStream<PTNetworkUploadEvent, Error>,
        modelType: T.Type?
    ) -> AsyncThrowingStream<(progress: Progress, response: PTBaseStructModel<T>?), Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    for try await event in source {
                        let response = try event.response.map {
                            try parseCodableResponse($0, modelType: modelType)
                        }
                        continuation.yield((progressValue(from: event.progress), response))
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    /// 🌟 便捷重载方法：当接口只返回成功/失败时使用，底层自动代劳传入占位模型
    class public func requestCodableApi(needGobal: Bool = true, urlStr: URLConvertible, method: HTTPMethod = .post, header: HTTPHeaders? = nil, parameters: Parameters? = nil, cachePolicy: PTNetworkCachePolicy? = nil, encoder: ParameterEncoding = URLEncoding.default, jsonRequest: Bool = false) async throws -> PTBaseStructModel<PTDummyModel> {
        return try await self.requestCodableApi(needGobal: needGobal, urlStr: urlStr, method: method, header: header, parameters: parameters, cachePolicy: cachePolicy, modelType: PTDummyModel.self, encoder: encoder, jsonRequest: jsonRequest)
    }
    
    /// 核心项目调用总接口
    class public func requestCodableApi<T: Codable & Sendable>(needGobal: Bool = true, urlStr: URLConvertible, method: HTTPMethod = .post, header: HTTPHeaders? = nil, parameters: Parameters? = nil, cachePolicy: PTNetworkCachePolicy? = nil, modelType: T.Type? = nil, encoder: ParameterEncoding = URLEncoding.default, jsonRequest: Bool = false) async throws -> PTBaseStructModel<T> {
        let snapshot = try await _internalRequestApi(needGobal: needGobal,
                                                     urlStr: urlStr,
                                                     method: method,
                                                     header: header,
                                                     parameters: parameters,
                                                     cachePolicy: cachePolicy,
                                                     encoder: encoder,
                                                     jsonRequest: jsonRequest)
        return try parseCodableResponse(snapshot, modelType: modelType)
    }

    /// English: Executes a request and decodes a Sendable model from an explicit JSON path.
    /// Español: Ejecuta una solicitud y decodifica un modelo Sendable desde una ruta JSON explícita.
    /// 中文：执行请求，并从显式 JSON 路径解码 Sendable 模型。
    ///
    /// Root response:
    ///
    /// ```swift
    /// let response = try await Network.requestPTModel(
    ///     urlStr: endpoint,
    ///     modelType: User.self
    /// )
    /// ```
    ///
    /// Wrapped response:
    ///
    /// ```swift
    /// let response = try await Network.requestPTModel(
    ///     urlStr: endpoint,
    ///     modelType: User.self,
    ///     modelPath: "$.data"
    /// )
    /// ```
    ///
    /// `modelPath` never guesses `data`, `result`, or `payload`; `.root` remains the default.
    public class func requestPTModel<T: Decodable & Sendable>(needGobal: Bool = true,
                                                                urlStr: URLConvertible,
                                                                method: HTTPMethod = .post,
                                                                header: HTTPHeaders? = nil,
                                                                parameters: Parameters? = nil,
                                                                cachePolicy: PTNetworkCachePolicy? = nil,
                                                                modelType: T.Type,
                                                                encoder: ParameterEncoding = URLEncoding.default,
                                                                jsonRequest: Bool = false,
                                                                modelPath: PTJSONPath = .root,
                                                                decoder: PTModelDecoder = .init(policy: .compatible)) async throws -> PTModelNetworkResponse<T> {
        let snapshot = try await _internalRequestApi(needGobal: needGobal,
                                                     urlStr: urlStr,
                                                     method: method,
                                                     header: header,
                                                     parameters: parameters,
                                                     cachePolicy: cachePolicy,
                                                     encoder: encoder,
                                                     jsonRequest: jsonRequest)
        let payload = PTNetworkResponsePayload(snapshot: snapshot)
        let model = try PTNetworkResponseDecoder<T>.ptModel(modelType,
                                                             at: modelPath,
                                                             decoder: decoder).decode(payload)
        return PTModelNetworkResponse(payload: payload, model: model)
    }
    
    public class func requestCodableBodyAPI<T: Codable & Sendable>(needGobal: Bool = true, urlStr: String, body: Data, header: HTTPHeaders? = nil, method: HTTPMethod = .post,
                                                                         cachePolicy: PTNetworkCachePolicy? = nil, modelType: T.Type? = nil) async throws -> PTBaseStructModel<T> {
        let snapshot = try await _internalRequestBodyAPI(needGobal: needGobal,
                                                         urlStr: urlStr,
                                                         body: body,
                                                         header: header,
                                                         method: method,
                                                         cachePolicy: cachePolicy)
        return try parseCodableResponse(snapshot, modelType: modelType)
    }
    
    class public func fileCodableUpload<T: Codable & Sendable>(needGobal: Bool = true, media: Any, path: URLConvertible, method: HTTPMethod = .post, fileKey: String = "",
                                                                     params: [String: String]? = nil, header: HTTPHeaders? = nil, modelType: T.Type? = nil, jsonRequest: Bool = false) -> AsyncThrowingStream<(progress: Progress, response: PTBaseStructModel<T>?), Error> {
        let source = _internalFileUpload(needGobal: needGobal,
                                         media: media,
                                         path: path,
                                         method: method,
                                         fileKey: fileKey,
                                         params: params,
                                         header: header,
                                         jsonRequest: jsonRequest)
        return codableUploadStream(source: source, modelType: modelType)
    }
    
    class public func imageCodableUpload<T: Codable & Sendable>(needGobal: Bool = true, images: [UIImage]?, path: URLConvertible, method: HTTPMethod = .post, fileKey: [String] = ["images"], params: [String: String]? = nil, header: HTTPHeaders? = nil, modelType: T.Type? = nil, jsonRequest: Bool = false, pngData: Bool = true) -> AsyncThrowingStream<(progress: Progress, response: PTBaseStructModel<T>?), Error> {
        let source = _internalImageUpload(needGobal: needGobal,
                                          images: images,
                                          path: path,
                                          method: method,
                                          fileKey: fileKey,
                                          params: params,
                                          header: header,
                                          jsonRequest: jsonRequest,
                                          pngData: pngData)
        return codableUploadStream(source: source, modelType: modelType)
    }
}
