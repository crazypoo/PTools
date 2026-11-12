<!--
Current report metadata.
AUTO-GENERATED FILE.
Repository: crazypoo/PTools
Branch: master
Source revision: 3f9f7d5b604877bdb4a48d32a53944734c9c5072
Source version: 5.69.0
Source inputs digest: ed60290a1fc9bcf9c6196aef2f4a5f386a8a93a84f766fa6d58cfb4cb854f084
Generator version: 1
Generator: Scripts/report_concurrency.rb
Generated at: 2026-11-12T02:17:28Z
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
