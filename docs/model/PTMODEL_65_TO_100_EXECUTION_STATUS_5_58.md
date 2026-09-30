# PTModel 5.58.0：65% → 100% 执行状态

> 本文记录 `/Users/jax/Downloads/PTools_5.58.0_PTModel_65_To_100_Final_Completion_Execution_Plan.md` 的实际执行结果。只有源码、构建和回归证据同时成立的条目才标记为已完成；设备、TSan、第三方差异和发布签名不会用静态检查代替。

## 已落地的公共契约

- ✅ `PTFieldRecovery` 支持固定默认值、`PTDefaultValueProvider` 闭包默认值、上下文读取、required/invalid/null/missing 决策和 `PTDecodeTrace`。
- ✅ `PTNumericOverflowPolicy` 已进入基础数值解码；支持错误、默认值和边界夹紧。
- ✅ `PTJSONPath`、多 key alias、Flat 字段、lossy collection、Stringified JSON、`Any` 到 `PTJSONValue`、Date/Data/URL、非有限浮点、未知枚举、lifecycle、extras、polymorphic registry 和 typed file store 已有 Foundation-only 实现。
- ✅ 字典 key strategy、Set 确定性排序、重复 key 策略、Patch/Diff/Clone/Converter、Schema migration 和 JSON Schema 元数据保持在 Core。
- ✅ `PToolsModelUIKit`、`PToolsModelCombine` 已与 Core 分层；Observation 适配器只在可用平台编译。
- ✅ `PTJSONFieldScanner` 支持未知字段跳过、稳定 hash 二次字符串校验、资源上限和重复 key 策略。
- ✅ `PTFieldRecovery` 已区分 missing/null/invalid/overflow/value；数值溢出会遵循 recovery policy，并保留独立的 overflow reason。
- ✅ `PTModelSchema.decode` 与 `PTStaticCodec.decode` 共用字段 alias/path/flat 归一化；直接调用 Schema 不再绕过 canonical input normalization。
- ✅ `PTModelPatch.fromPresence` 已明确 missing 不产生更新、null 产生显式 null、value 产生 set；补充 migration/defaults/extras 的组合入口。
- ✅ `PTModelChunkStreamDecoder` 支持任意 `AsyncSequence<Data>` 分块、跨块字符串/嵌套值、取消、错误索引和有界缓冲；`PTStaticJSONWriter` 为生成 Schema 提供直接字段写入入口。
- ✅ `PTFileDataChunkSequence` 与 `PTURLSessionDataChunkSequence` 提供有界 FileHandle/URLSession bytes source adapter，并传播取消与 HTTP 状态错误。
- ✅ `@PTModel` 现已生成字段 descriptor、默认值、Lossy、Stringified、推断类型和 struct 直接解码入口；class/`@PTSubclass` 默认关闭直接构造路径，保留 Codable 回退，避免伪造继承安全性。
- ✅ `PToolsModelUIKit`、`PToolsModelCombine` 和 Observation 适配器已加入 SwiftPM/源码分层；Core 仍不导入 UIKit、Combine 或 Observation。
- ✅ SmartCodable/KakaJSON 旧入口已提供显式 Legacy adapter 产品和 CocoaPods opt-in subspec；新 `requestPTModel` 使用 `Data` 优先的 `PTModelNetworkResponse<Model>`，旧 `PTNetworkResponse` 保持传输层 API 兼容。
- ✅ 分段控件保留原始 `public let lineView` 和旧角标 API；旧角标存储不再直接引用已弃用声明，无角标标题入口改走规范重载。

## 本轮构建证据

