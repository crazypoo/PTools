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
