//
//  PTVariantSelectionEngine.swift
//  PToolsVariantCore
//
// English: A UI-free, value-typed variant selection engine for reusable product catalogs.
// Español: Un motor de selección de variantes sin UI y basado en tipos de valor para catálogos reutilizables.
// 中文：面向可复用商品目录、无 UI 且基于值类型的规格选择引擎。
//

import Foundation

// English: An option identifies one selectable value inside a catalog dimension.
// Español: Una opción identifica un valor seleccionable dentro de una dimensión del catálogo.
// 中文：一个选项表示目录某个规格维度中的一个可选值。
public struct PTVariantOption: Hashable, Sendable {
    public let level: Int
    public let id: String

    public init(level: Int, id: String) {
        self.level = level
        self.id = id
    }
}

// English: A variant contains only catalog facts; parsing backend-specific payloads stays outside this target.
// Español: Una variante solo contiene datos del catálogo; el parseo específico del backend queda fuera de este target.
// 中文：变体只保存目录事实，后端字段解析留在这个 target 之外。
public struct PTVariant: Sendable, Equatable {
    public let rawKey: String
    public let optionIDs: [Int: String]
    public let identifier: String
    public let price: Decimal
    public let stock: Int

    public init(rawKey: String,
                optionIDs: [Int: String],
                identifier: String = "",
                price: Decimal = 0,
                stock: Int = 0) {
        self.rawKey = rawKey
        self.optionIDs = optionIDs
        self.identifier = identifier
        self.price = price
        self.stock = stock
    }
}

public struct PTVariantOptionReference: Hashable, Sendable {
    public let level: Int
    public let id: String

    public init(level: Int, id: String) {
        self.level = level
        self.id = id
    }
}

public enum PTVariantOptionAvailability: Equatable, Sendable {
    case selected
    case available
    case conflict
    case soldOut
}

// English: Make conflict resolution explicit so callers can choose compatibility or strict validation.
// Español: Hace explícita la resolución de conflictos para que el consumidor elija compatibilidad o validación estricta.
// 中文：显式暴露冲突处理策略，让调用方选择兼容模式或严格校验模式。
public enum PTVariantConflictPolicy: Sendable, Equatable {
    /// Keep the newest dimension and remove older conflicting selections.
    /// Conserva la dimensión más nueva y elimina las selecciones antiguas en conflicto.
    /// 保留最近选择的维度，并清除较早的冲突选择。
    case keepLatestSelection

    /// Reject a selection that would make the current combination invalid.
    /// Rechaza una selección que volvería inválida la combinación actual.
    /// 拒绝会让当前组合失效的新选择。
    case rejectNewSelection
}

public struct PTVariantPriceRange: Equatable, Sendable {
    public let minimum: Decimal
    public let maximum: Decimal

    public init(minimum: Decimal, maximum: Decimal) {
        self.minimum = minimum
        self.maximum = maximum
    }
}

public struct PTVariantSelectionSnapshot: Sendable {
    public let selected: [Int: String]
    public let optionStates: [PTVariantOptionReference: PTVariantOptionAvailability]
    public let candidates: [PTVariant]
    public let matchedVariant: PTVariant?
    public let missingLevels: [Int]
    public let priceRange: PTVariantPriceRange?

    public init(selected: [Int: String],
                optionStates: [PTVariantOptionReference: PTVariantOptionAvailability],
                candidates: [PTVariant],
                matchedVariant: PTVariant?,
                missingLevels: [Int],
                priceRange: PTVariantPriceRange?) {
        self.selected = selected
        self.optionStates = optionStates
        self.candidates = candidates
        self.matchedVariant = matchedVariant
        self.missingLevels = missingLevels
        self.priceRange = priceRange
    }
}

// English: Keep selection as a Sendable value type so UI and network adapters can own it independently.
// Español: Mantiene la selección como un tipo de valor Sendable para que UI y adaptadores de red la posean independientemente.
// 中文：选择引擎使用 Sendable 值类型，让 UI 和网络适配器可以独立持有。
public struct PTVariantSelectionEngine: Sendable {
    public let levels: [Int]
    public let options: [PTVariantOption]
    public let variants: [PTVariant]
    public let minimumStock: Int
    public let conflictPolicy: PTVariantConflictPolicy

    public private(set) var selected: [Int: String]
    private var selectionOrder: [Int]

    public init(levels: [Int],
                options: [PTVariantOption],
                variants: [PTVariant],
                initialSelection: [Int: String] = [:],
                minimumStock: Int = 1,
                conflictPolicy: PTVariantConflictPolicy = .keepLatestSelection) {
        self.levels = Array(Set(levels)).sorted()
        self.options = options
        self.variants = variants
        self.minimumStock = max(1, minimumStock)
        self.conflictPolicy = conflictPolicy

        let validIDs = Set(options.map { PTVariantOptionReference(level: $0.level, id: $0.id) })
        let validSelection = initialSelection.filter {
            validIDs.contains(PTVariantOptionReference(level: $0.key, id: $0.value))
        }
        self.selected = validSelection
        self.selectionOrder = self.levels.filter { validSelection[$0] != nil }
    }

