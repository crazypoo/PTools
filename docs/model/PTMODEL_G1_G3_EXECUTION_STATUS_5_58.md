# PTModel 5.58.0 — G1 / G2 / G3 执行状态

## 范围

本次严格关闭计划中的 G1、G2、G3。G4 的第三方 differential、property/fuzz、TSan、
真机、RSS/allocation、多平台和 Archive 不在本次范围内，保持 `⏸️`，不把本地证据
冒充为已完成。

## G1：Macro / Semantics / Boundary

- ✅ 独立 SwiftSyntax macro expansion / diagnostic golden suite。
- ✅ public 与 internal fixture。
- ✅ Observation 类型的明确诊断：宏不猜测 Observation storage，要求手写 Schema。
- ✅ `@objc dynamic` 类型的 Codable fallback 边界。
- ✅ generic `@PTModel` fixture，以及 generic `@PTSubclass` 不支持诊断。
- ✅ manual Codable fixture。
- ✅ duplicate encoded key 与重复 annotation 诊断。
- ✅ `@PTFlat` / `@PTPath` 非法组合，以及继承 flattened collision 诊断。
- ✅ 三层 parent / child / grandchild lifecycle 顺序 golden。

G1 的外部 SmartCodable/KakaJSON parity 没有宣称完成；那属于 G4。

## G2：Direct / Schema / Runtime

本轮选择第二种方案：不为了追求 Direct 覆盖率而复制 annotation side effect，正式冻结
以下边界：

| 能力 | 决策 | 可验证行为 |
| --- | --- | --- |
| 普通不可变字段 | Direct | `ptUsesDirectPath == true`，稳定字段扫描、解码和编码保持一致。 |
| `@PTTransform` / `@PTValidate` | `INTENTIONAL_DIFFERENCE / SCHEMA_BOUNDARY` | 标注模型退出 Direct，decode/encode phase 只在 Schema 路径执行一次。 |
| `@PTPolymorphic` | `INTENTIONAL_DIFFERENCE / SCHEMA_BOUNDARY` | discriminator、registry、typed resolver 保留运行时上下文。 |
| `@PTExtras` | `INTENTIONAL_DIFFERENCE / EXPLICIT_OPT_IN` | 普通 decode 不改变模型状态；`decodeWithExtras` 才捕获并 attach 未知字段。 |
| `@objc dynamic` / Observation | `INTENTIONAL_DIFFERENCE / CODABLE_FALLBACK` | 不使用不安全反射；通过诊断或手写 Schema 明确接入。 |

已补验证：

- ✅ Direct 与 Schema fallback 行为 golden。
- ✅ Extras 普通 decode / opt-in decodeWithExtras / encode round-trip。
- ✅ Dynamic + Polymorphic + Patch 组合回归。
- ✅ actor-backed Sink 1000 次写入 contention benchmark。
- ✅ Release benchmark 记录在 [PTMODEL_BEHAVIOR_DIFFERENCES.md](PTMODEL_BEHAVIOR_DIFFERENCES.md)
  和 [PTMODEL_BENCHMARKS_5_58.md](PTMODEL_BENCHMARKS_5_58.md)。

## G3：Consumer / CocoaPods / iOS Host

- ✅ SmartCodable legacy SwiftPM consumer build + run。
- ✅ KakaJSON legacy SwiftPM consumer build + run。
- ✅ Mixed legacy consumer build + run。
- ✅ PTModel-only consumer build + run。
- ✅ CocoaPods `pod install --no-repo-update`，且工作区跟踪输入未被修改。
- ✅ `PooTools-Example` 的 Swift 6 / iOS 17 配置检查。
- ✅ `Appz` legacy compatibility target 的 Swift 5 配置检查。
- ✅ `PooTools-Example` 真实 CocoaPods workspace Debug Simulator build。
- ✅ `PooTools-Example` 真实 CocoaPods workspace Release Simulator build。
- ✅ 可用 iOS Simulator 的显式 build、install、launch、terminate。
- ✅ `PToolsNetworkTests` 使用 iOS 17 Simulator SDK / arm64 编译。
- ✅ typed executor 与 legacy transport 共用同一个 URLProtocol host fixture，响应、状态码和 payload 契约已冻结在测试源中。
- ✅ `internalSmartCodableImports = 0`、`internalKakaJSONImports = 0`、`remainingLegacyNetworkCalls = 0`。

统一门禁入口：

```sh
bash Scripts/PTModel/validate_f1_f3.sh
```

最终结果：

```text
PASS: PTModel G1/G2/G3 deterministic and iOS host gates
```

## 验证证据

| 检查 | 结果 |
| --- | --- |
| `PTModelCoreTests` | 38 tests passed |
| `PTModelMacroGoldenTests` | 13 tests passed |
| `PTModelBenchmark` Release，1000 models / 5 iterations | passed；1000 concurrent encode/decode completed |
| `PToolsNetworkTests` iOS 17 Simulator SDK / arm64 | passed compile |
| SwiftPM consumer fixtures | 4 build + run passed |
| CocoaPods install | passed；tracked status unchanged |
| PooTools-Example Debug / Release | passed |
| Simulator install / launch | passed |
| `git diff --check` / `swift package dump-package` | passed |

## G4 状态

⏸️ 未执行：真实 SmartCodable/KakaJSON differential、完整 property-based/fuzz、TSan、
真机 RSS/allocation、网络开销矩阵、宏构建成本矩阵、多平台/Archive、GitHub required checks
和正式 tag。用户明确将 G4 真机流程留给真实项目验证，因此本文件不标记 G4 完成。

