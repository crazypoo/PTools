//
//  audit_model_dependencies.swift
//
// English: Report model dependency usage without changing source files.
// Español: Informa del uso de dependencias de modelos sin modificar archivos fuente.
// 中文：只报告模型依赖使用情况，不自动修改源码。
//

import Foundation

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let sourceRoot = root.appendingPathComponent("PooToolsSource", isDirectory: true)
let enumerator = FileManager.default.enumerator(at: sourceRoot,
                                                includingPropertiesForKeys: [.isRegularFileKey],
                                                options: [.skipsHiddenFiles])
var swiftFiles: [URL] = []
while let item = enumerator?.nextObject() as? URL {
    guard item.pathExtension == "swift" else { continue }
    swiftFiles.append(item)
}

var smartCodable = 0
var kakaJSON = 0
var ptModel = 0
var adapters = 0
for file in swiftFiles {
    guard let contents = try? String(contentsOf: file, encoding: .utf8) else { continue }
    smartCodable += contents.components(separatedBy: "import SmartCodable").count - 1
    kakaJSON += contents.components(separatedBy: "import KakaJSON").count - 1
    ptModel += contents.components(separatedBy: "PTModel").count - 1
    adapters += contents.components(separatedBy: "PTNetworkLegacyResponseDecoder").count - 1
}

let report: [String: Int] = [
    "swiftFiles": swiftFiles.count,
    "smartCodableImports": smartCodable,
    "kakaJSONImports": kakaJSON,
    "ptModelReferences": ptModel,
    "legacyNetworkAdapterReferences": adapters
]
let data = try JSONSerialization.data(withJSONObject: report, options: [.sortedKeys])
if let output = String(data: data, encoding: .utf8) {
    print(output)
}
