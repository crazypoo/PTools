//
//  PTModel benchmark runner
//
// English: Measure real PTModel encode/decode throughput with a reproducible JSON output.
// Español: Mide el rendimiento real de codificación/decodificación PTModel con JSON reproducible.
// 中文：用可复现的 JSON 输出测量真实 PTModel 编码和解码吞吐量。
//

import Foundation
import PToolsModel

@PTModel
public struct BenchmarkModel: Codable, Sendable {
    public let id: Int
    public let name: String
    public let tags: [String]
    public let nested: Nested

    public struct Nested: Codable, Sendable {
        public let active: Bool
        public let score: Double
    }
}

// English: Keep annotation hooks in a measured Schema-fallback fixture instead of pretending they are raw direct fields.
// Español: Mantiene los hooks de anotación en un fixture medido de fallback Schema sin fingir que son campos directos.
// 中文：使用可测量的 Schema 回退夹具承载注解钩子，不把它伪装成原始 Direct 字段。
@PTModel
public struct BenchmarkSchemaFallbackModel: Codable, Sendable, PTModelAnnotationProvider {
    @PTTransform
    public let title: String
    @PTValidate
    public let count: Int

    public init(title: String, count: Int) {
        self.title = title
        self.count = count
    }

    public static func ptTransform(value: PTJSONValue,
                                   field: PTModelFieldDescriptor,
                                   phase: PTModelAnnotationPhase) throws -> PTJSONValue? {
        guard field.name == "title", case .string(let title) = value else { return nil }
        return .string(phase == .decode ? title.uppercased() : title.lowercased())
    }

    public static func ptValidate(value: PTJSONValue,
                                  field: PTModelFieldDescriptor,
                                  phase: PTModelAnnotationPhase) throws {
        guard field.name == "count",
              case .number(let number) = value,
              Int(number.rawRepresentation) ?? -1 >= 0 else {
            throw PTModelError.validationFailed("count must be non-negative")
        }
    }
}

private struct BenchmarkResult: Codable, Sendable {
    let count: Int
    let iterations: Int
    let encodedBytes: Int
    let encodeP50Milliseconds: Double
    let encodeP95Milliseconds: Double
    let encodeP99Milliseconds: Double
    let decodeP50Milliseconds: Double
    let decodeP95Milliseconds: Double
    let decodeP99Milliseconds: Double
    let directDecodeP50Milliseconds: Double
    let schemaFallbackDecodeP50Milliseconds: Double
    let directEncodeP50Milliseconds: Double
    let schemaFallbackEncodeP50Milliseconds: Double
    let concurrentEncodeCount: Int
    let concurrentDecodeCount: Int
    let modelsPerSecond: Double
    let bytesPerSecond: Double
}

private func percentile(_ values: [Double], fraction: Double) -> Double {
    guard !values.isEmpty else { return 0 }
    let sorted = values.sorted()
    let position = min(sorted.count - 1, Int(Double(sorted.count - 1) * fraction))
    return sorted[position]
}

private func elapsedMilliseconds(_ operation: () throws -> Void) rethrows -> Double {
    let start = DispatchTime.now().uptimeNanoseconds
    try operation()
    let end = DispatchTime.now().uptimeNanoseconds
    return Double(end - start) / 1_000_000
}

private func argument(named name: String, default defaultValue: Int) -> Int {
    guard let index = CommandLine.arguments.firstIndex(of: name),
          let next = CommandLine.arguments.dropFirst(index + 1).first,
          let value = Int(next), value > 0 else {
        return defaultValue
    }
    return value
}

// English: Run an explicit 1,000-task stress pass over immutable encoder and decoder values.
// Español: Ejecuta una prueba explícita de 1.000 tareas sobre encoders y decoders inmutables.
// 中文：对不可变 encoder 和 decoder 执行明确的 1,000 任务并发压力测试。
private func runConcurrentStress(models: [BenchmarkModel],
                                 encoder: PTModelEncoder,
                                 decoder: PTModelDecoder) async throws -> (encode: Int, decode: Int) {
    guard let model = models.first else { throw PTModelError.invalidInput }
    let data = try encoder.encode(model)
    let count = 1_000
    let encodeCount = try await withThrowingTaskGroup(of: Bool.self, returning: Int.self) { group in
        for _ in 0..<count {
            group.addTask {
                _ = try encoder.encode(model)
                return true
            }
        }
        var completed = 0
        for try await succeeded in group where succeeded { completed += 1 }
        return completed
    }
    let decodeCount = try await withThrowingTaskGroup(of: Bool.self, returning: Int.self) { group in
        for _ in 0..<count {
            group.addTask {
                _ = try decoder.decode(BenchmarkModel.self, from: data)
                return true
            }
        }
        var completed = 0
        for try await succeeded in group where succeeded { completed += 1 }
        return completed
    }
    return (encodeCount, decodeCount)
}

