//
//  PTErrorHelper.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/5/27.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import Foundation

enum PTErrorHelper {
    
    /// 根据底层抛出的 Error 与最终的 HTTP 状态码，为数据模型清洗并填充准确的错误描述
    static func handle(_ error: Error?, model: PTHttpModel) -> PTHttpModel {
        // 1. 优先捕获并应用底层传输层/网络层的系统级异常（如无网络连接、请求超时、SSL 证书无效等）
        if let error = error {
            model.errorDescription = error.localizedDescription
            model.errorLocalizedDescription = error.localizedDescription
            return model
        }

        // 2. 无底层 Error 时，依据标准 HTTP 响应状态码过滤业务层级异常
        if let codeString = model.statusCode, let statusCode = Int(codeString) {
            // 标准 HTTP 协议中，4xx 代表客户端参数/权限异常，5xx 代表远端服务器内部故障
            if statusCode >= 400 {
                // 🌟 原生黑魔法：利用系统内置支持动态提取多语言语义，省去数百行 switch-case 模板代码
                let standardReason = HTTPURLResponse.localizedString(forStatusCode: statusCode).capitalized
                model.errorDescription = "HTTP \(statusCode): \(standardReason)"
                model.errorLocalizedDescription = standardReason
            } else {
                // 确保 2xx 与 3xx 阶段数据状态纯净，配合模型层驱动正确的绿色标识
                model.errorDescription = nil
                model.errorLocalizedDescription = nil
            }
        }

        return model
    }
}
