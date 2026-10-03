//
//  PTLoadedImageTypes.swift
//  PooTools
//
// English: Value models for loaded-image discovery and lazy diagnostics.
// Español: Modelos de valor para descubrir imágenes cargadas y diagnosticar de forma diferida.
// 中文：用于已加载镜像发现和延迟诊断的值类型模型。
//

import Foundation

enum PTLoadedImageSource: String, Sendable, Hashable, Codable {
    case initialDyldEnumeration
    case dyldAddCallback
    case dladdrResolved
}

enum PTLoadedBinaryBacking: String, Sendable, Hashable, Codable {
    case standaloneFile
    case sharedCacheLikely
    case memoryOnly
    case unknown

    var displayName: String {
        switch self {
        case .standaloneFile:
            return "Standalone File"
        case .sharedCacheLikely:
            return "Shared Cache / System Image"
        case .memoryOnly:
            return "Memory Only"
        case .unknown:
            return "Unknown"
        }
    }
}

enum PTLoadedLibraryKind: String, Sendable, Hashable, Codable {
    case mainExecutable
    case appFramework
    case appDylib
    case systemFramework
    case systemPrivateFramework
    case systemDylib
    case injectedImage
    case unknown

    var displayName: String {
        switch self {
        case .mainExecutable:
            return "Main Executable"
        case .appFramework:
            return "App Framework"
        case .appDylib:
            return "App Dylib"
        case .systemFramework:
            return "System Framework"
        case .systemPrivateFramework:
            return "System Private Framework"
        case .systemDylib:
            return "System Dylib"
        case .injectedImage:
            return "Injected Image"
        case .unknown:
            return "Unknown Image"
        }
    }

    var isPrivateCompatibilityValue: Bool {
        switch self {
        case .systemFramework, .systemDylib:
            return false
        case .mainExecutable, .appFramework, .appDylib, .systemPrivateFramework, .injectedImage, .unknown:
            return true
        }
    }
}

enum PTLoadedLibraryCapability: String, Sendable, Hashable, Codable {
    case validHeader
    case fileMetadata
    case mappedSize
    case uuid
    case objectiveCRuntime
    case swiftMetadata
    case sharedCacheCandidate
}

enum PTLoadedLibraryInspectionState: Sendable, Hashable {
    case idle
    case loading
    case loaded
    case partiallyLoaded
    case unavailable(reason: String)
    case failed(message: String)
}

struct PTLoadedImageSnapshot: Identifiable, Sendable, Hashable {
    let identifier: String
    let path: String
    let name: String
    let headerAddress: UInt
    let vmAddressSlide: Int
    let isMainExecutable: Bool
    let fileType: UInt32?
    let source: PTLoadedImageSource

    var id: String { identifier }
}

struct PTSwiftMetadataSummary: Sendable, Hashable, Codable {
    let hasSwiftTypesSection: Bool
    let hasSwiftProtocolSection: Bool
    let hasSwiftReflectionMetadata: Bool
    let estimatedTypeRecordCount: Int?
    let sectionNames: [String]

    var isAvailable: Bool {
        hasSwiftTypesSection || hasSwiftProtocolSection || hasSwiftReflectionMetadata
    }

    static let unavailable = PTSwiftMetadataSummary(hasSwiftTypesSection: false,
                                                     hasSwiftProtocolSection: false,
                                                     hasSwiftReflectionMetadata: false,
                                                     estimatedTypeRecordCount: nil,
                                                     sectionNames: [])
}

enum PTObjCClassInspectionResult: Sendable, Hashable {
    case notRequested
    case loaded([String])
    case unavailable(reason: String)
    case failed(message: String)

    var classes: [String] {
        if case let .loaded(classes) = self {
            return classes
        }
        return []
    }

    var count: Int? {
        switch self {
        case .notRequested, .unavailable, .failed:
            return nil
        case let .loaded(classes):
            return classes.count
        }
    }
}

struct PTLoadedLibraryDetails: Sendable, Hashable {
    let fileSize: UInt64?
    let mappedSize: UInt64?
    let architecture: String?
    let uuid: UUID?
    let backing: PTLoadedBinaryBacking
    let capabilities: Set<PTLoadedLibraryCapability>
    let swiftMetadata: PTSwiftMetadataSummary
    let objcClasses: PTObjCClassInspectionResult
    let segments: [PTMachOSegment]
    let machOFailure: String?

