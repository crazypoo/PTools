//
//  PTLoadedLibraryInspector.swift
//  PooTools
//
// English: Performs bounded metadata inspection off the main actor and keeps class enumeration lazy.
// Español: Realiza una inspección acotada fuera del actor principal y mantiene perezosa la enumeración de clases.
// 中文：在主 Actor 之外执行有边界的元数据诊断，并让类枚举保持延迟执行。
//

import Foundation

struct PTLoadedLibraryInspector: Sendable {
    let configuration: PTLoadedLibsConfiguration

    init(configuration: PTLoadedLibsConfiguration = .default) {
        self.configuration = configuration
    }

    func inspectMetadata(_ snapshot: PTLoadedImageSnapshot) -> PTLoadedLibraryDetails {
        if let cached = PTLoadedLibraryInspectionCache.metadata(for: snapshot.identifier) {
            return cached
        }

        let fileSize: UInt64?
        let backing: PTLoadedBinaryBacking
        if configuration.enablesFileMetadataInspection, !snapshot.path.isEmpty {
            let attributes = try? FileManager.default.attributesOfItem(atPath: snapshot.path)
            fileSize = attributes?[.size] as? UInt64 ?? (attributes?[.size] as? NSNumber).map { $0.uint64Value }
            backing = fileSize == nil ? Self.classifyBacking(path: snapshot.path) : .standaloneFile
        } else {
            fileSize = nil
            backing = Self.classifyBacking(path: snapshot.path)
        }

        let machO = PTMachOImageInspector.inspect(snapshot)
        let capabilities = Self.capabilities(snapshot: snapshot,
                                             fileSize: fileSize,
                                             backing: backing,
                                             machO: machO)
        let details = PTLoadedLibraryDetails.metadata(fileSize: fileSize,
                                                       mappedSize: machO.info?.mappedSize,
                                                       architecture: machO.info?.architecture,
                                                       uuid: machO.info?.uuid,
                                                       backing: backing,
                                                       capabilities: capabilities,
                                                       swiftMetadata: configuration.enablesSwiftMetadataInspection
                                                           ? (machO.info?.swiftMetadata ?? .unavailable)
                                                           : .unavailable,
                                                       segments: machO.info?.segments ?? [],
                                                       machOFailure: machO.failure)
        PTLoadedLibraryInspectionCache.store(metadata: details, for: snapshot.identifier)
        return details
    }

    func inspectObjectiveCClasses(_ snapshot: PTLoadedImageSnapshot) -> PTObjCClassInspectionResult {
        guard configuration.enablesObjectiveCRuntimeInspection else {
            return .unavailable(reason: "Objective-C inspection disabled")
        }
        if let cached = PTLoadedLibraryInspectionCache.classes(for: snapshot.identifier) {
            return cached
        }
        let result = PTObjCRuntimeImageInspector.inspect(path: snapshot.path)
        PTLoadedLibraryInspectionCache.store(classes: result, for: snapshot.identifier)
        return result
    }

    private static func classifyBacking(path: String) -> PTLoadedBinaryBacking {
        guard !path.isEmpty else { return .memoryOnly }
        if FileManager.default.fileExists(atPath: path) {
            return .standaloneFile
        }
        if path.hasPrefix("/System/Library/") || path.hasPrefix("/usr/lib/") {
            return .sharedCacheLikely
        }
        return .unknown
    }

    private static func capabilities(snapshot: PTLoadedImageSnapshot,
                                     fileSize: UInt64?,
                                     backing: PTLoadedBinaryBacking,
                                     machO: PTMachOInspection) -> Set<PTLoadedLibraryCapability> {
        var result: Set<PTLoadedLibraryCapability> = snapshot.fileType == nil ? [] : [.validHeader]
        if fileSize != nil { result.insert(.fileMetadata) }
        if machO.info?.mappedSize != nil { result.insert(.mappedSize) }
        if machO.info?.uuid != nil { result.insert(.uuid) }
        if machO.info?.swiftMetadata.isAvailable == true { result.insert(.swiftMetadata) }
        if backing == .sharedCacheLikely { result.insert(.sharedCacheCandidate) }
        return result
    }
}
