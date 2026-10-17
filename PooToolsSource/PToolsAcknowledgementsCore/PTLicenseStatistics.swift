// English: Statistics are plain values so custom dashboards do not depend on the UIKit module.
// Español: Las estadísticas son valores simples para que los dashboards no dependan de UIKit.
// 中文：统计结果是纯值类型，自定义仪表盘无需依赖 UIKit。

import Foundation

public struct PTLicenseStatistics: Codable, Hashable, Sendable {
    public let totalDependencies: Int
    public let sourceManagerCounts: [String: Int]
    public let verificationCounts: [String: Int]
    public let licenseExpressionCounts: [String: Int]
    public let missingLicenseCount: Int
    public let conflictCount: Int
    public let reviewCount: Int

    public init(
        totalDependencies: Int,
        sourceManagerCounts: [String: Int],
        verificationCounts: [String: Int],
        licenseExpressionCounts: [String: Int],
        missingLicenseCount: Int,
        conflictCount: Int,
        reviewCount: Int
    ) {
        self.totalDependencies = totalDependencies
        self.sourceManagerCounts = sourceManagerCounts
        self.verificationCounts = verificationCounts
        self.licenseExpressionCounts = licenseExpressionCounts
        self.missingLicenseCount = missingLicenseCount
        self.conflictCount = conflictCount
        self.reviewCount = reviewCount
    }
}

public extension PTLicenseManifest {
    func statistics() -> PTLicenseStatistics {
        var sourceCounts: [String: Int] = [:]
        var verificationCounts: [String: Int] = [:]
        var licenseCounts: [String: Int] = [:]
        for entry in entries {
            for source in entry.sourceManagers {
                sourceCounts[source.rawValue, default: 0] += 1
            }
            verificationCounts[entry.verification.rawValue, default: 0] += 1
            licenseCounts[entry.licenseExpression ?? "UNKNOWN", default: 0] += 1
        }
        return PTLicenseStatistics(
            totalDependencies: entries.count,
            sourceManagerCounts: sourceCounts,
            verificationCounts: verificationCounts,
            licenseExpressionCounts: licenseCounts,
            missingLicenseCount: entries.filter { $0.licenseTexts.isEmpty }.count,
            conflictCount: entries.filter { $0.verification == .conflict }.count,
            reviewCount: entries.filter { $0.verification == .review }.count
        )
    }
}
