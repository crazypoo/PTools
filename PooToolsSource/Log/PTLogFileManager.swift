import Foundation

/// Serializes file output and bounds the on-device log file size.
public actor PTLogFileManager {
    public static let shared = PTLogFileManager()
    private let fileManager = FileManager.default
    private let maxFileSize: UInt64 = 5 * 1024 * 1024

    private init() {}

    public func append(logText: String) {
        let cachePath = FileManager.pt.CachesDirectory()
        let logURL = URL(fileURLWithPath: cachePath).appendingPathComponent("log.txt")

        guard let data = logText.data(using: .utf8) else { return }

        do {
            if !fileManager.fileExists(atPath: logURL.path) {
                fileManager.createFile(atPath: logURL.path, contents: nil, attributes: nil)
            }
            if let fileSize = try? logURL.resourceValues(forKeys: [.fileSizeKey]).fileSize,
               UInt64(fileSize) >= maxFileSize {
                try? fileManager.removeItem(at: logURL)
                fileManager.createFile(atPath: logURL.path, contents: nil, attributes: nil)
            }

            let fileHandle = try FileHandle(forWritingTo: logURL)
            defer { try? fileHandle.close() }
            try fileHandle.seekToEnd()
            fileHandle.write(data)
        } catch {
            print("❌ [PTLogFileManager] 写入日志文件失败: \(error)")
        }
    }
}
