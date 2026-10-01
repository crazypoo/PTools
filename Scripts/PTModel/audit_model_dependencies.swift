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
var internalSmartCodable = 0
var internalKakaJSON = 0
var legacyNetworkCalls = 0
for file in swiftFiles {
    guard let contents = try? String(contentsOf: file, encoding: .utf8) else { continue }
    let isLegacyAdapter = file.path.contains("PToolsModelLegacy") || file.path.contains("Fixtures")
    let smartImports = contents.components(separatedBy: "import SmartCodable").count - 1
    let kakaImports = contents.components(separatedBy: "import KakaJSON").count - 1
    smartCodable += smartImports
    kakaJSON += kakaImports
    if isLegacyAdapter {
        // English: Third-party imports are allowed only in explicit legacy adapters and fixtures.
        // Español: Las importaciones de terceros solo se permiten en adaptadores heredados y fixtures explícitos.
        // 中文：第三方 import 只允许出现在显式旧版适配器和 fixture 中。
    } else {
        internalSmartCodable += smartImports
        internalKakaJSON += kakaImports
    }
    ptModel += contents.components(separatedBy: "PTModel").count - 1
    adapters += contents.components(separatedBy: "PTNetworkLegacyResponseDecoder").count - 1
    // English: Count call sites only; declarations in the compatibility wrapper are not migration debt.
    // Español: Cuenta solo los call sites; las declaraciones del wrapper de compatibilidad no son deuda de migración.
    // 中文：只统计调用点；兼容包装器自身的方法声明不算迁移债务。
    let callLines = contents.split(whereSeparator: \.isNewline).filter { line in
        let text = line.trimmingCharacters(in: .whitespacesAndNewlines)
        return !text.contains("func requestApi") && !text.contains("func requestBodyAPI")
    }.joined(separator: "\n")
    legacyNetworkCalls += callLines.components(separatedBy: "requestApi(").count - 1
    legacyNetworkCalls += callLines.components(separatedBy: "requestBodyAPI(").count - 1
}

let report: [String: Int] = [
    "swiftFiles": swiftFiles.count,
    "smartCodableImports": smartCodable,
    "kakaJSONImports": kakaJSON,
    "internalSmartCodableImports": internalSmartCodable,
    "internalKakaJSONImports": internalKakaJSON,
    "ptModelReferences": ptModel,
    "legacyNetworkAdapterReferences": adapters,
    "remainingLegacyNetworkCalls": legacyNetworkCalls
]
let data = try JSONSerialization.data(withJSONObject: report, options: [.sortedKeys])
if let output = String(data: data, encoding: .utf8) {
    print(output)
}
print("internalSmartCodableImports = \(internalSmartCodable)")
print("internalKakaJSONImports = \(internalKakaJSON)")
print("remainingLegacyNetworkCalls = \(legacyNetworkCalls)")