@main
struct PTModelBenchmarkMain {
    static func main() async {
        do {
            let count = argument(named: "--count", default: 1_000)
            let iterations = argument(named: "--iterations", default: 5)
            let models = (0..<count).map { index in
                BenchmarkModel(id: index,
                               name: "model-\(index)",
                               tags: ["ptmodel", "benchmark", "\(index % 8)"],
                               nested: .init(active: index.isMultiple(of: 2),
                                             score: Double(index) / 10))
            }
            // English: Measure the default compatibility path; canonical mode is a separate opt-in contract.
            // Español: Mide la ruta de compatibilidad predeterminada; el modo canónico es un contrato opt-in separado.
            // 中文：基准测试默认兼容路径；canonical 模式是单独的显式选择契约。
            let encoder = PTModelEncoder(sortedKeys: true)
            let decoder = PTModelDecoder(policy: .strict)
            let directSample = BenchmarkModel(id: 1,
                                              name: "direct",
                                              tags: ["ptmodel"],
                                              nested: .init(active: true, score: 1))
            let directSampleData = try PTStaticCodec.encode(directSample)
            let fallbackSampleData = Data(#"{"title":"fallback","count":2}"#.utf8)
            let fallbackSample = try PTStaticCodec.decode(BenchmarkSchemaFallbackModel.self,
                                                           from: fallbackSampleData)
            var encodeMeasurements: [Double] = []
            var decodeMeasurements: [Double] = []
            var directDecodeMeasurements: [Double] = []
            var schemaFallbackDecodeMeasurements: [Double] = []
            var directEncodeMeasurements: [Double] = []
            var schemaFallbackEncodeMeasurements: [Double] = []
            var encodedData = Data()

            for _ in 0..<iterations {
                encodeMeasurements.append(try elapsedMilliseconds {
                    encodedData = try encoder.encode(models)
                })
                decodeMeasurements.append(try elapsedMilliseconds {
                    _ = try decoder.decode([BenchmarkModel].self, from: encodedData)
                })
                directDecodeMeasurements.append(try elapsedMilliseconds {
                    for _ in models {
                        _ = try PTStaticCodec.decode(BenchmarkModel.self,
                                                      from: directSampleData)
                    }
                })
                schemaFallbackDecodeMeasurements.append(try elapsedMilliseconds {
                    for _ in models {
                        _ = try PTStaticCodec.decode(BenchmarkSchemaFallbackModel.self,
                                                      from: fallbackSampleData)
                    }
                })
                directEncodeMeasurements.append(try elapsedMilliseconds {
                    for _ in models {
                        _ = try PTStaticCodec.encode(directSample)
                    }
                })
                schemaFallbackEncodeMeasurements.append(try elapsedMilliseconds {
                    for _ in models {
                        _ = try PTStaticCodec.encode(fallbackSample)
                    }
                })
            }

            let stress = try await runConcurrentStress(models: models,
                                                       encoder: encoder,
                                                       decoder: decoder)
            let totalSeconds = (encodeMeasurements.reduce(0, +) + decodeMeasurements.reduce(0, +)) / 1_000
            let result = BenchmarkResult(count: count,
                                         iterations: iterations,
                                         encodedBytes: encodedData.count,
                                         encodeP50Milliseconds: percentile(encodeMeasurements, fraction: 0.50),
                                         encodeP95Milliseconds: percentile(encodeMeasurements, fraction: 0.95),
                                         encodeP99Milliseconds: percentile(encodeMeasurements, fraction: 0.99),
                                         decodeP50Milliseconds: percentile(decodeMeasurements, fraction: 0.50),
                                         decodeP95Milliseconds: percentile(decodeMeasurements, fraction: 0.95),
                                         decodeP99Milliseconds: percentile(decodeMeasurements, fraction: 0.99),
                                         directDecodeP50Milliseconds: percentile(directDecodeMeasurements, fraction: 0.50),
                                         schemaFallbackDecodeP50Milliseconds: percentile(schemaFallbackDecodeMeasurements, fraction: 0.50),
                                         directEncodeP50Milliseconds: percentile(directEncodeMeasurements, fraction: 0.50),
                                         schemaFallbackEncodeP50Milliseconds: percentile(schemaFallbackEncodeMeasurements, fraction: 0.50),
                                         concurrentEncodeCount: stress.encode,
                                         concurrentDecodeCount: stress.decode,
                                         modelsPerSecond: totalSeconds > 0 ? Double(count * iterations * 2) / totalSeconds : 0,
                                         bytesPerSecond: totalSeconds > 0 ? Double(encodedData.count * iterations) / totalSeconds : 0)
            let output = try JSONEncoder().encode(result)
            guard let string = String(data: output, encoding: .utf8) else {
                throw PTModelError.conversionFailed("Benchmark result is not UTF-8")
            }
            print(string)
        } catch {
            FileHandle.standardError.write(Data("PTModelBenchmark failed: \(error.localizedDescription)\n".utf8))
            exit(1)
        }
    }
}
