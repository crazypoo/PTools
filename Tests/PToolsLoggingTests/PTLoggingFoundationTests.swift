//
//  PTLoggingFoundationTests.swift
//  PToolsLoggingTests
//
// English: Verifies filtering, privacy redaction and bounded logging for the 5.21.x pipeline.
// Español: Verifica el filtrado, la redacción de privacidad y el logging acotado de la tubería 5.21.x.
// 中文：验证 5.21.x 日志管线的过滤、隐私脱敏和有界写入。
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

    // English: The memory destination keeps diagnostics bounded while preserving important records.
    // Español: El destino de memoria mantiene los diagnósticos acotados y conserva los registros importantes.
    // 中文：内存日志目标限制诊断容量，同时保留重要等级的记录。
    func testMemoryDestinationKeepsBoundedSnapshotAndRedacts() async {
        let destination = PTMemoryLogDestination(capacity: 2,
                                                  queueCapacity: 32,
                                                  dropPolicy: .preferImportant)
        destination.append(makeRecord(sequence: 1,
                                      level: .info,
                                      message: "token=secret-value"))
        destination.append(makeRecord(sequence: 2,
                                      level: .warning,
                                      message: "warning"))
        destination.append(makeRecord(sequence: 3,
                                      level: .error,
                                      message: "error"))

        await destination.flush()

        let records = await destination.snapshot()
        XCTAssertEqual(records.count, 2)
        XCTAssertTrue(records.contains { $0.level == .warning })
        XCTAssertTrue(records.contains { $0.level == .error })
        XCTAssertFalse(records.contains { $0.message.contains("secret-value") })

        let pressure = await destination.backpressureSnapshot()
        XCTAssertGreaterThanOrEqual(pressure.bufferDroppedCount, 1)
    }

    // English: Verify that a strict drop-newest policy does not reorder retained records.
    // Español: Verifica que la política estricta de descartar el más nuevo no reordene los registros retenidos.
    // 中文：验证严格丢弃最新记录的策略不会重排已保留记录。
    func testMemoryDestinationDropNewestPolicy() async {
        let destination = PTMemoryLogDestination(capacity: 1,
                                                  queueCapacity: 8,
                                                  dropPolicy: .dropNewest)
        destination.append(makeRecord(sequence: 1, level: .info, message: "first"))
        destination.append(makeRecord(sequence: 2, level: .info, message: "second"))

        await destination.flush()

        let records = await destination.snapshot()
        XCTAssertEqual(records.map(\.sequence), [1])
        let pressure = await destination.backpressureSnapshot()
        XCTAssertGreaterThanOrEqual(pressure.bufferDroppedCount, 1)
    }

    // English: Multiple consumers must receive the same immutable record snapshot.
    // Español: Varios consumidores deben recibir el mismo snapshot de registro inmutable.
    // 中文：多个消费者必须收到同一份不可变日志快照。
    func testMemoryDestinationSupportsMultipleSubscribers() async {
        let destination = PTMemoryLogDestination(capacity: 8, queueCapacity: 8)
        let firstStream = await destination.subscribe()
        let secondStream = await destination.subscribe()
        var firstIterator = firstStream.makeAsyncIterator()
        var secondIterator = secondStream.makeAsyncIterator()

        destination.append(makeRecord(sequence: 1, level: .info, message: "shared"))
        await destination.flush()

        let first = await firstIterator.next()
        let second = await secondIterator.next()
        XCTAssertEqual(first?.sequence, 1)
        XCTAssertEqual(second?.sequence, 1)
        XCTAssertEqual(first?.message, second?.message)
    }

    // English: Sampling policies are deterministic and safe for concurrent callers to copy.
    // Español: Las políticas de muestreo son deterministas y seguras para copiar entre llamadas concurrentes.
    // 中文：采样策略具有确定性，可以安全地在并发调用之间复制。
    func testSamplingPolicy() {
        XCTAssertTrue(PTLogSamplingPolicy.all.accepts(index: 0))
        XCTAssertTrue(PTLogSamplingPolicy.every(3).accepts(index: 6))
        XCTAssertFalse(PTLogSamplingPolicy.every(3).accepts(index: 7))
        XCTAssertTrue(PTLogSamplingPolicy.first(2).accepts(index: 1))
        XCTAssertFalse(PTLogSamplingPolicy.first(2).accepts(index: 3))
    }

    private func makeRecord(sequence: UInt64,
                            level: PTLogLevel,
                            message: String) -> PTLogRecord {
        PTLogRecord(sequence: sequence,
                    level: level,
                    subsystem: "com.example.tests",
                    category: .performance,
                    message: message,
                    file: #fileID,
                    function: #function,
                    line: #line)
    }
}