    static func metadata(fileSize: UInt64?,
                         mappedSize: UInt64?,
                         architecture: String?,
                         uuid: UUID?,
                         backing: PTLoadedBinaryBacking,
                         capabilities: Set<PTLoadedLibraryCapability>,
                         swiftMetadata: PTSwiftMetadataSummary,
                         segments: [PTMachOSegment],
                         machOFailure: String?) -> PTLoadedLibraryDetails {
        PTLoadedLibraryDetails(fileSize: fileSize,
                                mappedSize: mappedSize,
                                architecture: architecture,
                                uuid: uuid,
                                backing: backing,
                                capabilities: capabilities,
                                swiftMetadata: swiftMetadata,
                                objcClasses: .notRequested,
                                segments: segments,
                                machOFailure: machOFailure)
    }
}

struct PTLoadedLibrary: Identifiable, Sendable, Hashable {
    let id: String
    let name: String
    let path: String
    let kind: PTLoadedLibraryKind
    let headerAddress: UInt
    let vmAddressSlide: Int

    var fileSize: UInt64?
    var mappedSize: UInt64?
    var architecture: String?
    var uuid: UUID?
    var backing: PTLoadedBinaryBacking
    var capabilities: Set<PTLoadedLibraryCapability>
    var objcClassCount: Int?
    var objcInspection: PTObjCClassInspectionResult
    var swiftMetadata: PTSwiftMetadataSummary
    var segments: [PTMachOSegment]
    var classes: [String]
    var inspectionState: PTLoadedLibraryInspectionState
    var isExpanded: Bool

    init(snapshot: PTLoadedImageSnapshot) {
        id = snapshot.identifier
        name = snapshot.name
        path = snapshot.path
        kind = PTLoadedLibraryClassifier.kind(for: snapshot)
        headerAddress = snapshot.headerAddress
        vmAddressSlide = snapshot.vmAddressSlide
        fileSize = nil
        mappedSize = nil
        architecture = nil
        uuid = nil
        backing = .unknown
        capabilities = snapshot.fileType == nil ? [] : [.validHeader]
        objcClassCount = nil
        objcInspection = .notRequested
        swiftMetadata = .unavailable
        segments = []
        classes = []
        inspectionState = .idle
        isExpanded = false
    }

    // English: Preserve the old filter contract while the model exposes richer image kinds.
    // Español: Conserva el contrato de filtros antiguo mientras el modelo expone tipos de imagen más precisos.
    // 中文：在模型提供更细分类别的同时保留旧筛选契约。
    var isPrivate: Bool { kind.isPrivateCompatibilityValue }

    // English: Keep the legacy display field as a compatibility projection, never as source data.
    // Español: Mantiene el campo visual heredado como proyección compatible, nunca como dato fuente.
    // 中文：保留旧显示字段作为兼容投影，不再作为源数据。
    var size: String {
        if let fileSize {
            return PTLoadedLibrary.byteCountString(fileSize)
        }
        if let mappedSize {
            return "File unavailable · Mapped \(PTLoadedLibrary.byteCountString(mappedSize))"
        }
        return backing == .unknown ? "Unavailable" : backing.displayName
    }

    var address: String {
        "0x\(String(headerAddress, radix: 16, uppercase: true))"
    }

    var slide: String {
        "0x\(String(vmAddressSlide, radix: 16, uppercase: true))"
    }

    var fileSizeDescription: String {
        fileSize.map(PTLoadedLibrary.byteCountString) ?? "Unavailable"
    }

    var mappedSizeDescription: String {
        mappedSize.map(PTLoadedLibrary.byteCountString) ?? "Unavailable"
    }

    var summaryDescription: String {
        "\(path)\n\(kind.displayName) · \(architecture ?? "Architecture unavailable")\nFile: \(fileSizeDescription) · Mapped: \(mappedSizeDescription)\nObjective-C Classes: \(objcClassesDescription) · Swift Metadata: \(swiftMetadataDescription)\nAddress: \(address) · Slide: \(slide)"
    }

    var objcClassesDescription: String {
        switch objcInspection {
        case .notRequested:
            return "Not Loaded"
        case let .loaded(classes):
            return "\(classes.count)"
        case let .unavailable(reason):
            return "Unavailable: \(reason)"
        case let .failed(message):
            return "Failed: \(message)"
        }
    }

    var swiftMetadataDescription: String {
        swiftMetadata.isAvailable ? "Available" : "Not Detected"
    }

