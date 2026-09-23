// English: PTSymbol is the small, Sendable value used by the typed symbol catalog.
// Español: PTSymbol es el valor pequeño y Sendable utilizado por el catálogo tipado.
// 中文：PTSymbol 是类型化符号目录使用的轻量 Sendable 值类型。

import Foundation

@dynamicMemberLookup
public struct PTSymbol: RawRepresentable, Hashable, Sendable, Codable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    // English: Explicit appending keeps dynamic symbols available before the catalog is regenerated.
    // Español: La concatenación explícita permite usar símbolos dinámicos antes de regenerar el catálogo.
    // 中文：显式拼接保证目录重新生成前也能使用动态系统符号。
    public func appending(_ component: String) -> PTSymbol {
        guard !component.isEmpty else { return self }
        return PTSymbol(rawValue: rawValue.isEmpty ? component : "\(rawValue).\(component)")
    }

    // English: This compatibility lookup preserves the old chained call shape without copying a third-party class hierarchy.
    // Español: Esta búsqueda de compatibilidad conserva la sintaxis encadenada antigua sin copiar una jerarquía de terceros.
    // 中文：这个兼容查找保留旧的链式调用形式，同时不复制第三方类层级。
    public subscript(dynamicMember member: String) -> PTSymbol {
        appending(Self.rawComponent(from: member))
    }

    private static func rawComponent(from member: String) -> String {
        var components: [String] = []
        var current = ""

        func appendCurrent() {
            guard !current.isEmpty else { return }
            components.append(current.lowercased())
            current.removeAll(keepingCapacity: true)
        }

        for character in member {
            if character == "_" {
                appendCurrent()
                continue
            }
            if character.isUppercase {
                appendCurrent()
            }
            current.append(contentsOf: String(character).lowercased())
        }
        appendCurrent()
        return components.joined(separator: ".")
    }
}

// English: The fallback value is immutable and safe to pass across actor boundaries.
// Español: El valor de fallback es inmutable y seguro para cruzar límites de actor.
// 中文：回退值不可变，可以安全跨越 actor 边界传递。
public struct PTSymbolFallback: Sendable, Hashable, Codable {
    public let symbols: [PTSymbol]

    public init(_ symbols: [PTSymbol]) {
        self.symbols = symbols
    }

    public init(_ symbol: PTSymbol) {
        self.symbols = [symbol]
    }
}

// English: Catalog metadata is a normalized value instead of a dependency on Apple's private metadata format.
// Español: Los metadatos del catálogo son valores normalizados y no dependen del formato privado de Apple.
// 中文：目录元数据采用标准化值类型，不绑定 Apple 私有元数据格式。
public struct PTSymbolAvailability: Sendable, Hashable, Codable {
    public let introducedIOS: String
    public let deprecatedIOS: String?

    public init(introducedIOS: String = "17.0", deprecatedIOS: String? = nil) {
        self.introducedIOS = introducedIOS
        self.deprecatedIOS = deprecatedIOS
    }
}

public struct PTSymbolDescriptor: Sendable, Hashable, Codable {
    public let symbol: PTSymbol
    public let swiftName: String
    public let availability: PTSymbolAvailability
    public let renamedTo: PTSymbol?
    public let supportsVariableValue: Bool

    public init(symbol: PTSymbol,
                swiftName: String,
                availability: PTSymbolAvailability = .init(),
                renamedTo: PTSymbol? = nil,
                supportsVariableValue: Bool = false) {
        self.symbol = symbol
        self.swiftName = swiftName
        self.availability = availability
        self.renamedTo = renamedTo
        self.supportsVariableValue = supportsVariableValue
    }
}
