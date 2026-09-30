//
//  benchmark_models.swift
//
// English: Forward to the package-owned benchmark runner so every benchmark uses one reproducible implementation.
// Español: Reenvía al runner de benchmarks del paquete para que todas las mediciones usen una implementación reproducible.
// 中文：转发到包内的基准测试 runner，确保所有测量使用同一套可复现实现。
//

import Foundation

let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
process.arguments = ["swift", "run", "PTModelBenchmark"] + Array(CommandLine.arguments.dropFirst())
process.currentDirectoryURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
try process.run()
process.waitUntilExit()
exit(process.terminationStatus)
