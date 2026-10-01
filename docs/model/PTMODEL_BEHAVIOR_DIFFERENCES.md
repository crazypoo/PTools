# PTModel 行为差异与回滚

## 5.58.0 已知差异

- 普通 Codable 路径不读取 Swift 属性默认值；需要默认值时使用静态 Schema 的
  `PTFieldRecovery`，缺失非 Optional 字段仍由 Codable 决定是否报错。
- PTModel 不把 URL 字符串当成网络图片，不产生网络副作用。
- PTModel 不通过裸 `Any`、`Mirror` 或 Objective-C runtime 生成 Fast Path Schema。
- `PTPresence.missing` 在普通单值 Codable 编码中编码为 `null`；键控容器会省略
  missing，静态 Schema 通过 `PTModelEncoder.object(fields:)` 统一处理 omit/null。
- Foundation dictionary 中的 `Data` 使用 Base64 字符串桥接；模型字段的 Data strategy 由显式 API 控制：
  `.deferredToData` 使用字节数组，`.base64` 使用 Base64 字符串，`.utf8` 使用 UTF-8 字符串。
- 宏仅在 SwiftPM 产品中提供；CocoaPods 使用手写 Schema fallback，避免 SwiftSyntax
  污染 iOS 业务 target。
- Streaming 解码需要顶层数组，且输入 `Data` 由调用方持有；这不是自动的 URLSession
  网络分块代理。

## G1–G3 5.58.0 最终边界冻结

本轮只冻结本仓库可验证的 G1、G2、G3。以下差异是有意保留的 Schema boundary，
不是未发现的隐式回退：

| 场景 | 冻结决策 | 原因 |
| --- | --- | --- |
| `@PTTransform` / `@PTValidate` | `INTENTIONAL_DIFFERENCE / SCHEMA_BOUNDARY` | 注解需要明确的 decode/encode phase；统一走 Schema 可保证钩子只执行一次。 |
| `@PTPolymorphic` | `INTENTIONAL_DIFFERENCE / SCHEMA_BOUNDARY` | discriminator、registry 和 typed resolver 需要运行时上下文，不下沉为裸 Direct scanner。 |
| `@PTExtras` | `INTENTIONAL_DIFFERENCE / EXPLICIT_OPT_IN` | 普通 decode 不隐式改变模型状态；`decodeWithExtras` 才捕获并 attach 未知字段。 |
| `@objc dynamic` / Observation | `INTENTIONAL_DIFFERENCE / CODABLE_FALLBACK` | 不使用不安全反射猜测存储布局；宏诊断和手写 Schema 是显式边界。 |
| 普通不可变 Codable 字段 | Direct | 使用稳定字段和静态 Schema，保持无第三方依赖的快速路径。 |

`PTModelCoreTests` 的 Direct/Schema golden、Extras opt-in、Dynamic/Polymorphic/Patch
组合回归、三层生命周期顺序以及 actor Sink contention benchmark 对上述边界提供本地
证据。这里不宣称与 SmartCodable、KakaJSON 的全量 differential parity；该项属于 G4。

## 回滚方式

业务模型迁移前继续使用 `PooTools/Core` 中的 `PTBaseModel`、SmartCodable 和 KakaJSON 入口。
新增的 `PToolsModelCore` / `PooTools/ModelCore` 是可选产品，不会替换旧依赖，也不会改变旧入口。
