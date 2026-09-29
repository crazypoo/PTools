# SmartCodable Current Capability Matrix

当前版本能力只作为目标矩阵，不作为 PTools 当前运行时依赖。每个目标能力都必须由独立
fixture、差异记录和回滚策略证明后，才能进入 PTModel canonical path。

| 能力 | 状态 |
| --- | --- |
| Codable interoperability | PTModel 5.58.0 已提供基础入口 |
| key alias / nested path | PLANNED 5.58.3 |
| Date/Data/Float strategy | Foundation strategy 已提供，完整 annotation PLANNED |
| Any bridge | Foundation compatibility bridge 已提供，裸 Any fast path 禁止 |
| ignored/flat/lossy/published | PLANNED static Schema |
| diagnostics / updater | PLANNED 5.58.3 / 5.58.9 |
| macro inheritance | PLANNED 5.58.5 |