| 检查 | 结果 |
| --- | --- |
| Foundation-only Core Swift 6 strict concurrency module | ✅ `swift build --target PToolsModel` 通过 |
| PTModel macro expansion probe | ✅ defaults/lossy/stringified/direct path typecheck 通过 |
| PooTools CocoaPods iOS Simulator Debug | ✅ Xcode workspace 通过 |
| PooTools CocoaPods iOS Simulator Release | ✅ Xcode workspace 通过 |
| PooTools-Example CocoaPods iOS Simulator Debug | ✅ Xcode workspace 通过 |
| PooTools-Example CocoaPods iOS Simulator Release | ✅ Xcode workspace 通过 |
| `pod install --no-repo-update` | ✅ 通过；仅更新本地 PooTools checksum |
| `swift package dump-package` | ✅ 通过 |
| `pod ipc spec PooTools.podspec` | ✅ 通过 |
| `git diff --check` / PTModel 静态门禁 | ✅ 通过 |
| PTModel target/benchmark 编译 | ✅ `swift build --target PToolsModelTests`、`swift build --target PTModelBenchmark` 通过 |
| PTModel 1000-task benchmark | ✅ 5 次迭代完成；P99 encode 3.027792 ms，P99 decode 24.120458 ms；encode/decode 各 1000 次 |
| PooTools 源码 Xcode 警告门禁（Debug / Release） | ✅ 通过；源码 warning 为 0，Pods 与工程警告单独报告 |
| Swift 6 严格并发 Xcode 警告门禁 | ⏸ 被外部 Pods 阻断：InAppViewDebugger、Swinject；未修改 Pods |
| `swift test --filter PTModelCoreTests` | ⏸ SwiftPM 当前把 UIKit targets 当作 macOS target 构建，`PooToolsSource/CheckBox/PTCheckBox.swift` 无法导入 UIKit；不是 iOS workspace 测试通过证明 |

## 仍不能诚实标记为 100% 的项

### Macro / inheritance

当前宏已生成字段 descriptor、CodingKeys、Key/Path/Required/Flat/Ignore 标记、默认值/Lossy/Stringified 的直接字段路径和字段值入口；以下能力仍需要独立实现与 golden test：transform/validate/polymorphic/extras 注解语义、property-wrapper/Observation/ObjC/generic 字段规则、N-level `@PTSubclass` superclass schema 合并和冲突编译诊断。

### Network / dependency split

Legacy adapter 产品已经分层，但 `Network.swift` 和 `PTNetworkModelBridge.swift` 仍保留历史 SmartCodable/KakaJSON 编译入口，内部业务模型尚未全部迁移。因此不能把 `internalSmartCodableImports == 0` 或 `internalKakaJSONImports == 0` 标记为通过。

### Correctness / performance proof

差分矩阵、property-based/fuzz、TSan 1000 并发回归、Release 真机基准、多平台 Archive 和真实 Consumer fixture 尚未在本机完成。Simulator benchmark 已执行 1000-task stress，但不能替代 TSan、真机内存/分配和行为 parity；当前仍只完成静态、宏展开、Core 编译、benchmark 和 iOS Simulator Debug/Release workspace 构建。

### 仍未执行的强制路线

- `PTStaticFieldDispatcher` 目前是“顶层字节扫描 + 字段值切片解码”，仍不是所有 primitive/collection/nested model 的最终无树直接解码器。
- Network 内部仍有 SmartCodable/KakaJSON 兼容入口，`audit_model_dependencies.swift` 当前仍报告 `internalSmartCodableImports=8`、`internalKakaJSONImports=3`、`remainingLegacyNetworkCalls=2`；不能提前移除依赖。
- Differential/property/fuzz/TSan、真实 Apple 设备 benchmark、macOS/tvOS/watchOS/visionOS Archive、SwiftPM/CocoaPods consumer fixture 和 API baseline 尚未执行。

## 版本与发布规则

- 当前版本继续为 `5.58.0`。
- 未完成 Stage D/E 的依赖迁移、差分、TSan、真机和发布门禁前，不创建新的 tag。
- CocoaPods 生成目录只作为构建产物；源码修复必须回到 `PooToolsSource`、`Package.swift` 和 `PooTools.podspec`。
