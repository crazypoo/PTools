//
//  PTLoggingPerformanceTests.swift
//  PToolsLoggingTests
//
// English: Measures the bounded memory append path used by Debug and Instruments.
// Español: Mide la ruta acotada de memoria usada por Debug e Instruments.
// 中文：测量 Debug 和 Instruments 使用的有界内存追加路径。
//

import XCTest
@testable import PToolsLogging

final class PTLoggingPerformanceTests: XCTestCase {
    func testMemoryDestinationAppendPerformance() async {
        let destination = PTMemoryLogDestination(capacity: 100_000,
                                                  queueCapacity: 100_000,
                                                  dropPolicy: .dropOldest)
        let template = PTLogRecord(sequence: 0,
                                   level: .debug,
                                   subsystem: "com.example.tests",
                                   category: .performance,
                                   message: "benchmark",
                                   file: #fileID,
                                   function: #function,
                                   line: #line)

        measure {
            for sequence in 0..<10_000 {
                destination.append(PTLogRecord(sequence: UInt64(sequence),
                                               timestamp: template.timestamp,
                                               level: template.level,
                                               subsystem: template.subsystem,
                                               category: template.category,
                                               message: template.message,
                                               metadata: template.metadata,
                                               privacy: template.privacy,
                                               file: template.file,
                                               function: template.function,
                                               line: template.line))
            }
        }

        await destination.flush()
        let records = await destination.snapshot()
        XCTAssertFalse(records.isEmpty)
    }
}
