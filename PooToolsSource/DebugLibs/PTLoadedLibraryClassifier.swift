//
//  PTLoadedLibraryClassifier.swift
//  PooTools
//
// English: Classifies loaded images using stable public path conventions.
// Español: Clasifica imágenes cargadas usando convenciones públicas y estables de rutas.
// 中文：使用稳定的公开路径规则对已加载镜像进行分类。
//

import Foundation

enum PTLoadedLibraryClassifier {
    static func kind(for snapshot: PTLoadedImageSnapshot) -> PTLoadedLibraryKind {
        if snapshot.isMainExecutable {
            return .mainExecutable
        }

        let path = snapshot.path
        if path.isEmpty {
            return .unknown
        }

        if path.hasPrefix("/System/Library/PrivateFrameworks/") {
            return .systemPrivateFramework
        }
        if path.hasPrefix("/System/Library/Frameworks/") {
            return .systemFramework
        }
        if path.hasPrefix("/usr/lib/") {
            return .systemDylib
        }
        if path.contains("/Library/Developer/") || path.contains("/Developer/") {
            return .injectedImage
        }
        if let appRange = path.range(of: ".app/") {
            let suffix = String(path[appRange.upperBound...])
            if suffix.contains("/Frameworks/") || suffix.hasSuffix(".framework/\(snapshot.name)") {
                return .appFramework
            }
            if suffix.hasSuffix(".dylib") || snapshot.name.hasSuffix(".dylib") {
                return .appDylib
            }
            return .appDylib
        }

        if path.hasSuffix(".framework/\(snapshot.name)") {
            return .appFramework
        }
        if path.hasSuffix(".dylib") {
            return .appDylib
        }
        return .unknown
    }
}

