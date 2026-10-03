<!--
Current report metadata.
AUTO-GENERATED FILE.
Repository: crazypoo/PTools
Branch: master
Source revision: b6875bfcbb5b503f145e05d8bcc101c196cc316e
Source version: 5.60.0
Source inputs digest: eb66b030720b0fd30eb573eff88c7601464f448a455eafda9e1630c8be0309e3
Generator version: 1
Generator: Scripts/report_concurrency.rb
Generated at: 2026-10-03T05:18:13Z
-->

# PTools 当前 Swift 6 并发扫描

本报告只记录现状；系统对象兼容包装器必须继续登记在 Scripts/unchecked_sendable_allowlist.txt。

| 规则 | 数量 |
| --- | ---: |
| as_bang | 4 |
| main_queue_async | 26 |
| task_detached | 30 |
| unchecked_sendable | 45 |

## 约束

- 业务共享状态不得新增 @unchecked Sendable。
- 生产代码不得新增 nonisolated(unsafe)。
- Any、Progress 和 UIKit/PhotoKit 对象不得直接跨 actor 传递。
- Task.detached 只能用于明确不继承 actor 状态的纯后台工作。
