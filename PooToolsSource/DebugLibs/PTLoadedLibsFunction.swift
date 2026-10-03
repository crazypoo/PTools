//
//  PTLoadedLibsFunction.swift
//  PooTools
//
// English: Compatibility facade for the registry-based Loaded Libs implementation.
// Español: Fachada de compatibilidad para la implementación de Loaded Libs basada en un registro.
// 中文：为基于 Registry 的 Loaded Libs 实现保留兼容门面。
//

import Foundation

@available(*, deprecated, message: "Use PTDyldImageProvider through PTLoadedLibrariesViewModel.")
enum PTLoadedLibsFunction {
    // English: Return immutable snapshots without exposing dyld pointers to callers.
    // Español: Devuelve snapshots inmutables sin exponer punteros de dyld a los consumidores.
    // 中文：返回不可变快照，不向调用方暴露 dyld 指针。
    static func fetchLoadedImageSnapshots() -> [PTLoadedImageSnapshot] {
        PTDyldImageProvider().snapshots()
    }
}
