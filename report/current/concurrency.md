<!--
Current report metadata.
AUTO-GENERATED FILE.
Repository: crazypoo/PTools
Branch: feature/pr46-pr50-inspector-layout-governance-20261030
Source revision: 0deb064cea510c896e78b35fab0997808e796173
Source version: 5.69.0
Source inputs digest: 8c745967288dcd0493111e7ec716d9f601938762a8f52bae2525c7d3591bb455
Generator version: 1
Generator: Scripts/report_concurrency.rb
Generated at: 2026-10-30T03:42:31Z
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
