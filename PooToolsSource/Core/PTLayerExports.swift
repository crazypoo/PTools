//
//  PTLayerExports.swift
//  PooTools
//
//  Re-export split SwiftPM layers while keeping CocoaPods source compatibility.
//  Reexporta las capas SwiftPM separadas y conserva la compatibilidad con CocoaPods.
//  重新导出拆分后的 SwiftPM 层，同时保持 CocoaPods 源码兼容。
//

// English: canImport keeps the legacy Xcode/CocoaPods source set buildable without split modules.
// Español: canImport mantiene compilable el conjunto heredado de Xcode/CocoaPods sin módulos separados.
// 中文：canImport 保证没有拆分模块的 Xcode/CocoaPods 源码集合仍可编译。
#if canImport(PToolsCore)
@_exported import PToolsCore
#endif

#if canImport(PToolsUIFoundation)
@_exported import PToolsUIFoundation
#endif

#if canImport(PToolsPermissionCore)
@_exported import PToolsPermissionCore
#endif
