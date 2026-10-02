<!--
Current report metadata.
AUTO-GENERATED FILE.
Repository: crazypoo/PTools
Branch: master
Source revision: e9e0402b99b3bcc1a95b156a8b19ae2f857c8218
Source version: 5.59.0
Source inputs digest: 4caf138b6ab1c85771b47b142436225495a9f22124e365083fb05dd723906f32
Generator version: 1
Generator: Scripts/report_concurrency.rb
Generated at: 2026-10-01T22:10:22Z
-->

# PTools 当前 Swift 6 并发扫描

本报告只记录现状；系统对象兼容包装器必须继续登记在 Scripts/unchecked_sendable_allowlist.txt。

| 规则 | 数量 |
| --- | ---: |
| as_bang | 4 |
| main_queue_async | 27 |
| task_detached | 29 |
| unchecked_sendable | 53 |

## 约束

- 业务共享状态不得新增 @unchecked Sendable。
- 生产代码不得新增 nonisolated(unsafe)。
- Any、Progress 和 UIKit/PhotoKit 对象不得直接跨 actor 传递。
- Task.detached 只能用于明确不继承 actor 状态的纯后台工作。
