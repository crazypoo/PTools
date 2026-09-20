<!--
AUTO-GENERATED FILE.
DO NOT EDIT MANUALLY.

Generator: Scripts/report_concurrency_5_9.rb
Source revision: 7beff0ffd16062cec5a2c5da1044b5111779d7e8
Generated at: 2026-09-20T16:54:12Z
-->

# PTools 当前 Swift 6 并发扫描

本报告只记录现状；系统对象兼容包装器必须继续登记在 Scripts/unchecked_sendable_allowlist.txt。

| 规则 | 数量 |
| --- | ---: |
| as_bang | 4 |
| main_queue_async | 28 |
| task_detached | 28 |
| unchecked_sendable | 68 |

## 约束

- 业务共享状态不得新增 @unchecked Sendable。
- 生产代码不得新增 nonisolated(unsafe)。
- Any、Progress 和 UIKit/PhotoKit 对象不得直接跨 actor 传递。
- Task.detached 只能用于明确不继承 actor 状态的纯后台工作。
