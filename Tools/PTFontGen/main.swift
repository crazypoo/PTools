// English: Generate the deterministic PTFont catalog source from reviewed JSON metadata.
// Español: Genera el código determinista del catálogo PTFont desde los metadatos JSON revisados.
// 中文：根据审核后的 JSON 元数据生成确定性的 PTFont 目录源码。

import Foundation

private struct Catalog: Decodable {
    let catalogVersion: String?
    let fonts: [FontEntry]
}

private struct FontEntry: Decodable {
    let swiftName: String
    let postScriptName: String
    let familyName: String
    let introducedIOS: String
}

@main
struct PTFontGen {
    static func main() throws {
        let arguments = Array(CommandLine.arguments.dropFirst())
        let catalogPath = value(after: "--catalog", in: arguments)
            ?? "PooToolsSource/Font/Resources/FontCatalog/FontCatalog.json"
        let outputPath = value(after: "--output", in: arguments)
            ?? "PooToolsSource/Font/Generated/PTFontCatalog.generated.swift"

        let data = try Data(contentsOf: URL(fileURLWithPath: catalogPath))
        let catalog = try JSONDecoder().decode(Catalog.self, from: data)
        try validate(catalog.fonts)
        let source = render(catalog)
        let outputURL = URL(fileURLWithPath: outputPath)
        try FileManager.default.createDirectory(at: outputURL.deletingLastPathComponent(),
                                                withIntermediateDirectories: true)
        try source.write(to: outputURL, atomically: true, encoding: .utf8)
        print("PASS [PTFONTGEN] generated \(catalog.fonts.count) fonts at \(outputPath)")
    }

    private static func value(after flag: String, in arguments: [String]) -> String? {
        guard let index = arguments.firstIndex(of: flag), arguments.indices.contains(index + 1) else {
            return nil
        }
        return arguments[index + 1]
    }

    private static func validate(_ fonts: [FontEntry]) throws {
        guard !fonts.isEmpty else { throw ValidationError.emptyCatalog }
        let swiftNames = fonts.map(\.swiftName)
        let postScriptNames = fonts.map(\.postScriptName)
        guard Set(swiftNames).count == swiftNames.count else { throw ValidationError.duplicateSwiftName }
        guard Set(postScriptNames).count == postScriptNames.count else { throw ValidationError.duplicatePostScriptName }
        guard fonts.allSatisfy({ !$0.familyName.isEmpty && !$0.postScriptName.isEmpty }) else {
            throw ValidationError.invalidEntry
        }
    }

    private static func render(_ catalog: Catalog) -> String {
        var lines = [
            "// AUTO-GENERATED FILE — DO NOT EDIT.",
            "// Generator: Tools/PTFontGen/main.swift",
            "// Catalog version: \(catalog.catalogVersion ?? "unknown")",
            "// English: Generated immutable metadata for the PTFont catalog.",
            "// Español: Metadatos inmutables generados para el catálogo PTFont.",
            "// 中文：PTFont 目录的不可变元数据生成文件。",
            "",
            "import Foundation",
            "",
            "public extension PTFont {"
        ]
        for font in catalog.fonts {
            lines += [
                "    static let \(font.swiftName) = PTFont(",
                "        postScriptName: \(swiftString(font.postScriptName)),",
                "        familyName: \(swiftString(font.familyName)),",
                "        introducedIOS: \(swiftString(font.introducedIOS))",
                "    )",
                ""
            ]
        }
        lines += ["}", "", "internal enum PTFontCatalogGenerated {", "    static let allFonts: [PTFont] = ["]
        lines += catalog.fonts.map { "        .\($0.swiftName)," }
        lines += ["    ]", "}", ""]
        return lines.joined(separator: "\n")
    }

    private static func swiftString(_ value: String) -> String {
        value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "\\r")
            .replacingOccurrences(of: "\t", with: "\\t")
            .withQuotes
    }

    private enum ValidationError: Error {
        case emptyCatalog
        case duplicateSwiftName
        case duplicatePostScriptName
        case invalidEntry
    }
}

private extension String {
    var withQuotes: String { "\"\(self)\"" }
}
