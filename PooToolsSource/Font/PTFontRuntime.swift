//
//  PTFontRuntime.swift
//
// English: Discover fonts lazily from the active iOS runtime, never during application startup.
// Español: Descubre fuentes de forma diferida desde el runtime iOS activo, nunca durante el arranque.
// 中文：按需从当前 iOS Runtime 发现字体，不在应用启动时扫描。
//

import Foundation
import UIKit

public struct PTFontRuntimeSnapshot: Codable, Sendable {
    public let runtime: String
    public let generatedAt: Date
    public let fonts: [PTFontDescriptor]

    public init(runtime: String,
                generatedAt: Date = Date(),
                fonts: [PTFontDescriptor]) {
        self.runtime = runtime
        self.generatedAt = generatedAt
        self.fonts = fonts
    }
}

@MainActor
public enum PTFontRuntime {
    private static var cachedFonts: [PTFontDescriptor]?

    public static var installedFonts: [PTFontDescriptor] {
        if let cachedFonts { return cachedFonts }
        let descriptors = discover()
        cachedFonts = descriptors
        return descriptors
    }

    public static func refresh() -> [PTFontDescriptor] {
        let descriptors = discover()
        cachedFonts = descriptors
        return descriptors
    }

    // English: Export a simulator-host snapshot for human-reviewed catalog updates.
    // Español: Exporta una instantánea del host Simulator para actualizar el catálogo con revisión humana.
    // 中文：导出 Simulator 宿主快照，供人工审核后更新字体目录。
    public static func snapshot(runtime: String) -> PTFontRuntimeSnapshot {
        PTFontRuntimeSnapshot(runtime: runtime, fonts: installedFonts)
    }

    // English: Serialize the runtime snapshot without touching the reviewed catalog.
    // Español: Serializa la instantánea del runtime sin modificar el catálogo revisado.
    // 中文：序列化 Runtime 快照，但不修改已审核的正式目录。
    public static func snapshotJSON(runtime: String) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(snapshot(runtime: runtime))
    }

    private static func discover() -> [PTFontDescriptor] {
        UIFont.familyNames
            .sorted()
            .flatMap { familyName in
                UIFont.fontNames(forFamilyName: familyName)
                    .sorted()
                    .map { postScriptName in
                        let catalogEntry = PTFontCatalog.font(named: postScriptName)
                        return PTFontDescriptor(postScriptName: postScriptName,
                                                familyName: familyName,
                                                introducedIOS: catalogEntry?.introducedIOS,
                                                deprecatedIOS: nil,
                                                aliases: [])
                    }
            }
            .reduce(into: [PTFontDescriptor]()) { result, descriptor in
                guard !result.contains(where: { $0.postScriptName == descriptor.postScriptName }) else { return }
                result.append(descriptor)
            }
    }
}
