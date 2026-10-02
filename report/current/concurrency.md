<!--
Current report metadata.
AUTO-GENERATED FILE.
Repository: crazypoo/PTools
Branch: master
Source revision: 26d9a4ef27a56e1b0f3e130443230a878e99abb0
Source version: 5.59.0
Source inputs digest: 6aaa6f6be0320ecf737bee8c48fe02589aa0bdf3bae9f182aa3b2d2a2870b184
Generator version: 1
Generator: Scripts/report_concurrency.rb
Generated at: 2026-10-02T06:44:02Z
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
