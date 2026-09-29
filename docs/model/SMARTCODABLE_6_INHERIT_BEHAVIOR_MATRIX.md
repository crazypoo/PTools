# SmartCodable 6.x / Inherit Legacy Behavior Matrix

继承和宏能力不在 5.58.0 的 runtime 核心内实现。此矩阵用于冻结旧行为，避免迁移时
把运行时属性扫描误当成静态 Schema。

| 行为 | 5.58.0 记录 |
| --- | --- |
| superclass field mapping | 待 `@PTSubclass` 阶段验证 |
| required init / super encode | 待 Macro golden tests 验证 |
| inherited key configuration | 待静态 Schema contract 验证 |
| NSObject / @objc inheritance | 待独立 Macro 兼容轴验证 |
| N-level inheritance | 待 5.58.5 回归 fixture |
