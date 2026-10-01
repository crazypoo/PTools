# DebugNetwork 6.0 迁移说明

5.x 兼容入口：

| 旧入口 | 5.x 迁移入口 | 6.0 计划 |
| --- | --- | --- |
| `PTHttpModel` | `PTNetworkCaptureRecord` / `PTNetworkCaptureSummary` | 删除旧引用模型 |
| `PTHttpDatasource` | `PTNetworkCaptureStore` | 删除 MainActor 数据源 |
| `PTNetworkHelper` | `PTNetworkDebugPresentationSession` + Capture Engine | 删除兼容控制器 |
| 旧 reload Notification | `PTNetworkCaptureStore.changes()` | 删除通知广播 |
| 本地速度压测名称 | `PTLoopbackThroughputBenchmark` | 保留语义明确的名称 |

迁移规则：列表只查询 summary，详情按 UUID 查询完整 record；导出默认使用脱敏 record；业务 Network 的 cache、retry、auth 和 dedup 不迁移到 DebugNetwork。

进入 6.0 删除前必须满足：内部调用为零、Example 调用为零、至少一个真实宿主迁移、兼容测试通过、文档已发布。
