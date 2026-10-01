<!--
Current report metadata.
Repository: crazypoo/PTools
Branch: master
Source revision: 6a3f97d0ab05a4f04ab789c93804c84c787b5da6
Source version: 5.59.0
Generator version: current-report-normalizer
Generated at: 2026-10-01T12:30:41Z
-->

# PTools 当前 Swift 6 并发扫描

本报告只记录现状；系统对象兼容包装器必须继续登记在 Scripts/unchecked_sendable_allowlist.txt。

| 规则 | 数量 |
| --- | ---: |
| as_bang | 4 |
| main_queue_async | 27 |
| task_detached | 29 |
| unchecked_sendable | 68 |

## 约束

- 业务共享状态不得新增 @unchecked Sendable。
- 生产代码不得新增 nonisolated(unsafe)。
- Any、Progress 和 UIKit/PhotoKit 对象不得直接跨 actor 传递。
- Task.detached 只能用于明确不继承 actor 状态的纯后台工作。
