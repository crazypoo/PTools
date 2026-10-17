// English: Exporters preserve license text while keeping metadata deterministic and safe for user output.
// Español: Los exportadores conservan el texto legal y mantienen los metadatos deterministas y seguros.
// 中文：导出器保留许可证原文，同时让元数据确定性且适合安全展示。

import Foundation

public enum PTAcknowledgementsExportFormat: Sendable {
    case json
    case text
    case noticeText
    case csv
}

public extension PTLicenseManifest {
    func export(_ format: PTAcknowledgementsExportFormat) throws -> Data {
        switch format {
        case .json:
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            return try encoder.encode(self)
        case .text:
            return Data(try exportText(includeNotices: false).utf8)
        case .noticeText:
            return Data(try exportText(includeNotices: true).utf8)
        case .csv:
            return Data(try exportCSV().utf8)
        }
    }

    private func exportText(includeNotices: Bool) throws -> String {
        var output: [String] = []
        for entry in sorted() {
            output.append("===== \(entry.name)\(entry.version.map { " \($0)" } ?? "") =====")
            output.append("ID: \(entry.id)")
            output.append("License: \(entry.licenseExpression ?? "UNKNOWN")")
            for document in entry.licenseTexts {
                output.append("--- \(document.fileName) ---")
                output.append(document.text)
            }
            if includeNotices {
                for document in entry.notices {
                    output.append("--- NOTICE: \(document.fileName) ---")
                    output.append(document.text)
                }
            }
            output.append("")
        }
        return output.joined(separator: "\n")
    }

    private func exportCSV() throws -> String {
        var rows = ["id,name,version,sourceManagers,licenseExpression,verification,hasLicenseText"]
        for entry in sorted() {
            let values = [
                entry.id,
                entry.name,
                entry.version ?? "",
                entry.sourceManagers.map(\.rawValue).joined(separator: "|"),
                entry.licenseExpression ?? "UNKNOWN",
                entry.verification.rawValue,
                entry.licenseTexts.isEmpty ? "false" : "true"
            ]
            rows.append(values.map(Self.csvEscape).joined(separator: ","))
        }
        return rows.joined(separator: "\n") + "\n"
    }

    private static func csvEscape(_ value: String) -> String {
        let safeValue = value.first.map { "=+-@".contains($0) ? "'\(value)" : value } ?? value
        let escaped = safeValue.replacingOccurrences(of: "\"", with: "\"\"")
        return "\"\(escaped)\""
    }
}
