// English: These immutable values are the shared contract for generators, headless clients, and UIKit.
// Español: Estos valores inmutables son el contrato compartido entre generadores, clientes headless y UIKit.
// 中文：这些不可变值类型是生成器、纯数据客户端和 UIKit 之间的共享契约。

import Foundation

public enum PTAcknowledgementSourceManager: String, Codable, CaseIterable, Hashable, Sendable {
    case swiftPM
    case cocoaPods
    case manual
    case binary
    case vendored
}

public enum PTAcknowledgementVerification: String, Codable, CaseIterable, Hashable, Sendable {
    case verified
    case unverified
    case review
    case conflict
}

public struct PTLicenseDocument: Codable, Hashable, Sendable {
    public let fileName: String
    public let text: String
    public let sha256: String

    public init(fileName: String, text: String, sha256: String? = nil) {
        self.fileName = fileName
        self.text = text
        self.sha256 = sha256 ?? PTLicenseHash.sha256(text)
    }

    private enum CodingKeys: String, CodingKey {
        case fileName
        case text
        case sha256
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let fileName = try container.decode(String.self, forKey: .fileName)
        let text = try container.decode(String.self, forKey: .text)
        let sha256 = try container.decodeIfPresent(String.self, forKey: .sha256)
        self.init(fileName: fileName, text: text, sha256: sha256)
    }
}

public struct PTAcknowledgementProvenance: Codable, Hashable, Sendable {
    public let origin: String
    public let resolvedRevision: String?
    public let sourceURL: URL?

    public init(origin: String, resolvedRevision: String? = nil, sourceURL: URL? = nil) {
        self.origin = origin
        self.resolvedRevision = resolvedRevision
        self.sourceURL = sourceURL
    }
}

public struct PTAcknowledgement: Codable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let version: String?
    public let sourceManagers: [PTAcknowledgementSourceManager]
    public let repositoryURL: URL?
    public let websiteURL: URL?
    public let licenseExpression: String?
    public let licenseTexts: [PTLicenseDocument]
    public let notices: [PTLicenseDocument]
    public let provenance: PTAcknowledgementProvenance?
    public let verification: PTAcknowledgementVerification

    public init(
        id: String,
        name: String,
        version: String? = nil,
        sourceManagers: [PTAcknowledgementSourceManager] = [.manual],
        repositoryURL: URL? = nil,
        websiteURL: URL? = nil,
        licenseExpression: String? = nil,
        licenseTexts: [PTLicenseDocument] = [],
        notices: [PTLicenseDocument] = [],
        provenance: PTAcknowledgementProvenance? = nil,
        verification: PTAcknowledgementVerification = .unverified
    ) {
        self.id = id
        self.name = name
        self.version = version
        self.sourceManagers = Array(Set(sourceManagers)).sorted { $0.rawValue < $1.rawValue }
        self.repositoryURL = repositoryURL
        self.websiteURL = websiteURL
        self.licenseExpression = licenseExpression
        self.licenseTexts = licenseTexts
        self.notices = notices
        self.provenance = provenance
        self.verification = verification
    }
}
