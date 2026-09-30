# PTModel 5.58.0 API / Contract Freeze

## 已冻结的公共契约

- `PTModelDecoder` / `PTModelEncoder` 的 policy、strategy、limits 和 session 参数。
- `PTPresence` 的 Missing / Null / Value 语义。
- `PTModelFieldDescriptor`、`PTFieldRecovery`、`PTModelDiagnostic` 和 validator。
- `PTModelSchema`、`PTStaticModel`、`PTStaticCodec` 和 `PTStableKeyHash`。
- `PTModelPatch` / `PTModelDiff` / `PTModelClone` / `PTModelConverter`。
- `PTModelMigrationChain`、`PTExtras` 和 JSON Schema 导出。
- `PTModelStreamDecoder` / `PTModelStreamEncoder` 及 async/file sink。
- `PTNetworkResponseDecoder` 的 Sendable 泛型路径与 `PTNetworkLegacyResponseDecoder`
  的 MainActor 兼容边界。

## 兼容约束

- 不删除 `PTBaseModel`、SmartCodable、KakaJSON 或旧 Network 入口。
- CocoaPods 不引入 SwiftSyntax；宏调用方需要 SwiftPM，Pods 使用手写 Schema。
- 新增字段使用追加参数或新类型，不改变既有初始化器的默认行为。
- 所有跨 actor 的新模型必须是值类型或 `Sendable`；动态 `Any` 只停留在兼容层。

## 未伪造为已通过的门禁

当前 macOS `swift test --filter PTModelCoreTests` 会因为包中其它 UIKit target
被 macOS SDK 构建而阻断；这不是 PTModelCore 的失败证据。完整 iOS workspace
Debug/Release、CocoaPods、真机、TSan、Archive 和第三方 differential fixture 必须
在对应宿主环境继续验证后，才可以创建正式 `5.58.0` tag。
