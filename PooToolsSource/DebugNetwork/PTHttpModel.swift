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
    var id: String { String(index) }

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