    // English: Split only on catalog separators; a colon remains part of an option identifier.
    // Español: Divide solo por separadores del catálogo; los dos puntos siguen formando parte del identificador.
    // 中文：只按目录分隔符拆分，冒号仍属于选项标识的一部分。
    public static func keyTokens(from rawKey: String) -> [String] {
        rawKey
            .split { $0 == ";" || $0 == "," }
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    @discardableResult
    public mutating func select(level: Int, optionID: String) -> PTVariantSelectionSnapshot {
        let reference = PTVariantOptionReference(level: level, id: optionID)
        guard options.contains(where: {
            PTVariantOptionReference(level: $0.level, id: $0.id) == reference
        }) else {
            return snapshot()
        }

        if selected[level] == optionID {
            // English: Allow clearing a selected option even after its stock expires.
            // Español: Permite limpiar una opción seleccionada aunque su stock haya caducado.
            // 中文：即使已选项后来售罄，也允许主动清除它。
            selected.removeValue(forKey: level)
            selectionOrder.removeAll { $0 == level }
            return snapshot()
        }

        guard !matchingVariants(for: [level: optionID]).isEmpty else {
            return snapshot()
        }

        let previousSelection = selected
        let previousOrder = selectionOrder
        selected[level] = optionID
        selectionOrder.removeAll { $0 == level }
        selectionOrder.append(level)

        switch conflictPolicy {
        case .keepLatestSelection:
            normalizeConflicts(keeping: level)
        case .rejectNewSelection:
            if matchingVariants(for: selected).isEmpty {
                selected = previousSelection
                selectionOrder = previousOrder
            }
        }
        return snapshot()
    }

    @discardableResult
    public mutating func clear(level: Int) -> PTVariantSelectionSnapshot {
        selected.removeValue(forKey: level)
        selectionOrder.removeAll { $0 == level }
        return snapshot()
    }

    public func automaticSelection() -> [Int: String] {
        var result: [Int: String] = [:]
        for level in levels {
            let ids = Set(matchingVariants(for: result).compactMap { $0.optionIDs[level] })
            if ids.count == 1, let onlyID = ids.first {
                result[level] = onlyID
            }
        }
        return result
    }

    public func snapshot() -> PTVariantSelectionSnapshot {
        let candidates = matchingVariants(for: selected)
        let matchedVariant = selected.count == levels.count && candidates.count == 1 ? candidates[0] : nil

        var states: [PTVariantOptionReference: PTVariantOptionAvailability] = [:]
        for option in options {
            let reference = PTVariantOptionReference(level: option.level, id: option.id)
            if selected[option.level] == option.id {
                states[reference] = .selected
                continue
            }

            guard !matchingVariants(for: [option.level: option.id]).isEmpty else {
                states[reference] = .soldOut
                continue
            }

            var trial = selected
            trial[option.level] = option.id
            states[reference] = matchingVariants(for: trial).isEmpty ? .conflict : .available
        }

        let prices = candidates.map(\.price)
        let priceRange: PTVariantPriceRange?
        if let minimum = prices.min(), let maximum = prices.max() {
            priceRange = PTVariantPriceRange(minimum: minimum, maximum: maximum)
        } else {
            priceRange = nil
        }

        return PTVariantSelectionSnapshot(selected: selected,
                                           optionStates: states,
                                           candidates: candidates,
                                           matchedVariant: matchedVariant,
                                           missingLevels: levels.filter { selected[$0] == nil },
                                           priceRange: priceRange)
    }

    private func matchingVariants(for selection: [Int: String]) -> [PTVariant] {
        variants.filter { variant in
            variant.stock >= minimumStock && selection.allSatisfy { level, optionID in
                variant.optionIDs[level] == optionID
            }
        }
    }

    private mutating func normalizeConflicts(keeping level: Int) {
        guard matchingVariants(for: selected).isEmpty else { return }

        // English: Prefer the latest dimension and remove older conflicting dimensions linearly.
        // Español: Prioriza la última dimensión y elimina linealmente las dimensiones antiguas en conflicto.
        // 中文：优先保留最近选择的维度，按选择顺序线性清除冲突维度。
        let levelsToRemove = selectionOrder.filter { $0 != level }
        for oldLevel in levelsToRemove {
            selected.removeValue(forKey: oldLevel)
            selectionOrder.removeAll { $0 == oldLevel }
            if !matchingVariants(for: selected).isEmpty { break }
        }
    }
}
