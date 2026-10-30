<!--
Current report metadata.
AUTO-GENERATED FILE.
Repository: crazypoo/PTools
Branch: feature/pr51-pr55-debug-performance-rel-candidate-20261030
Source revision: 6928fdb7d49e1a9b1353b68d24225b23a0d67eb2
Source version: 5.69.0
Source inputs digest: c0ec772e7214cf193c1b62fabd35850af82c5fef5524d529dcced405437ce7e0
Generator version: 1
Generator: Scripts/report_concurrency.rb
Generated at: 2026-10-30T04:12:21Z
-->

# PTools 当前 Swift 6 并发扫描

本报告只记录现状；系统对象兼容包装器必须继续登记在 Scripts/unchecked_sendable_allowlist.txt。

| 规则 | 数量 |
| --- | ---: |
| main_queue_async | 25 |
| task_detached | 36 |
| unchecked_sendable | 55 |

## 约束

- 业务共享状态不得新增 @unchecked Sendable。
- 生产代码不得新增 nonisolated(unsafe)。
- Any、Progress 和 UIKit/PhotoKit 对象不得直接跨 actor 传递。
- Task.detached 只能用于明确不继承 actor 状态的纯后台工作。
