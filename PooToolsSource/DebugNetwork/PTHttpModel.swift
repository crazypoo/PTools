//
//  PTHttpModel.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/5/27.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import Foundation

// 请求序列化格式
enum RequestSerializer: UInt {
    case json = 0
    case form
}

final class PTHttpModel: NSObject {
    var url: URL?
    var requestData: Data?
    var responseData: Data?
    var requestId: String?
    var method: String?
    var statusCode: String?
    
    // 🌟 修正为标准术语 mimeType
    var mimeType: String?
    
    // 🌟 过渡期无缝兼容方案：保留 mineType 供现有业务代码访问，底层映射至 mimeType
    @available(*, deprecated, renamed: "mimeType", message: "请使用标准的 mimeType 命名")
    var mineType: String? {
        get { mimeType }
        set { mimeType = newValue }
    }
    
    var startTime: String?
    var endTime: String?
    var totalDuration: String?
    var isImage = false

    var requestHeaderFields: [String: Any]?
    var responseHeaderFields: [String: Any]?
    var isTag = false
    var isSelected = false
    var requestSerializer: RequestSerializer = .json
    var errorDescription: String?
    var errorLocalizedDescription: String?
    var size: String?
    var index: Int = .zero
    var id: String { requestId ?? String(index) }
    // English: Keep diagnostic metrics only at the legacy detail boundary.
    // Español: Conserva las métricas de diagnóstico solo en el límite de detalle heredado.
    // 中文：仅在旧详情页边界保留诊断指标。
    var networkMetrics: PTNetworkTaskMetricsSnapshot?

    override init() {
        super.init()
        self.statusCode = "0"
        self.url = URL(string: "")
    }

    // 🌟 终极加固：结合底层网络错误与 HTTP 状态码的双重判定
    var isSuccess: Bool {
        // 1. 确保无底层网络层面的错误描述
        let hasNoError = (errorDescription == nil || errorDescription?.isEmpty == true)
        
        // 2. 解析状态码
        let codeInt = Int(statusCode ?? "0") ?? 0
        
        // 业务成功判定：
        // - 0 代表未经过远端服务器的本地直连或特殊构造响应
        // - 200..<400 代表合规的成功响应与正常的业务重定向
        let isStatusCodeValid = (codeInt == 0 || (codeInt >= 200 && codeInt < 400))
        
        return hasNoError && isStatusCodeValid
    }
}

// English: Convert the immutable capture record only at the legacy UI boundary.
// Español: Convierte el registro inmutable únicamente en el límite de la UI heredada.
// 中文：只在旧 UI 兼容边界把不可变抓包记录转换为旧模型。
extension PTHttpModel {
    convenience init(record: PTNetworkCaptureRecord) {
        self.init()
        requestId = record.id.uuidString
        index = Int(clamping: record.sequence)
        url = record.request.url
        method = record.request.method
        requestData = record.request.body.previewData
        requestHeaderFields = record.request.headers
        statusCode = record.response.map { String($0.statusCode) }
        mimeType = record.response?.mimeType
        responseData = record.response?.body.previewData
        responseHeaderFields = record.response?.headers
        startTime = ISO8601DateFormatter().string(from: record.timing.startedAt)
        endTime = record.timing.endedAt.map { ISO8601DateFormatter().string(from: $0) }
        totalDuration = record.timing.duration.map { String(format: "%.4f (s)", $0) }
        size = ByteCountFormatter.string(fromByteCount: record.response?.body.totalBytes ?? 0, countStyle: .file)
        errorDescription = record.error?.description
        errorLocalizedDescription = record.error?.description
        isImage = record.response?.mimeType?.localizedCaseInsensitiveContains("image") == true
        networkMetrics = record.metrics
    }
}
