// English: This macOS-friendly executable performs explicit build-time collection and validation.
// Español: Este ejecutable compatible con macOS recopila y valida solo durante la compilación.
// 中文：这个兼容 macOS 的可执行工具只在构建期执行明确的收集和校验。

import Foundation
import PToolsAcknowledgementsCore

#if canImport(Darwin)
import Darwin
#else
import Glibc
#endif

private struct PTGeneratorConfiguration: Codable, Sendable {
    var resolvedPaths: [String] = []
    var podfileLockPath: String?
    var appTarget: String?
    var overridesPath: String?
    var outputPath: String = "PTAcknowledgements.json"
    var reportPath: String = "PTAcknowledgements.report.json"
    var offline = true
    var checkoutRoots: [String] = []
}

private struct PTGenerationReport: Codable, Sendable {
    let schemaVersion: Int
    let generatorVersion: String
    let mode: String
    let appTarget: String?
    let issues: [PTAcknowledgementsValidationIssue]
    let entryCount: Int
}

private enum PTGeneratorFailure: Error, LocalizedError {
    case usage(String)
    case invalidArguments
    case fileWriteFailed

    var errorDescription: String? {
        switch self {
        case let .usage(message): return message
        case .invalidArguments: return "生成器参数无效。"
        case .fileWriteFailed: return "无法写入生成器输出文件。"
        }
    }
}

private struct PTCLIArguments {
    let command: String
    let values: [String: [String]]
    let flags: Set<String>

    init(arguments: [String]) throws {
        guard let command = arguments.first else {
            throw PTGeneratorFailure.usage(Self.help)
        }
        self.command = command
        var values: [String: [String]] = [:]
        var flags = Set<String>()
        var index = 1
        while index < arguments.count {
            let argument = arguments[index]
            guard argument.hasPrefix("--") else { throw PTGeneratorFailure.invalidArguments }
            let key = String(argument.dropFirst(2))
            if index + 1 < arguments.count, !arguments[index + 1].hasPrefix("--") {
                values[key, default: []].append(arguments[index + 1])
                index += 2
            } else {
                flags.insert(key)
                index += 1
            }
        }
        self.values = values
        self.flags = flags
    }

    func value(_ key: String) -> String? { values[key]?.last }
    func allValues(_ key: String) -> [String] { values[key] ?? [] }
    func hasFlag(_ key: String) -> Bool { flags.contains(key) }

    static let help = """
    PTAcknowledgementsGenerator

    Commands:
      init --project <path> --app-target <name> [--output <config.json>]
      generate --config <config.json> [--offline]
      generate --resolved <Package.resolved> --podfile-lock <Podfile.lock> --output <manifest.json>
      validate --manifest <manifest.json> [--strict]
      validate --config <config.json> [--strict]
      diff --old <old.json> --new <new.json>
      audit --config <config.json>
    """
}

@main
private struct PTAcknowledgementsGenerator {
    static let version = "1.0.0"

    static func main() {
        do {
            let arguments = try PTCLIArguments(arguments: Array(CommandLine.arguments.dropFirst()))
            try run(arguments)
        } catch {
            FileHandle.standardError.write(Data("PTAcknowledgementsGenerator: \(error.localizedDescription)\n".utf8))
            exit(1)
        }
    }

    private static func run(_ arguments: PTCLIArguments) throws {
        switch arguments.command {
        case "init": try initialize(arguments)
        case "generate": try generate(arguments, auditOnly: false)
        case "audit": try generate(arguments, auditOnly: true)
        case "validate": try validate(arguments)
        case "diff": try diff(arguments)
        case "help", "--help": print(PTCLIArguments.help)
        default: throw PTGeneratorFailure.usage(PTCLIArguments.help)
        }
    }

    private static func initialize(_ arguments: PTCLIArguments) throws {
        guard let project = arguments.value("project"), let appTarget = arguments.value("app-target") else {
            throw PTGeneratorFailure.usage("init 需要 --project 和 --app-target。")
        }
        let projectURL = URL(fileURLWithPath: project).standardizedFileURL
        let root = projectURL.hasDirectoryPath ? projectURL : projectURL.deletingLastPathComponent()
        let configuration = PTGeneratorConfiguration(
            resolvedPaths: [root.appendingPathComponent("Package.resolved").path],
            podfileLockPath: root.appendingPathComponent("Podfile.lock").path,
            appTarget: appTarget,
            overridesPath: root.appendingPathComponent("Config/PTAcknowledgements.overrides.json").path,
            outputPath: "$(DERIVED_FILE_DIR)/PTAcknowledgements.json",
            reportPath: "$(DERIVED_FILE_DIR)/PTAcknowledgements.report.json",
            offline: true,
            checkoutRoots: [root.appendingPathComponent(".build/checkouts").path]
        )
        let data = try encoded(configuration)
        if let output = arguments.value("output") {
            try write(data, to: URL(fileURLWithPath: output))
        } else {
            print(String(decoding: data, as: UTF8.self))
        }
    }

