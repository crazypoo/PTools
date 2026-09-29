# KakaJSON 1.1.2 Behavior Matrix

KakaJSON 仍是 5.x 旧 Core 的兼容依赖。PTModel 吸收的是一行式转换体验和明确的双向入口，
不复制其 runtime reflection 和模糊类型转换实现。

| 能力 | 状态 |
| --- | --- |
| JSON → Model / Model → JSON | PTModel 5.58.0 PARITY（Codable models） |
| String / Data / Dictionary input | PTModel 5.58.0 PARITY |
| nested / array / set / dictionary output | PTModel 5.58.0 基础 Codable 路径 |
| dynamic model | PLANNED adapter |
| recursive / generic model | Codable 可用；专用 Schema/diagnostics PLANNED |
| persistence | PLANNED 5.58.4 |
| arbitrary coercion | INTENTIONAL_DIFFERENCE：只允许显式安全转换 |
