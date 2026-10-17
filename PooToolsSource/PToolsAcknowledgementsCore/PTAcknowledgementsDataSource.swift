// English: The data source boundary lets custom UI consume the same manifest without importing UIKit.
// Español: El límite de fuente permite que una UI personalizada use el mismo manifest sin importar UIKit.
// 中文：数据源边界让自定义 UI 复用同一份 Manifest，而无需引入 UIKit。

import Foundation

public protocol PTAcknowledgementsDataSource: Sendable {
    func loadManifest() async throws -> PTLicenseManifest
}

public actor PTAcknowledgementsRepository {
    private let source: any PTAcknowledgementsDataSource
    private var cachedManifest: PTLicenseManifest?
    private var loadingTask: Task<PTLicenseManifest, Error>?

    public init(source: any PTAcknowledgementsDataSource = PTBundleAcknowledgementsDataSource()) {
        self.source = source
    }

    public func load(forceReload: Bool = false) async throws -> PTLicenseManifest {
        if !forceReload, let cachedManifest {
            return cachedManifest
        }
        if let loadingTask {
            return try await loadingTask.value
        }

        let source = self.source
        let task = Task { try await source.loadManifest() }
        loadingTask = task
        defer { loadingTask = nil }
        let manifest = try await task.value
        cachedManifest = manifest
        return manifest
    }

    public func reload() async throws -> PTLicenseManifest {
        try await load(forceReload: true)
    }

    public func invalidateCache() {
        cachedManifest = nil
    }
}
