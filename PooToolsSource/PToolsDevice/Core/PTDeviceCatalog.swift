// English: The catalog is a generated, immutable lookup surface; runtime code never parses JSON.
// Español: El catálogo es una superficie de consulta inmutable y generada; el runtime nunca analiza JSON.
// 中文：设备目录是生成的不可变查询层，运行时不解析 JSON。

import Foundation

public enum PTDeviceCatalog {
    public static let version = PTDeviceCatalogGenerated.version
    public static let allSpecifications = PTDeviceCatalogGenerated.specifications

    public static func specification(for model: PTDeviceModel) -> PTDeviceSpecification? {
        allSpecifications.first { $0.model == model }
    }

    public static func specification(for identifier: String) -> PTDeviceSpecification? {
        allSpecifications.first { $0.identifiers.contains(identifier) }
    }

    public static func model(for identifier: String) -> PTDeviceModel? {
        specification(for: identifier)?.model
    }

    public static func models(family: PTDeviceFamily) -> [PTDeviceModel] {
        allSpecifications.filter { $0.family == family }.map(\.model)
    }

    public static func models(platform: PTDevicePlatform) -> [PTDeviceModel] {
        allSpecifications.filter { $0.platform == platform }.map(\.model)
    }
}