    private static func generate(_ arguments: PTCLIArguments, auditOnly: Bool) throws {
        let configuration = try configuration(from: arguments)
        let entries = try collect(configuration)
        let manifest = try PTAcknowledgementsProvider.make(
            entries: entries,
            generatorVersion: version,
            appTarget: configuration.appTarget
        )
        let issues = manifest.validationIssues()
        let report = PTGenerationReport(
            schemaVersion: 1,
            generatorVersion: version,
            mode: auditOnly ? "audit" : "generate",
            appTarget: configuration.appTarget,
            issues: issues,
            entryCount: manifest.entries.count
        )
        let reportData = try encoded(report)
        if auditOnly {
            print(String(decoding: reportData, as: UTF8.self))
            return
        }
        try write(try manifest.export(.json), to: URL(fileURLWithPath: configuration.outputPath))
        try write(reportData, to: URL(fileURLWithPath: configuration.reportPath))
        print("生成 PTAcknowledgements.json: \(manifest.entries.count) 条目")
    }

    private static func validate(_ arguments: PTCLIArguments) throws {
        let path: String
        if let manifest = arguments.value("manifest") ?? arguments.value("file") {
            path = manifest
        } else if let configPath = arguments.value("config") {
            let data = try Data(contentsOf: URL(fileURLWithPath: configPath))
            let configuration = try JSONDecoder().decode(PTGeneratorConfiguration.self, from: data)
            guard !configuration.outputPath.contains("$(") else {
                throw PTGeneratorFailure.usage("validate --config 需要可解析的 outputPath；Build Phase 请传入 --manifest。")
            }
            path = configuration.outputPath
        } else {
            throw PTGeneratorFailure.usage("validate 需要 --manifest 或 --config。")
        }
        let manifest = try PTAcknowledgementsProvider.load(fileURL: URL(fileURLWithPath: path))
        let issues = manifest.validationIssues()
        let errors = issues.filter { $0.severity == .error }
        let missingText = issues.filter { $0.code == "missing-license-text" }
        let strict = arguments.hasFlag("strict")
        let report = PTGenerationReport(
            schemaVersion: 1,
            generatorVersion: version,
            mode: strict ? "validate-strict" : "validate",
            appTarget: manifest.appTarget,
            issues: issues,
            entryCount: manifest.entries.count
        )
        print(String(decoding: try encoded(report), as: UTF8.self))
        if !errors.isEmpty || (strict && !missingText.isEmpty) {
            throw PTGeneratorFailure.usage("许可证清单未通过校验。")
        }
    }

    private static func diff(_ arguments: PTCLIArguments) throws {
        guard let oldPath = arguments.value("old"), let newPath = arguments.value("new") else {
            throw PTGeneratorFailure.usage("diff 需要 --old 和 --new。")
        }
        let old = try PTAcknowledgementsProvider.load(fileURL: URL(fileURLWithPath: oldPath))
        let new = try PTAcknowledgementsProvider.load(fileURL: URL(fileURLWithPath: newPath))
        let oldIDs = Set(old.entries.map(\.id))
        let newIDs = Set(new.entries.map(\.id))
        print("Added: \(newIDs.subtracting(oldIDs).sorted().joined(separator: ", "))")
        print("Removed: \(oldIDs.subtracting(newIDs).sorted().joined(separator: ", "))")
        let changed = old.entries.compactMap { previous -> String? in
            guard let current = new.entry(id: previous.id), current != previous else { return nil }
            return previous.id
        }
        print("Changed: \(changed.sorted().joined(separator: ", "))")
    }

    private static func configuration(from arguments: PTCLIArguments) throws -> PTGeneratorConfiguration {
        if let configPath = arguments.value("config") {
            let data = try Data(contentsOf: URL(fileURLWithPath: configPath))
            let decoder = JSONDecoder()
            var configuration = try decoder.decode(PTGeneratorConfiguration.self, from: data)
            if arguments.hasFlag("offline") { configuration.offline = true }
            return configuration
        }
        guard !arguments.allValues("resolved").isEmpty || arguments.value("podfile-lock") != nil else {
            throw PTGeneratorFailure.usage("generate/audit 需要 --config，或至少一个 --resolved/--podfile-lock。")
        }
        return PTGeneratorConfiguration(
            resolvedPaths: arguments.allValues("resolved"),
            podfileLockPath: arguments.value("podfile-lock"),
            appTarget: arguments.value("app-target"),
            overridesPath: arguments.value("overrides"),
            outputPath: arguments.value("output") ?? "PTAcknowledgements.json",
            reportPath: arguments.value("report") ?? "PTAcknowledgements.report.json",
            offline: !arguments.hasFlag("allow-network"),
            checkoutRoots: arguments.allValues("checkout-root")
        )
    }

