//
//  PTLoadedLibraryInspectionCache.swift
//  PooTools
//
// English: Bounds debug inspection results so expanded library details cannot grow without limit.
// Español: Limita los resultados de inspección para que los detalles expandidos no crezcan sin límite.
// 中文：限制调试诊断缓存，避免展开库详情后内存无限增长。
//

import Foundation
import os.lock

private struct PTLoadedLibraryInspectionCacheState: Sendable {
    var metadata: [String: PTLoadedLibraryDetails] = [:]
    var classes: [String: PTObjCClassInspectionResult] = [:]
    var order: [String] = []
}

enum PTLoadedLibraryInspectionCache {
    private static let capacity = 64
    private static let state = OSAllocatedUnfairLock(initialState: PTLoadedLibraryInspectionCacheState())

    static func metadata(for identifier: String) -> PTLoadedLibraryDetails? {
        state.withLock { $0.metadata[identifier] }
    }

    static func classes(for identifier: String) -> PTObjCClassInspectionResult? {
        state.withLock { $0.classes[identifier] }
    }

    static func store(metadata: PTLoadedLibraryDetails, for identifier: String) {
        state.withLock { state in
            state.metadata[identifier] = metadata
            touch(identifier, state: &state)
        }
    }

    static func store(classes: PTObjCClassInspectionResult, for identifier: String) {
        state.withLock { state in
            state.classes[identifier] = classes
            touch(identifier, state: &state)
        }
    }

    static func remove(identifier: String) {
        state.withLock { state in
            state.metadata.removeValue(forKey: identifier)
            state.classes.removeValue(forKey: identifier)
            state.order.removeAll { $0 == identifier }
        }
    }

    // English: Remove entries tied to an unloaded image when only its header address remains available.
    // Español: Elimina las entradas de una imagen descargada cuando solo queda disponible su dirección de cabecera.
    // 中文：当卸载回调只提供头地址时，移除与该镜像关联的缓存。
    static func removeAll(matchingHeaderAddress headerAddress: UInt) {
        state.withLock { state in
            let prefix = "\(headerAddress)|"
            let identifiers = Set(state.metadata.keys).union(state.classes.keys).filter { $0.hasPrefix(prefix) }
            for identifier in identifiers {
                state.metadata.removeValue(forKey: identifier)
                state.classes.removeValue(forKey: identifier)
                state.order.removeAll { $0 == identifier }
            }
        }
    }

    private static func touch(_ identifier: String, state: inout PTLoadedLibraryInspectionCacheState) {
        state.order.removeAll { $0 == identifier }
        state.order.append(identifier)
        while state.order.count > capacity {
            let evicted = state.order.removeFirst()
            state.metadata.removeValue(forKey: evicted)
            state.classes.removeValue(forKey: evicted)
        }
    }
}
