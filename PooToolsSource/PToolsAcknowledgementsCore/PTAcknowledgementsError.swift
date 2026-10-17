// English: Public errors distinguish missing data from an intentionally empty dependency set.
// Español: Los errores públicos distinguen los datos ausentes de un conjunto de dependencias vacío intencionalmente.
// 中文：公开错误类型区分缺少数据和确实为空的依赖集合。

import Foundation

public enum PTAcknowledgementsError: Error, Equatable, Sendable, LocalizedError {
    case missingManifest
    case unreadableManifest
    case invalidJSON
    case unsupportedSchema(actual: Int)
    case integrityMismatch(id: String)
    case entryNotFound(id: String)
    case licenseTextUnavailable(id: String)
    case duplicateIdentity(id: String)
    case licenseConflict(id: String)
    case invalidEntry(id: String)
    case invalidURL
    case unsafeExportValue
    case exportFailure(format: String)
    case invalidConfiguration

    public var errorDescription: String? {
        switch self {
        case .missingManifest:
            return "未找到 PTAcknowledgements.json。请先配置一次构建期生成步骤。"
        case .unreadableManifest:
            return "无法读取第三方依赖致谢文件。"
        case .invalidJSON:
            return "第三方依赖致谢文件不是有效 JSON。"
        case let .unsupportedSchema(actual):
            return "不支持的 PTAcknowledgements schema: \(actual)。"
        case let .integrityMismatch(id):
            return "许可证原文完整性校验失败: \(id)。"
        case let .entryNotFound(id):
            return "找不到依赖条目: \(id)。"
        case let .licenseTextUnavailable(id):
            return "依赖没有可用的完整许可证原文: \(id)。"
        case let .duplicateIdentity(id):
            return "依赖清单存在重复身份: \(id)。"
        case let .licenseConflict(id):
            return "同一依赖的许可证原文存在冲突: \(id)。"
        case let .invalidEntry(id):
            return "依赖条目无效: \(id)。"
        case .invalidURL:
            return "依赖清单包含无效或不安全的 URL。"
        case .unsafeExportValue:
            return "导出内容包含不安全的控制字符或 CSV 公式。"
        case let .exportFailure(format):
            return "导出 \(format) 失败。"
        case .invalidConfiguration:
            return "致谢生成器配置无效。"
        }
    }
}

public enum PTAcknowledgementsIssueSeverity: String, Codable, Sendable {
    case warning
    case error
    case review
}

public struct PTAcknowledgementsValidationIssue: Codable, Equatable, Sendable {
    public let severity: PTAcknowledgementsIssueSeverity
    public let code: String
    public let message: String
    public let entryID: String?

    public init(
        severity: PTAcknowledgementsIssueSeverity,
        code: String,
        message: String,
        entryID: String? = nil
    ) {
        self.severity = severity
        self.code = code
        self.message = message
        self.entryID = entryID
    }
}
