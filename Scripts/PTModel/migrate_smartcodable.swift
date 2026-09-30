//
//  migrate_smartcodable.swift
//
// English: Produce a read-only SmartCodable migration manifest; source files are never rewritten.
// Español: Produce un manifiesto de migración de SmartCodable de solo lectura; nunca reescribe el código fuente.
// 中文：生成只读的 SmartCodable 迁移清单；不会自动改写源码。
//

import Foundation

struct Match: Codable {
    let file: String
    let line: Int
    let kind: String
    let text: String
}

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let sourceRoot = root.appendingPathComponent("PooToolsSource", isDirectory: true)
let patterns: [(String, String)] = [
    ("import", "import SmartCodable"),
    ("annotation", "@SmartCodable"),
    ("annotation", "@SmartSubclass"),
    ("protocol", "SmartCodable"),
    ("legacy-model", "PTBaseModel")
]

var matches: [Match] = []
let enumerator = FileManager.default.enumerator(at: sourceRoot,
                                                includingPropertiesForKeys: [.isRegularFileKey],
                                                options: [.skipsHiddenFiles])
while let file = enumerator?.nextObject() as? URL {
    guard file.pathExtension == "swift",
          let contents = try? String(contentsOf: file, encoding: .utf8) else { continue }
    for (lineIndex, line) in contents.components(separatedBy: .newlines).enumerated() {
        for (kind, pattern) in patterns where line.contains(pattern) {
            matches.append(Match(file: file.path,
                                 line: lineIndex + 1,
                                 kind: kind,
                                 text: line.trimmingCharacters(in: .whitespacesAndNewlines)))
        }
    }
}

let report: [String: Any] = [
    "mode": "dry-run",
    "source": "SmartCodable",
    "matches": matches.map { ["file": $0.file, "line": $0.line, "kind": $0.kind, "text": $0.text] },
    "matchCount": matches.count,
    "nextStep": "Replace each match with PTModelCore/PTModel or an explicit legacy adapter, then rerun this report."
]
let data = try JSONSerialization.data(withJSONObject: report, options: [.prettyPrinted, .sortedKeys])
print(String(decoding: data, as: UTF8.self))
