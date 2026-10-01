# PTModel 5.58.0 基准测试

## 运行方式

仓库内提供真实 SwiftPM runner，不使用静态 manifest 代替测量：

```sh
PTMODEL_BENCHMARK_COUNT=1000 \
PTMODEL_BENCHMARK_ITERATIONS=5 \
Scripts/PTModel/run_benchmarks.sh
```

也可以直接运行：

```sh
swift run PTModelBenchmark --count 1000 --iterations 5
```

输出为 JSON，包含：

- 编码和解码 P50/P95 毫秒数。
- Direct 字段与 Schema fallback 单对象循环的 P50 毫秒数。
- 1000-task 并发编码/解码完成数。
- 编码后的字节数。
- models/sec 和 bytes/sec。
- 样本数量与迭代次数。

## 本次基线

2026-09-30 本机 Debug 基线（Apple Silicon Simulator/macOS host 的 SwiftPM
Foundation target）：

```json
{"encodeP50Milliseconds":3.043209,"decodeP95Milliseconds":24.609583,"encodeP95Milliseconds":3.178458,"iterations":5,"decodeP50Milliseconds":24.138416,"modelsPerSecond":72796.7833314468,"bytesPerSecond":3748342.7721278616,"encodedBytes":102981,"count":1000}
```

该基线测量默认兼容编码路径；`canonical` 是单独的显式契约，不能用这组数据替代验证。
这只是可复现基线，不代表所有设备的性能承诺。Release、真机、内存峰值、分配次数
和第三方兼容路径需要在目标工程中单独采样；没有对照数据时不宣称“更快”。

## G2 Direct / Schema 边界基线

2026-10-01 本机 Release 基线（Apple Silicon Simulator/macOS host，1000 models，5 iterations）：

```json
{"encodeP50Milliseconds":3.009292,"encodeP99Milliseconds":3.137875,"schemaFallbackEncodeP50Milliseconds":4.791084,"bytesPerSecond":7633145.997183161,"encodeP95Milliseconds":3.137875,"decodeP99Milliseconds":7.992083,"decodeP95Milliseconds":7.992083,"directDecodeP50Milliseconds":14.910292,"directEncodeP50Milliseconds":11.154084,"decodeP50Milliseconds":7.860292,"count":1000,"concurrentEncodeCount":1000,"concurrentDecodeCount":1000,"encodedBytes":102981,"modelsPerSecond":148243.7730684915,"iterations":5,"schemaFallbackDecodeP50Milliseconds":8.394667}
```

这组数据只用于冻结 Direct、Schema fallback 和并发 Sink 的可重复测量；Direct/Schema
循环的工作单元不同，不能直接解读为端到端加速承诺。G4 的真机 RSS、allocation、TSan
和第三方 differential 仍保持未完成。
