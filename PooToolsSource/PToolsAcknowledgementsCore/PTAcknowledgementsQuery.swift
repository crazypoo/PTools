// English: Query operations are pure value functions shared by headless and UIKit consumers.
// Español: Las consultas son funciones puras de valores compartidas por consumidores headless y UIKit.
// 中文：查询操作是纯值函数，纯数据和 UIKit 消费者共用同一套逻辑。

import Foundation

public struct PTAcknowledgementsQuery: Hashable, Sendable {
    public var keyword: String?
    public var sourceManagers: Set<PTAcknowledgementSourceManager>
    public var verification: Set<PTAcknowledgementVerification>
    public var licenseExpressions: Set<String>
    public var hasLicenseText: Bool?
    public var includeLicenseText: Bool

    public init(
        keyword: String? = nil,
        sourceManagers: Set<PTAcknowledgementSourceManager> = [],
        verification: Set<PTAcknowledgementVerification> = [],
        licenseExpressions: Set<String> = [],
        hasLicenseText: Bool? = nil,
        includeLicenseText: Bool = false
    ) {
        self.keyword = keyword
        self.sourceManagers = sourceManagers
        self.verification = verification
        self.licenseExpressions = licenseExpressions
        self.hasLicenseText = hasLicenseText
        self.includeLicenseText = includeLicenseText
    }
}

public typealias PTAcknowledgementsFilter = PTAcknowledgementsQuery

public enum PTAcknowledgementsSort: Sendable {
    case nameVersionID
    case versionNameID
    case custom
}

public extension PTLicenseManifest {
    func search(_ keyword: String, includeLicenseText: Bool = false) -> [PTAcknowledgement] {
        let normalized = keyword.ptAcknowledgementSearchKey
        guard !normalized.isEmpty else { return entries }
        return entries.filter { entry in
            var values = [entry.name, entry.version ?? "", entry.licenseExpression ?? "", entry.id]
            values.append(contentsOf: entry.sourceManagers.map(\.rawValue))
            values.append(contentsOf: [entry.repositoryURL?.absoluteString, entry.websiteURL?.absoluteString].compactMap { $0 })
            if includeLicenseText {
                values.append(contentsOf: entry.licenseTexts.map(\.text))
                values.append(contentsOf: entry.notices.map(\.text))
            }
            return values.contains { $0.ptAcknowledgementSearchKey.contains(normalized) }
        }
    }

    func filter(_ query: PTAcknowledgementsQuery) -> [PTAcknowledgement] {
        let candidates: [PTAcknowledgement]
        if let keyword = query.keyword, !keyword.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            candidates = search(keyword, includeLicenseText: query.includeLicenseText)
        } else {
            candidates = entries
        }
        return candidates.filter { entry in
            let sourceMatch = query.sourceManagers.isEmpty || !query.sourceManagers.isDisjoint(with: entry.sourceManagers)
            let verificationMatch = query.verification.isEmpty || query.verification.contains(entry.verification)
            let expressionMatch = query.licenseExpressions.isEmpty || query.licenseExpressions.contains { expression in
                entry.licenseExpression?.caseInsensitiveCompare(expression) == .orderedSame
            }
            let textMatch = query.hasLicenseText.map { $0 == !entry.licenseTexts.isEmpty } ?? true
            return sourceMatch && verificationMatch && expressionMatch && textMatch
        }
    }

    func sorted(by sort: PTAcknowledgementsSort = .nameVersionID) -> [PTAcknowledgement] {
        switch sort {
        case .nameVersionID, .custom:
            return entries.sorted(by: PTLicenseManifest.entrySort)
        case .versionNameID:
            return entries.sorted {
                [$0.version ?? "", $0.name, $0.id].joined(separator: "\u{1F}")
                    .localizedCaseInsensitiveCompare([$1.version ?? "", $1.name, $1.id].joined(separator: "\u{1F}")) == .orderedAscending
            }
        }
    }
}

private extension String {
    var ptAcknowledgementSearchKey: String {
        folding(options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive], locale: Locale(identifier: "en_US_POSIX"))
    }
}
