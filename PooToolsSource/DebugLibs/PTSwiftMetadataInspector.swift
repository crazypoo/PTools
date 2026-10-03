//
//  PTSwiftMetadataInspector.swift
//  PooTools
//
// English: Detects stable Swift metadata sections without attempting ABI-dependent type demangling.
// Español: Detecta secciones estables de metadatos Swift sin intentar demanglar tipos dependientes del ABI.
// 中文：只检测稳定的 Swift 元数据段，不尝试执行依赖 ABI 的类型还原。
//

import Foundation

enum PTSwiftMetadataInspector {
    static func summary(sectionNames: [String], typeSectionSize: UInt64?) -> PTSwiftMetadataSummary {
        let names = Set(sectionNames)
        let hasTypes = names.contains("__swift5_types")
        let hasProtocols = names.contains("__swift5_proto") || names.contains("__swift5_protos")
        let reflectionNames: Set<String> = [
            "__swift5_fieldmd",
            "__swift5_reflstr",
            "__swift5_assocty",
            "__swift5_capture",
            "__swift5_builtin"
        ]
        let hasReflection = !names.isDisjoint(with: reflectionNames)
        let estimatedCount: Int?
        if hasTypes, let typeSectionSize, typeSectionSize <= UInt64(Int.max) {
            estimatedCount = Int(typeSectionSize / 4)
        } else {
            estimatedCount = nil
        }

        return PTSwiftMetadataSummary(hasSwiftTypesSection: hasTypes,
                                      hasSwiftProtocolSection: hasProtocols,
                                      hasSwiftReflectionMetadata: hasReflection,
                                      estimatedTypeRecordCount: estimatedCount,
                                      sectionNames: names.sorted())
    }
}

