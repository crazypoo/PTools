//
//  PTMediaCache.swift
//  PooTools
//

import Foundation

// English: Cache variants are part of the key so originals, thumbnails, GIF frames, and Live Photo resources never collide.
// Español: Las variantes forman parte de la clave para que originales, miniaturas, GIF y Live Photo nunca colisionen.
// 中文：缓存变体属于键的一部分，避免原图、缩略图、GIF 帧和 Live Photo 资源互相覆盖。
public enum PTMediaCacheVariant: String, Hashable, Sendable {
    case original
    case thumbnail
    case processed
    case gifFrame
    case livePhotoImage
    case livePhotoVideo
    case videoThumbnail
}

// English: A stable cache key is derived from media identity and rendering intent, not Swift's randomized hashValue.
// Español: La clave estable se basa en la identidad y la intención de renderizado, no en hashValue aleatorio de Swift.
// 中文：缓存键由媒体身份和渲染意图稳定生成，不使用 Swift 每次变化的 hashValue。
public struct PTMediaCacheKey: Hashable, Sendable {
    public let resourceIdentifier: String
    public let variant: PTMediaCacheVariant
    public let pixelWidth: Int?
    public let pixelHeight: Int?
    public let frameNumber: Int?

    public init(resourceIdentifier: String,
                variant: PTMediaCacheVariant,
                pixelWidth: Int? = nil,
                pixelHeight: Int? = nil,
                frameNumber: Int? = nil) {
        self.resourceIdentifier = resourceIdentifier
        self.variant = variant
        self.pixelWidth = pixelWidth
        self.pixelHeight = pixelHeight
        self.frameNumber = frameNumber
    }

    var filename: String {
        let raw = [resourceIdentifier,
                   variant.rawValue,
                   pixelWidth.map(String.init) ?? "0",
                   pixelHeight.map(String.init) ?? "0",
                   frameNumber.map(String.init) ?? "0"].joined(separator: "|")
        return raw.data(using: .utf8)?.base64EncodedString()
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "+", with: "-") ?? UUID().uuidString
    }
}

// English: The actor serializes disk reads, writes, and quota maintenance for all media adapters.
// Español: El actor serializa lecturas, escrituras y mantenimiento de cuota para todos los adaptadores multimedia.
// 中文：Actor 统一串行化所有媒体适配层的磁盘读写和容量维护。
public actor PTMediaCache {
    public static let shared = PTMediaCache()

    private let directory: URL
    private let maximumDiskSize: Int64
    private let targetDiskSize: Int64
    private let maximumMemorySize: Int64 = 32 * 1024 * 1024
    private var memoryValues: [PTMediaCacheKey: Data] = [:]
    private var memorySize: Int64 = 0
    private var lastMaintenanceUptime: TimeInterval = 0

    public init(directory: URL? = nil,
                maximumDiskSize: Int64 = 150 * 1024 * 1024,
                targetDiskSize: Int64 = 100 * 1024 * 1024) {
        let baseURL = directory ?? (FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first ?? FileManager.default.temporaryDirectory)
        self.directory = baseURL.appendingPathComponent("PTMediaCache", isDirectory: true)
        self.maximumDiskSize = max(1, maximumDiskSize)
        self.targetDiskSize = max(1, min(targetDiskSize, maximumDiskSize))
        try? FileManager.default.createDirectory(at: self.directory, withIntermediateDirectories: true)
    }

    public func data(for key: PTMediaCacheKey) -> Data? {
        if let data = memoryValues[key] {
            return data
        }
        let url = fileURL(for: key)
        guard let data = try? Data(contentsOf: url, options: .mappedIfSafe), !data.isEmpty else {
            return nil
        }
        storeInMemory(data, for: key)
        touch(url)
        return data
    }

    public func insert(_ data: Data, for key: PTMediaCacheKey) {
        guard !data.isEmpty else { return }
        storeInMemory(data, for: key)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try? data.write(to: fileURL(for: key), options: .atomic)
        trimIfNeeded()
    }

    public func removeValue(for key: PTMediaCacheKey) {
        removeFromMemory(key)
        try? FileManager.default.removeItem(at: fileURL(for: key))
    }

    public func removeAll() {
        memoryValues.removeAll(keepingCapacity: false)
        memorySize = 0
        guard let files = try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil) else { return }
        for url in files {
            try? FileManager.default.removeItem(at: url)
        }
    }

    private func fileURL(for key: PTMediaCacheKey) -> URL {
        directory.appendingPathComponent(key.filename, isDirectory: false)
    }

    private func touch(_ url: URL) {
        try? FileManager.default.setAttributes([.modificationDate: Date()], ofItemAtPath: url.path)
    }

    private func storeInMemory(_ data: Data, for key: PTMediaCacheKey) {
        if let oldData = memoryValues.updateValue(data, forKey: key) {
            memorySize -= Int64(oldData.count)
        }
        memorySize += Int64(data.count)
        while memorySize > maximumMemorySize, let oldestKey = memoryValues.keys.first {
            removeFromMemory(oldestKey)
        }
    }

    private func removeFromMemory(_ key: PTMediaCacheKey) {
        guard let data = memoryValues.removeValue(forKey: key) else { return }
        memorySize -= Int64(data.count)
    }

    private func trimIfNeeded() {
        let now = ProcessInfo.processInfo.systemUptime
        guard now - lastMaintenanceUptime >= 60 else { return }
        lastMaintenanceUptime = now

        guard let files = try? FileManager.default.contentsOfDirectory(at: directory,
                                                                        includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey],
                                                                        options: [.skipsHiddenFiles]) else { return }
        var entries: [(url: URL, size: Int64, date: Date)] = []
        var totalSize: Int64 = 0
        for url in files {
            autoreleasepool {
                guard let values = try? url.resourceValues(forKeys: [.fileSizeKey, .contentModificationDateKey]),
                      let fileSize = values.fileSize,
                      fileSize > 0 else { return }
                let size = Int64(fileSize)
                totalSize += size
                entries.append((url, size, values.contentModificationDate ?? .distantPast))
            }
        }
        guard totalSize > maximumDiskSize else { return }
        entries.sort { $0.date < $1.date }
        for entry in entries {
            try? FileManager.default.removeItem(at: entry.url)
            totalSize -= entry.size
            if totalSize <= targetDiskSize { break }
        }
    }
}
