# SmartCodable 4.4.4 Legacy Behavior Matrix

本文件是 PTools 当前 SwiftPM 锁定版本的迁移基线。`PTModelCore` 不直接依赖该框架，
以下差异必须通过 fixture 验证后再进入兼容 Adapter。

| 行为 | 5.58.0 记录 |
| --- | --- |
| Codable model | 保留旧 Core 行为；新 Core 使用 Foundation Codable |
| missing/default | 需要现有模型 fixture；PTModel 不猜测属性默认值 |
| null/coercion | PTModel 只提供显式 policy，不复制危险的隐式转换 |
| Date/Data/Float strategy | PTModel 使用独立 strategy 类型，Adapter 待后续阶段 |
| SmartPublished / wrapper | 待 5.58.3 静态 Schema 阶段 |
| diagnostics | PTModel 错误为类型化错误；上游诊断需 Adapter fixture |
