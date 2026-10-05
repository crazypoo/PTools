// English: File-backed resume data keeps interrupted downloads recoverable without retaining file bytes in memory.
// Español: Los datos de reanudación en archivos permiten recuperar descargas interrumpidas sin retener bytes en memoria.
// 中文：文件化 resume data 让中断下载可恢复，同时不把文件内容长期放在内存中。

import Foundation
#if SWIFT_PACKAGE
import PToolsTransferCore
#endif

public actor PTFileTransferResumeStore: PTTransferResumeStore {
    public let directoryURL: URL

    public init(directoryURL: URL) {
        self.directoryURL = directoryURL
    }

    public func load(for id: PTTransferID) async throws -> Data? {
        let url = fileURL(for: id)
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        return try Data(contentsOf: url)
    }

    public func save(_ data: Data, for id: PTTransferID) async throws {
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        try data.write(to: fileURL(for: id), options: [.atomic])
    }

    public func remove(for id: PTTransferID) async throws {
        let url = fileURL(for: id)
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        try FileManager.default.removeItem(at: url)
    }

    private func fileURL(for id: PTTransferID) -> URL {
        directoryURL.appendingPathComponent(id.rawValue.uuidString).appendingPathExtension("resume")
    }
}