    var expandedStatusText: String {
        switch inspectionState {
        case .loading:
            return "Loading Objective-C Classes…"
        case .unavailable(let reason):
            return "Objective-C Classes Unavailable: \(reason)"
        case .failed(let message):
            return "Objective-C Classes Failed: \(message)"
        case .partiallyLoaded, .idle:
            switch objcInspection {
            case .notRequested:
                return swiftMetadata.isAvailable ? "Objective-C Classes Not Loaded · Swift metadata detected" : "Objective-C Classes Not Loaded"
            case .loaded(let classes):
                return classes.isEmpty ? "No Objective-C runtime classes" : ""
            case .unavailable(let reason):
                return "Objective-C Classes Unavailable: \(reason)"
            case .failed(let message):
                return "Objective-C Classes Failed: \(message)"
            }
        case .loaded:
            return classes.isEmpty ? "No Objective-C runtime classes" : ""
        }
    }

    var isLoading: Bool {
        get { inspectionState == .loading }
        set {
            if newValue {
                inspectionState = .loading
            } else if inspectionState == .loading {
                inspectionState = .idle
            }
        }
    }

    mutating func apply(metadata: PTLoadedLibraryDetails) {
        fileSize = metadata.fileSize
        mappedSize = metadata.mappedSize
        architecture = metadata.architecture
        uuid = metadata.uuid
        backing = metadata.backing
        capabilities.formUnion(metadata.capabilities)
        swiftMetadata = metadata.swiftMetadata
        segments = metadata.segments
        if let failure = metadata.machOFailure {
            inspectionState = .partiallyLoaded
            if capabilities == [.validHeader] || capabilities.isEmpty {
                inspectionState = .failed(message: failure)
            }
        } else {
            inspectionState = .loaded
        }
    }

    mutating func apply(classes result: PTObjCClassInspectionResult) {
        switch result {
        case let .loaded(classes):
            self.classes = classes
            objcClassCount = classes.count
            objcInspection = result
            capabilities.insert(.objectiveCRuntime)
            inspectionState = .loaded
        case .notRequested:
            break
        case let .unavailable(reason):
            objcInspection = result
            inspectionState = .unavailable(reason: reason)
        case let .failed(message):
            objcInspection = result
            inspectionState = .failed(message: message)
        }
    }

    private static func byteCountString(_ value: UInt64) -> String {
        guard value <= UInt64(Int64.max) else { return "Unavailable" }
        return ByteCountFormatter.string(fromByteCount: Int64(value), countStyle: .binary)
    }
}

public struct PTLoadedLibsConfiguration: Sendable, Hashable {
    public var enablesSwiftMetadataInspection: Bool
    public var enablesObjectiveCRuntimeInspection: Bool
    public var enablesFileMetadataInspection: Bool
    public var enablesVerboseLogging: Bool
    public var runtimeClassSearchEnabled: Bool

    public init(enablesSwiftMetadataInspection: Bool = true,
                enablesObjectiveCRuntimeInspection: Bool = true,
                enablesFileMetadataInspection: Bool = true,
                enablesVerboseLogging: Bool = false,
                runtimeClassSearchEnabled: Bool = false) {
        self.enablesSwiftMetadataInspection = enablesSwiftMetadataInspection
        self.enablesObjectiveCRuntimeInspection = enablesObjectiveCRuntimeInspection
        self.enablesFileMetadataInspection = enablesFileMetadataInspection
        self.enablesVerboseLogging = enablesVerboseLogging
        self.runtimeClassSearchEnabled = runtimeClassSearchEnabled
    }

    public static let `default` = PTLoadedLibsConfiguration()
}

public struct PTLoadedLibsDiagnostics: Sendable, Hashable {
    public let imageCount: Int
    public let registryCount: Int
    public let callbackAddCount: Int
    public let callbackRemoveCount: Int
    public let unresolvedPathCount: Int
    public let fileUnavailableCount: Int
    public let machOFailureCount: Int
    public let objcRuntimeFailureCount: Int
    public let appImageCount: Int
    public let systemImageCount: Int
    public let sharedCacheCandidateCount: Int

    public init(imageCount: Int,
                registryCount: Int,
                callbackAddCount: Int,
                callbackRemoveCount: Int,
                unresolvedPathCount: Int,
                fileUnavailableCount: Int,
                machOFailureCount: Int,
                objcRuntimeFailureCount: Int,
                appImageCount: Int = 0,
                systemImageCount: Int = 0,
                sharedCacheCandidateCount: Int = 0) {
        self.imageCount = imageCount
        self.registryCount = registryCount
        self.callbackAddCount = callbackAddCount
        self.callbackRemoveCount = callbackRemoveCount
        self.unresolvedPathCount = unresolvedPathCount
        self.fileUnavailableCount = fileUnavailableCount
        self.machOFailureCount = machOFailureCount
        self.objcRuntimeFailureCount = objcRuntimeFailureCount
        self.appImageCount = appImageCount
        self.systemImageCount = systemImageCount
        self.sharedCacheCandidateCount = sharedCacheCandidateCount
    }
}
