# PTModel 兼容矩阵

状态含义：`PARITY` 表示当前入口已具备可验证能力；`PLANNED` 表示计划中但尚未宣称完成；
`INTENTIONAL_DIFFERENCE` 表示为了安全或并发边界明确不同。

| 能力 | SmartCodable 4.4.4 legacy | SmartCodable 6.x/Inherit | SmartCodable current | KakaJSON 1.1.2 | PTModel 5.58.0 |
| --- | --- | --- | --- | --- | --- |
| Codable model decode | PARITY | PARITY | PARITY | PARITY | PARITY |
| JSON string / Data input | PARITY | PARITY | PARITY | PARITY | PARITY |
| Model → JSON / Data | PARITY | PARITY | PARITY | PARITY | PARITY |
| Foundation dictionary / array input | PARITY | PARITY | PARITY | PARITY | PARITY |
| Top-level scalar / array | PARTIAL | PARTIAL | PARTIAL | PARITY | PARITY |
| Exact numeric lexeme | PARTIAL | PARTIAL | PARTIAL | PARTIAL | PARITY |
| Missing / null / invalid distinction | PARTIAL | PARTIAL | PARTIAL | PARTIAL | PARITY contract |
| Duplicate-key policy | UNSPECIFIED | UNSPECIFIED | UNSPECIFIED | UNSPECIFIED | PARITY |
| KakaJSON dynamic model | N/A | N/A | N/A | PARITY | INTENTIONAL_DIFFERENCE; legacy adapter only |
| Macro inheritance | N/A | PARITY | PARITY | N/A | SwiftPM `@PTSubclass`; CocoaPods manual fallback |
| Static Schema / field policies | N/A | PARTIAL | PARTIAL | PARTIAL | PARITY for manual schema |
| Macro field discovery / wrappers | N/A | PARITY | PARITY | N/A | PARITY for supported wrappers; Observation and ObjC storage use explicit boundary rules |
| Macro Path / Flat direct scanner | N/A | PARTIAL | PARTIAL | N/A | PARITY for generated PTModel fields |
| Transform / Validate direct construction | N/A | PARTIAL | PARTIAL | N/A | PARITY through normalized direct object construction |
| Polymorphic discriminator | N/A | PARTIAL | PARTIAL | PARTIAL | PARITY through typed registry/resolver; annotated fields keep schema fallback |
| Unknown / Extras capture | N/A | PARTIAL | PARTIAL | PARTIAL | PARITY through explicit `decodeWithExtras`; ordinary decode does not mutate models |
| Patch / Diff / Clone / Migration | N/A | PARTIAL | PARTIAL | PARTIAL | PARITY for PTJSONValue/Codable models |
| Top-level array streaming | N/A | PARTIAL | PARTIAL | PARTIAL | PARITY with bounded element scanner |
| Foundation Date/Data/URL strategies | PARTIAL | PARTIAL | PARTIAL | PARTIAL | PARITY through explicit codecs |
| Swift 6 concurrency boundary | UNKNOWN | UNKNOWN | UNKNOWN | UNKNOWN | PTModel values are Sendable; legacy is MainActor-only |
| Runtime reflection fast path | USED/UNKNOWN | USED/UNKNOWN | USED/UNKNOWN | USED/UNKNOWN | INTENTIONAL_DIFFERENCE |

## 5.58.0 F1–F3 边界冻结

- `@Observable` backing storage 不由 `@PTModel` 猜测；宏会给出确定性诊断，使用手写 `PTStaticModel` Schema。
- `@objc dynamic`、NSObject 运行时字段不进入不安全反射快路径；这类字段保持 Codable/Schema 兼容路径。
- `PTPolymorphic` 和 `PTExtras` 是显式运行时边界：多态使用 `PTModelDynamicResolver`/`PTPolymorphicRegistry`，未知字段使用 `decodeWithExtras`。
- Path、Flat、Transform、Validate 已通过生成 Schema 的直接构造路径验证；只有需要上下文或外部状态的语义才保留 Schema fallback。
- `Any`、第三方 metatype 和 legacy Network 解析仅停留在兼容层，不穿过 Foundation-only Core 的并发执行器。

第三方版本行为矩阵必须在依赖更新时重新运行 fixture；不能仅凭版本号推断行为一致。
