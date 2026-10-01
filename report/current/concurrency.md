<!--
Current report metadata.
AUTO-GENERATED FILE.
Repository: crazypoo/PTools
Branch: master
Source revision: fd66ba388d2f4b8448b52d434ef02d2fdfd5d56e
Source version: 5.59.0
Source inputs digest: f65daecb5c4328289fea7efd63b8becda2567f98942e0f2f1c6937ded0182aa9
Generator version: 1
Generator: Scripts/report_concurrency.rb
Generated at: 2026-10-01T14:20:09Z
-->

# PTools 当前 Swift 6 并发扫描

本报告只记录现状；系统对象兼容包装器必须继续登记在 Scripts/unchecked_sendable_allowlist.txt。

| 规则 | 数量 |
| --- | ---: |
| as_bang | 4 |
| main_queue_async | 27 |
| task_detached | 29 |
| unchecked_sendable | 67 |

## 约束

- 业务共享状态不得新增 @unchecked Sendable。
- 生产代码不得新增 nonisolated(unsafe)。
- Any、Progress 和 UIKit/PhotoKit 对象不得直接跨 actor 传递。
- Task.detached 只能用于明确不继承 actor 状态的纯后台工作。
