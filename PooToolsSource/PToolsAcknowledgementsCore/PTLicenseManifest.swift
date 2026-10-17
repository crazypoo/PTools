// English: The manifest is immutable, deterministic, and validates its public data at construction time.
// Español: El manifest es inmutable, determinista y valida sus datos públicos al construirse.
// 中文：Manifest 不可变、可确定复现，并在创建时校验公开数据。

import Foundation

public enum PTAcknowledgementsMergePolicy: String, Codable, Sendable {
    case errorOnConflict
    case preferFirst
    case preferLast
}

public struct PTLicenseManifest: Codable, Hashable, Sendable {
    public static let supportedSchemaVersion = 1
    public let schemaVersion: Int
    public let generatorVersion: String?
    public let generatedAt: String?
    public let appTarget: String?
    public let entries: [PTAcknowledgement]

    public init(
        schemaVersion: Int = PTLicenseManifest.supportedSchemaVersion,
        generatorVersion: String? = nil,
        generatedAt: String? = nil,
        appTarget: String? = nil,
        entries: [PTAcknowledgement]
    ) throws {
        guard schemaVersion == Self.supportedSchemaVersion else {
            throw PTAcknowledgementsError.unsupportedSchema(actual: schemaVersion)
        }
        let sortedEntries = entries.sorted(by: Self.entrySort)
        try Self.validateEntries(sortedEntries)
        self.schemaVersion = schemaVersion
        self.generatorVersion = generatorVersion
        self.generatedAt = generatedAt
        self.appTarget = appTarget
        self.entries = sortedEntries
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let schemaVersion = try container.decodeIfPresent(Int.self, forKey: .schemaVersion) ?? 1
        let generatorVersion = try container.decodeIfPresent(String.self, forKey: .generatorVersion)
        let generatedAt = try container.decodeIfPresent(String.self, forKey: .generatedAt)
        let appTarget = try container.decodeIfPresent(String.self, forKey: .appTarget)
        let entries = try container.decode([PTAcknowledgement].self, forKey: .entries)
        try self.init(
            schemaVersion: schemaVersion,
            generatorVersion: generatorVersion,
            generatedAt: generatedAt,
            appTarget: appTarget,
            entries: entries
        )
    }

    public func entry(id: String) -> PTAcknowledgement? {
        entries.first { $0.id == id }
    }

    public func licenseDocuments(for id: String) throws -> [PTLicenseDocument] {
        guard let entry = entry(id: id) else {
            throw PTAcknowledgementsError.entryNotFound(id: id)
        }
        guard !entry.licenseTexts.isEmpty else {
            throw PTAcknowledgementsError.licenseTextUnavailable(id: id)
        }
        return entry.licenseTexts
    }

    public func licenseText(for id: String, fileName: String? = nil) throws -> String {
        let documents = try licenseDocuments(for: id)
        if let fileName {
            guard let document = documents.first(where: { $0.fileName == fileName }) else {
                throw PTAcknowledgementsError.licenseTextUnavailable(id: id)
            }
            return document.text
        }
        guard documents.count == 1 else {
            throw PTAcknowledgementsError.licenseTextUnavailable(id: id)
        }
        return documents[0].text
    }

    public func merging(
        _ other: PTLicenseManifest,
        policy: PTAcknowledgementsMergePolicy = .errorOnConflict
    ) throws -> PTLicenseManifest {
        var result = Dictionary(uniqueKeysWithValues: entries.map { ($0.id, $0) })
        for incoming in other.entries {
            guard let existing = result[incoming.id] else {
                result[incoming.id] = incoming
                continue
            }
            if existing == incoming { continue }
            switch policy {
            case .errorOnConflict:
                throw existing.licenseTexts.map(\.sha256) == incoming.licenseTexts.map(\.sha256)
                    ? PTAcknowledgementsError.duplicateIdentity(id: incoming.id)
                    : PTAcknowledgementsError.licenseConflict(id: incoming.id)
            case .preferFirst:
                continue
            case .preferLast:
                result[incoming.id] = incoming
            }
        }
        return try PTLicenseManifest(
            schemaVersion: schemaVersion,
            generatorVersion: generatorVersion ?? other.generatorVersion,
            generatedAt: generatedAt,
            appTarget: appTarget ?? other.appTarget,
            entries: Array(result.values)
        )
    }

    public func validationIssues() -> [PTAcknowledgementsValidationIssue] {
        var issues: [PTAcknowledgementsValidationIssue] = []
        for entry in entries {
            if entry.licenseTexts.isEmpty {
                issues.append(.init(
                    severity: .warning,
                    code: "missing-license-text",
                    message: "未找到完整许可证原文，需要人工补齐。",
                    entryID: entry.id
                ))
            }
            if entry.verification != .verified {
                issues.append(.init(
                    severity: entry.verification == .conflict ? .error : .review,
                    code: "verification-\(entry.verification.rawValue)",
                    message: "许可证来源尚未完成自动核验。",
                    entryID: entry.id
                ))
            }
            for document in entry.licenseTexts + entry.notices {
                if document.sha256 != PTLicenseHash.sha256(document.text) {
                    issues.append(.init(
                        severity: .error,
                        code: "integrity-mismatch",
                        message: "许可证文本 SHA256 与内容不一致。",
                        entryID: entry.id
                    ))
                }
            }
        }
        return issues
    }

    private enum CodingKeys: String, CodingKey {
        case schemaVersion
        case generatorVersion
        case generatedAt
        case appTarget
        case entries
    }

    static func entrySort(_ lhs: PTAcknowledgement, _ rhs: PTAcknowledgement) -> Bool {
        let left = [lhs.name, lhs.version ?? "", lhs.id].joined(separator: "\u{1F}")
        let right = [rhs.name, rhs.version ?? "", rhs.id].joined(separator: "\u{1F}")
        return left.folding(options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive], locale: Locale(identifier: "en_US_POSIX"))
            < right.folding(options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive], locale: Locale(identifier: "en_US_POSIX"))
    }

    private static func validateEntries(_ entries: [PTAcknowledgement]) throws {
        var ids = Set<String>()
        for entry in entries {
            let id = entry.id.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !id.isEmpty, !entry.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw PTAcknowledgementsError.invalidEntry(id: entry.id)
            }
            guard ids.insert(id).inserted else {
                throw PTAcknowledgementsError.duplicateIdentity(id: id)
            }
            guard entry.licenseTexts.allSatisfy({ !$0.fileName.isEmpty && !$0.text.isEmpty }) else {
                throw PTAcknowledgementsError.invalidEntry(id: id)
            }
            guard entry.notices.allSatisfy({ !$0.fileName.isEmpty && !$0.text.isEmpty }) else {
                throw PTAcknowledgementsError.invalidEntry(id: id)
            }
            for url in [entry.repositoryURL, entry.websiteURL, entry.provenance?.sourceURL].compactMap({ $0 }) {
                guard url.scheme?.lowercased() == "https" else {
                    throw PTAcknowledgementsError.invalidURL
                }
            }
        }
    }
}