    private static func collect(_ configuration: PTGeneratorConfiguration) throws -> [PTAcknowledgement] {
        var entries: [PTAcknowledgement] = []
        for path in configuration.resolvedPaths where FileManager.default.fileExists(atPath: path) {
            entries.append(contentsOf: scanResolved(URL(fileURLWithPath: path), configuration: configuration))
        }
        if let podfileLockPath = configuration.podfileLockPath, FileManager.default.fileExists(atPath: podfileLockPath) {
            entries.append(contentsOf: scanPodfileLock(URL(fileURLWithPath: podfileLockPath)))
        }
        if let overridesPath = configuration.overridesPath, FileManager.default.fileExists(atPath: overridesPath) {
            entries.append(contentsOf: try loadOverrides(URL(fileURLWithPath: overridesPath)))
        }
        return merge(entries)
    }

    private static func scanResolved(_ url: URL, configuration: PTGeneratorConfiguration) -> [PTAcknowledgement] {
        guard let data = try? Data(contentsOf: url),
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return [] }
        let rawPins = (object["pins"] as? [[String: Any]]) ?? ((object["object"] as? [String: Any])?["pins"] as? [[String: Any]]) ?? []
        let checkoutRoots = configuration.checkoutRoots.map { URL(fileURLWithPath: $0) }
        return rawPins.compactMap { pin in
            let identity = (pin["identity"] as? String) ?? (pin["package"] as? String) ?? (pin["name"] as? String)
            let location = pin["location"] as? String
            guard let identity, let location else { return nil }
            let state = pin["state"] as? [String: Any]
            let version = state?["version"] as? String
            let revision = state?["revision"] as? String
            let normalizedURL = normalizedRepositoryURL(location)
            let checkout = checkoutRoots.lazy.map { $0.appendingPathComponent(identity) }.first { FileManager.default.fileExists(atPath: $0.path) }
            let documents = checkout.map(resolveLicenseDocuments) ?? []
            let name = identity.split(separator: ".").last.map(String.init) ?? identity
            let versionOrRevision = version ?? revision ?? "unversioned"
            return PTAcknowledgement(
                id: "spm:\(normalizedURL ?? identity)@\(versionOrRevision)",
                name: name,
                version: version,
                sourceManagers: [.swiftPM],
                repositoryURL: normalizedURL.flatMap(URL.init(string:)),
                licenseExpression: classifyLicense(documents),
                licenseTexts: documents.filter { !$0.fileName.lowercased().contains("notice") },
                notices: documents.filter { $0.fileName.lowercased().contains("notice") },
                provenance: .init(origin: checkout == nil ? "resolved" : "localCheckout", resolvedRevision: revision, sourceURL: normalizedURL.flatMap(URL.init(string:))),
                verification: documents.isEmpty ? .unverified : .verified
            )
        }
    }

    private static func scanPodfileLock(_ url: URL) -> [PTAcknowledgement] {
        guard let text = try? String(contentsOf: url, encoding: .utf8) else { return [] }
        var entries: [PTAcknowledgement] = []
        var inPods = false
        for line in text.split(separator: "\n", omittingEmptySubsequences: false) {
            let value = String(line)
            if value == "PODS:" { inPods = true; continue }
            if inPods, !value.hasPrefix("- ") { if !value.hasPrefix("  ") { inPods = false }; continue }
            guard inPods, value.hasPrefix("- "), !value.hasPrefix("- \"") else { continue }
            let token = String(value.dropFirst(2))
            guard let open = token.range(of: " (", options: .backwards), token.hasSuffix(")") else { continue }
            let name = String(token[..<open.lowerBound])
            let versionStart = token.index(open.lowerBound, offsetBy: 2)
            let version = String(token[versionStart..<token.index(before: token.endIndex)])
            entries.append(PTAcknowledgement(
                id: "pod:\(name)@\(version)",
                name: name,
                version: version,
                sourceManagers: [.cocoaPods],
                licenseExpression: nil,
                verification: .unverified
            ))
        }
        return entries
    }

    private static func loadOverrides(_ url: URL) throws -> [PTAcknowledgement] {
        let data = try Data(contentsOf: url)
        if let manifest = try? PTAcknowledgementsProvider.load(data: data) { return manifest.entries }
        return try JSONDecoder().decode([PTAcknowledgement].self, from: data)
    }

    private static func merge(_ entries: [PTAcknowledgement]) -> [PTAcknowledgement] {
        var merged: [String: PTAcknowledgement] = [:]
        for entry in entries {
            let key = [entry.repositoryURL?.absoluteString ?? entry.id, entry.version ?? ""].joined(separator: "@")
            guard let existing = merged[key] else {
                merged[key] = entry
                continue
            }
            let documents = uniqueDocuments(existing.licenseTexts + entry.licenseTexts)
            let notices = uniqueDocuments(existing.notices + entry.notices)
            let verification: PTAcknowledgementVerification = existing.licenseTexts.map(\.sha256) == entry.licenseTexts.map(\.sha256)
                ? (documents.isEmpty ? .unverified : .verified)
                : .conflict
            merged[key] = PTAcknowledgement(
                id: existing.id,
                name: existing.name,
                version: existing.version ?? entry.version,
                sourceManagers: Array(Set(existing.sourceManagers + entry.sourceManagers)),
                repositoryURL: existing.repositoryURL ?? entry.repositoryURL,
                websiteURL: existing.websiteURL ?? entry.websiteURL,
                licenseExpression: existing.licenseExpression ?? entry.licenseExpression,
                licenseTexts: documents,
                notices: notices,
                provenance: existing.provenance ?? entry.provenance,
                verification: verification
            )
        }
        return merged.values.sorted { $0.id < $1.id }
    }

    private static func uniqueDocuments(_ documents: [PTLicenseDocument]) -> [PTLicenseDocument] {
        var seen = Set<String>()
        return documents.filter { seen.insert($0.fileName + "@" + $0.sha256).inserted }
    }

    private static func resolveLicenseDocuments(_ root: URL) -> [PTLicenseDocument] {
        let names = Set(["license", "licence", "copying", "notice", "license.md", "licence.md", "copying.md", "notice.md"])
        guard let enumerator = FileManager.default.enumerator(at: root, includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey], options: [.skipsHiddenFiles]) else { return [] }
        var documents: [PTLicenseDocument] = []
        for case let fileURL as URL in enumerator {
            let lowerName = fileURL.lastPathComponent.lowercased()
            guard names.contains(lowerName),
                  let values = try? fileURL.resourceValues(forKeys: [.isDirectoryKey, .fileSizeKey]),
                  values.isDirectory != true,
                  (values.fileSize ?? 0) <= 10 * 1024 * 1024,
                  let text = try? String(contentsOf: fileURL, encoding: .utf8),
                  !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { continue }
            documents.append(.init(fileName: fileURL.relativePath(from: root), text: text))
            if documents.count >= 20 { break }
        }
        return documents.sorted { $0.fileName < $1.fileName }
    }

    private static func classifyLicense(_ documents: [PTLicenseDocument]) -> String? {
        let combined = documents.map(\.text).joined(separator: "\n").lowercased()
        if combined.contains("apache license") { return "Apache-2.0" }
        if combined.contains("permission is hereby granted, free of charge") { return "MIT" }
        if combined.contains("redistribution and use in source and binary forms") { return "BSD" }
        return documents.isEmpty ? nil : "UNKNOWN"
    }

    private static func normalizedRepositoryURL(_ value: String) -> String? {
        var normalized = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if normalized.hasPrefix("git@github.com:") {
            normalized = "https://github.com/" + normalized.dropFirst("git@github.com:".count)
        }
        if normalized.hasPrefix("ssh://git@github.com/") {
            normalized = "https://github.com/" + normalized.dropFirst("ssh://git@github.com/".count)
        }
        if normalized.hasSuffix(".git") { normalized.removeLast(4) }
        while normalized.hasSuffix("/") { normalized.removeLast() }
        guard let url = URL(string: normalized), url.scheme?.lowercased() == "https", url.host != nil else { return nil }
        return url.absoluteString
    }

    private static func encoded<T: Encodable>(_ value: T) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(value)
    }

    private static func write(_ data: Data, to url: URL) throws {
        let resolved = URL(fileURLWithPath: url.path)
        try FileManager.default.createDirectory(at: resolved.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: resolved, options: .atomic)
    }
}

private extension URL {
    func relativePath(from root: URL) -> String {
        let rootPath = root.standardizedFileURL.path.hasSuffix("/") ? root.standardizedFileURL.path : root.standardizedFileURL.path + "/"
        return path.replacingOccurrences(of: rootPath, with: "")
    }
}
