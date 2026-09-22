//
//  PTLoggingFoundationTests.swift
//  PToolsLoggingTests
//
// English: Verifies filtering, privacy redaction and bounded file logging for the 5.20.x foundation.
// Español: Verifica el filtrado, la redacción de privacidad y el logging de archivos acotado de 5.20.x.
// 中文：验证 5.20.x 日志基础层的过滤、隐私脱敏和有界文件写入。
//

import Foundation
import XCTest
@testable import PToolsLogging

final class PTLoggingFoundationTests: XCTestCase {
    func testLogLevelOrderingAndCustomCategory() {
        XCTAssertLessThan(PTLogLevel.debug, .warning)
        XCTAssertGreaterThan(PTLogLevel.fault, .error)

        let obd = PTLogCategory(rawValue: "OBD")
        XCTAssertEqual(obd.rawValue, "OBD")
        XCTAssertNotEqual(obd, .network)
    }

    func testFilteringUsesCategoryLevelBeforeGlobalLevel() {
        let original = PTLogger.configuration
        defer {
            PTLogger.configure { configuration in
                configuration.minimumLevel = original.minimumLevel
                configuration.categoryLevels = original.categoryLevels
                configuration.subsystem = original.subsystem
            }
        }

        PTLogger.configure { configuration in
            configuration.minimumLevel = .warning
            configuration.categoryLevels = [.network: .debug]
        }

        XCTAssertFalse(PTLogger.isEnabled(level: .info, category: .general))
        XCTAssertTrue(PTLogger.isEnabled(level: .debug, category: .network))
        XCTAssertTrue(PTLogger.isEnabled(level: .error, category: .general))
    }

    func testRedactorHandlesSensitiveKeysAndPrivacy() {
        XCTAssertTrue(PTLogRedactor.isSensitiveKey("Authorization"))
        XCTAssertTrue(PTLogRedactor.isSensitiveKey("refresh_token"))
        XCTAssertEqual(PTLogRedactor.redact(message: "secret", privacy: .sensitive), "[REDACTED]")

        let metadata = PTLogRedactor.redact(metadata: [
            "Authorization": "Bearer secret",
            "statusCode": "200"
        ])
        XCTAssertEqual(metadata["Authorization"], "[REDACTED]")
        XCTAssertEqual(metadata["statusCode"], "200")
    }

    func testFileDestinationWritesRedactedRecord() async throws {
        let directoryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("PToolsLoggingTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directoryURL) }

        let configuration = PTLogFileConfiguration(directoryURL: directoryURL,
                                                    maximumFileSize: 1024,
                                                    maximumFiles: 3,
                                                    retentionDays: 7 * 24 * 60 * 60,
                                                    maximumTotalSize: 8 * 1024,
                                                    bufferSize: 1)
        let destination = PTFileLogDestination(configuration: configuration)
        destination.append(PTLogRecord(sequence: 1,
                                       level: .info,
                                       subsystem: "com.example.tests",
                                       category: .network,
                                       message: "request completed",
                                       metadata: ["Authorization": "Bearer secret", "statusCode": "200"],
                                       privacy: .public,
                                       file: #fileID,
                                       function: #function,
                                       line: #line))

        await destination.flush()

        let files = await PTFileLogDestination.logFiles(configuration: configuration)
        XCTAssertEqual(files.count, 1)
        let contents = try String(contentsOf: try XCTUnwrap(files.first), encoding: .utf8)
        XCTAssertTrue(contents.contains("Authorization=[REDACTED]"))
        XCTAssertTrue(contents.contains("statusCode=200"))
        XCTAssertFalse(contents.contains("Bearer secret"))
    }

    func testFileDestinationKeepsRetentionBoundDuringRotation() async throws {
        let directoryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("PToolsLoggingRotationTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directoryURL) }

        let configuration = PTLogFileConfiguration(directoryURL: directoryURL,
                                                    maximumFileSize: 256,
                                                    maximumFiles: 3,
                                                    retentionDays: 7 * 24 * 60 * 60,
                                                    maximumTotalSize: 8 * 1024,
                                                    bufferSize: 1)
        let destination = PTFileLogDestination(configuration: configuration)
        for sequence in 1...40 {
            destination.append(PTLogRecord(sequence: UInt64(sequence),
                                           level: .debug,
                                           subsystem: "com.example.tests",
                                           category: .performance,
                                           message: String(repeating: "x", count: 80),
                                           file: #fileID,
                                           function: #function,
                                           line: #line))
        }

        await destination.flush()

        let files = await PTFileLogDestination.logFiles(configuration: configuration)
        XCTAssertLessThanOrEqual(files.count, 3)
        XCTAssertFalse(files.isEmpty)
    }

    func testFileDestinationHandlesConcurrentStress() async throws {
        let directoryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("PToolsLoggingStressTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directoryURL) }

        let configuration = PTLogFileConfiguration(directoryURL: directoryURL,
                                                    maximumFileSize: 5 * 1024 * 1024,
                                                    maximumFiles: 3,
                                                    retentionDays: 7 * 24 * 60 * 60,
                                                    maximumTotalSize: 16 * 1024 * 1024,
                                                    bufferCapacity: 5_000,
                                                    bufferSize: 32 * 1024)
        let destination = PTFileLogDestination(configuration: configuration)

        // English: Exercise 100 concurrent producers with 1,000 records each.
        // Español: Ejecuta 100 productores concurrentes con 1.000 registros cada uno.
        // 中文：使用 100 个并发生产者，每个生产 1,000 条日志。
        await withTaskGroup(of: Void.self) { group in
            for producer in 0..<100 {
                group.addTask {
                    for index in 0..<1_000 {
                        destination.append(PTLogRecord(sequence: UInt64(producer * 1_000 + index + 1),
                                                       level: .debug,
                                                       subsystem: "com.example.tests",
                                                       category: .performance,
                                                       message: "stress-\(producer)-\(index)",
                                                       file: #fileID,
                                                       function: #function,
                                                       line: #line))
                    }
                }
            }
        }

        await destination.flush()

        let files = await PTFileLogDestination.logFiles(configuration: configuration)
        XCTAssertFalse(files.isEmpty)
        XCTAssertLessThanOrEqual(files.count, 3)
        for file in files {
            let values = try file.resourceValues(forKeys: [.fileSizeKey])
            XCTAssertGreaterThan(values.fileSize ?? 0, 0)
        }
    }
}
