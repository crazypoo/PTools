// Network+LegacyCompatibility.swift
// English: Legacy Any/KakaJSON APIs remain a thin compatibility boundary.
// Español: Las API heredadas Any/KakaJSON permanecen como una capa fina de compatibilidad.
// 中文：旧版 Any/KakaJSON API 仅保留为薄兼容层。

import UIKit
@preconcurrency import Alamofire
#if SWIFT_PACKAGE
import PToolsCore
import PToolsModelLegacyKakaJSON
import PToolsNetworkModelCore
#endif

extension Network {
    // KakaJSON metatypes are immutable lookup tokens kept only by the legacy adapter.
    // Los metatipos de KakaJSON son tokens inmutables que conserva únicamente el adaptador heredado.
    // KakaJSON 元类型是不可变查找标记，只由旧版兼容适配器持有。
    private struct PTLegacyModelTypeBox: @unchecked Sendable {
        let value: Any.Type?
    }

    @preconcurrency
    private static func legacyUploadStream(
        source: AsyncThrowingStream<PTNetworkUploadEvent, Error>,
        modelType: Any.Type?
    ) -> AsyncThrowingStream<(progress: Progress, response: PTBaseStructModel<Any>?), Error> {
        let typeBox = PTLegacyModelTypeBox(value: modelType)
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    for try await event in source {
                        let response = try event.response.map {
                            try parseResponse($0, modelType: typeBox.value)
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
    

    
    // MARK: - ================= 7. ⚠️ 动态兼容层：KakaJSON 旧版保留接口 =================
    
    internal static func parseResponse(_ snapshot: PTNetworkResponseSnapshot,
                                       modelType: Any.Type?) throws -> PTBaseStructModel<Any> {
        var (result, jsonString) = try validateAndPreprocessResponse(snapshot) as (PTBaseStructModel<Any>, String)
        if !jsonString.isEmpty, let modelType = modelType {
            do {
                result.customerModel = try PTLegacyKakaJSONAdapter.decode(modelType,
                                                                            data: Data(jsonString.utf8))
            } catch {
                throw PTNetworkError.decode(error.localizedDescription)
            }
        }
        return result
    }
    
    @available(*, deprecated, message: "Use requestPTModel(_:modelType:) with a Sendable model instead")
    public class func requestBodyAPI(needGobal: Bool = true, urlStr: String, body: Data, header: HTTPHeaders? = nil, method: HTTPMethod = .post, cachePolicy: PTNetworkCachePolicy? = nil, modelType: Any.Type? = nil) async throws -> PTBaseStructModel<Any> {
        let snapshot = try await _internalLegacyRequestBodyAPI(needGobal: needGobal,
                                                               urlStr: urlStr,
                                                               body: body,
                                                               header: header,
                                                               method: method,
                                                               cachePolicy: cachePolicy)
        return try parseResponse(snapshot, modelType: modelType)
    }
    
    @available(*, deprecated, message: "Use requestPTModel(_:modelType:) with a Sendable model instead")
    class public func requestApi(needGobal: Bool = true, urlStr: URLConvertible, method: HTTPMethod = .post, header: HTTPHeaders? = nil, parameters: Parameters? = nil,
                                 cachePolicy: PTNetworkCachePolicy? = nil, modelType: Any.Type? = nil, encoder: ParameterEncoding = URLEncoding.default, jsonRequest: Bool = false) async throws -> PTBaseStructModel<Any> {
        let snapshot = try await _internalLegacyRequestApi(needGobal: needGobal,
                                                            urlStr: urlStr,
                                                            method: method,
                                                            header: header,
                                                            parameters: parameters,
                                                            cachePolicy: cachePolicy,
                                                            encoder: encoder,
                                                            jsonRequest: jsonRequest)
        return try parseResponse(snapshot, modelType: modelType)
    }
    
    @available(*, deprecated, message: "Use the Codable upload API with a Sendable model instead")
    class public func fileUpload(needGobal: Bool = true, media: Any, path: URLConvertible, method: HTTPMethod = .post, fileKey: String = "", params: [String: String]? = nil, header: HTTPHeaders? = nil, modelType: Any.Type? = nil, jsonRequest: Bool = false) -> AsyncThrowingStream<(progress: Progress, response: PTBaseStructModel<Any>?), Error> {
        let source = _internalFileUpload(needGobal: needGobal,
                                         media: media,
                                         path: path,
                                         method: method,
                                         fileKey: fileKey,
                                         params: params,
                                         header: header,
                                         jsonRequest: jsonRequest)
        return legacyUploadStream(source: source, modelType: modelType)
    }
    
    @available(*, deprecated, message: "Use imageCodableUpload with a Sendable model instead")
    class public func imageUpload(needGobal: Bool = true, images: [UIImage]?, path: URLConvertible, method: HTTPMethod = .post, fileKey: [String] = ["images"], params: [String: String]? = nil, header: HTTPHeaders? = nil, modelType: Any.Type? = nil, jsonRequest: Bool = false, pngData: Bool = true) -> AsyncThrowingStream<(progress: Progress, response: PTBaseStructModel<Any>?), Error> {
        let source = _internalImageUpload(needGobal: needGobal,
                                          images: images,
                                          path: path,
                                          method: method,
                                          fileKey: fileKey,
                                          params: params,
                                          header: header,
                                          jsonRequest: jsonRequest,
                                          pngData: pngData)
        return legacyUploadStream(source: source, modelType: modelType)
    }
}
