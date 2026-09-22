//
//  Network+Logging.swift
//  PooTools
//
// English: Keep request logging and response snapshots independent from the Network facade.
// Español: Mantiene los registros de solicitudes y las instantáneas de respuesta independientes de la fachada Network.
// 中文：将请求日志和响应快照从 Network 门面中独立出来。
//

import Foundation
import UIKit
@preconcurrency import Alamofire
#if canImport(PToolsLogging)
import PToolsLogging
#endif

extension Network {
    static func logRequestStart(url: String, parameters: Parameters?, headers: HTTPHeaders, method: HTTPMethod) {
        let paramsStr = requestParametersForLog(parameters)
        let safeHeaders = redactedHeaders(headers.dictionary)
        PTNSLogConsole("🌐❤️1.请求地址 = \(url)\n💛2.参数 = \(paramsStr)\n💙3.请求头 = \(safeHeaders)\n🩷4.请求类型 = \(method.rawValue)🌐", levelType: PTLogMode, loggerType: .network)
    }

    // English: Redact request and response headers before they become a free-form log message.
    // Español: Oculta las cabeceras de solicitud y respuesta antes de convertirlas en un mensaje libre.
    // 中文：在请求头和响应头进入自由文本日志前先进行脱敏。
    static func redactedHeaders(_ headers: [String: String]) -> [String: String] {
        headers.reduce(into: [String: String]()) { result, item in
            result[item.key] = isSensitiveHeader(item.key)
                ? "[REDACTED]"
                : String(item.value.prefix(2_048))
        }
    }

    static func isSensitiveHeader(_ key: String) -> Bool {
        let normalized = key.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return normalized == "authorization"
            || normalized == "proxy-authorization"
            || normalized == "cookie"
            || normalized == "set-cookie"
            || normalized.contains("token")
            || normalized.contains("secret")
            || normalized.contains("password")
    }

    private static func requestParametersForLog(_ parameters: Parameters?) -> String {
        guard let parameters, !parameters.isEmpty else { return "没有参数" }
        if isAppStoreEnvironment {
            return "已隐藏（参数数量：\(parameters.count)）"
        }
        return sanitizedParameters(parameters)
    }

    private static func sanitizedParameters(_ parameters: Parameters?) -> String {
        guard let parameters, !parameters.isEmpty else { return "没有参数" }
        let sanitized = parameters.reduce(into: [String: String]()) { result, item in
            result[item.key] = isSensitiveHeader(item.key)
                ? "[REDACTED]"
                : String(describing: item.value).prefix(2_048).description
        }
        return String(describing: sanitized)
    }

    static func logRequestSuccess(url: String, jsonStr: String) {
        let printStr: String
        if jsonStr.isEmpty {
            printStr = "数据为空或响应内容不可解析"
        } else if shouldLogResponseDetails {
            printStr = String(jsonStr.prefix(16_384))
        } else {
            printStr = "已隐藏（响应长度：\(jsonStr.utf8.count) bytes）"
        }
        PTNSLogConsole("🌐接口请求成功回调🌐\n❤️1.请求地址 = \(url)\n💛2.result:\(printStr)🌐", levelType: PTLogMode, loggerType: .network)
    }

    static func logRequestFailure(url: String, error: AFError) {
        PTNSLogConsole("❌接口:\(url)\n🎈----------------------出现错误----------------------🎈\(String(describing: error.errorDescription))❌", levelType: .error, loggerType: .network)
    }

    static func addToken(to headers: HTTPHeaders,
                         configuration: PTNetworkConfig? = nil) -> HTTPHeaders {
        var headers = headers
        let token = (configuration ?? Network.share.config).userToken
        if !token.isEmpty {
            headers["token"] = token
            headers["device"] = "iOS"
        }
        return headers
    }

    static func isJSONResponse(_ metadata: PTResponseMetadata) -> Bool {
        let contentType = metadata.headers.first { key, _ in
            key.caseInsensitiveCompare("Content-Type") == .orderedSame
        }?.value.lowercased() ?? ""
        return contentType.contains("application/json") || contentType.contains("text/json")
    }

    static func responseSnapshot(url: String,
                                response: HTTPURLResponse?,
                                data: Data?) -> PTNetworkResponseSnapshot {
        var headers = [String: String](minimumCapacity: response?.allHeaderFields.count ?? 0)
        response?.allHeaderFields.forEach { key, value in
            headers[String(describing: key)] = String(describing: value)
        }
        let metadata = PTResponseMetadata(statusCode: response?.statusCode,
                                          headers: headers)
        return PTNetworkResponseSnapshot(url: url, data: data, metadata: metadata)
    }

    /// English: Pretty-print only bounded response data for diagnostics.
    /// Español: Formatea solo una cantidad limitada de datos de respuesta para diagnóstico.
    /// 中文：仅对有大小上限的响应数据进行格式化，避免诊断日志制造峰值。
    static func prettyPrintedJSONString(from data: Data) -> String {
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
            let prettyData = try JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted, .withoutEscapingSlashes])
            return String(data: prettyData, encoding: .utf8) ?? ""
        } catch {
            return String(data: data, encoding: .utf8) ?? ""
        }
    }
}
