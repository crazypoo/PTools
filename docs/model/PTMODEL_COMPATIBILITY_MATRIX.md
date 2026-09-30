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
| Patch / Diff / Clone / Migration | N/A | PARTIAL | PARTIAL | PARTIAL | PARITY for PTJSONValue/Codable models |
| Top-level array streaming | N/A | PARTIAL | PARTIAL | PARTIAL | PARITY with bounded element scanner |
| Foundation Date/Data/URL strategies | PARTIAL | PARTIAL | PARTIAL | PARTIAL | PARITY through explicit codecs |
| Swift 6 concurrency boundary | UNKNOWN | UNKNOWN | UNKNOWN | UNKNOWN | PTModel values are Sendable; legacy is MainActor-only |
| Runtime reflection fast path | USED/UNKNOWN | USED/UNKNOWN | USED/UNKNOWN | USED/UNKNOWN | INTENTIONAL_DIFFERENCE |

第三方版本行为矩阵必须在依赖更新时重新运行 fixture；不能仅凭版本号推断行为一致。
