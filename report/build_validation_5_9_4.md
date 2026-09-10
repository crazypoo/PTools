# PTools 5.9.4 Performance 构建验证记录

验证日期：2026-09-10（北京时间）

本记录把 PooTools 源码结果与外部 Pods 阻断分开记录。完整 Xcode 构建已经执行；由于外部依赖
失败，不能将本轮标记为完整构建通过。

## 静态与契约验证

| 项目 | 结果 |
| --- | --- |
| `PTNavBar.swift` / `PTTabBarView.swift` 前端语法解析 | 通过 |
| 其余本批修改文件前端语法解析 | 通过 |
| `swift package dump-package` | 通过 |
| `git diff --check` | 通过 |
| `report_cache_inventory_5_9.rb` | 通过，121 个缓存相关条目 |
| `validate_quality_scans.sh` | 通过；文件尺寸门禁和 Swift 6 安全扫描通过 |
| PooToolsSource warning/error | 当前两份 Xcode 日志未发现 |

## Xcode 完整构建

使用 `/Applications/Xcode.app`，通过 `PooTools.xcworkspace` 的
`PooTools-Example` scheme，目标为 iOS Simulator，分别执行 Debug 和 Release 完整构建。

| 配置 | 结果 | 阻断位置 |
| --- | --- | --- |
| `PooTools-Example` Debug | 阻断 | 外部 `Pods/KituraContracts` 的 `BodyFormat.json` 与 `_iso8601Formatter` Swift 6 并发诊断 |
| `PooTools-Example` Release | 阻断 | 外部 `SmartCodable` 宏脚本无法获取 `swift-syntax` 仓库 |

Debug 日志中的 KituraContracts 错误为非 Sendable 静态属性和共享可变 formatter；Release 日志中的
SmartCodable 阻断来自宏构建脚本无法克隆 `swift-syntax`。Pods 的弃用警告、Metal 工具链搜索路径
警告以及无输出脚本阶段提示均未归因到 PooTools 源码。本轮没有修改 Pods 源码、依赖版本或用户已有
的 `Podfile.lock` 改动。

原始日志：

- `/tmp/ptools-594-batch1-debug.log`
- `/tmp/ptools-594-batch1-release.log`
- `/tmp/ptools-594-batch2-debug.log`
- `/tmp/ptools-594-batch2-release.log`
- `/tmp/ptools-594-batch3-debug.log`
- `/tmp/ptools-594-batch3-release.log`

为进一步隔离源码 target，又通过同一 workspace 的 `PooTools` scheme 执行了 Debug / Release；
两者仍分别被外部 `Pods/Appz` 和 `Pods/KituraContracts` 阻断，未修改这些依赖：

- `/tmp/ptools-594-direct-debug.log`
- `/tmp/ptools-594-direct-release.log`

## 未完成的运行时验证

- Instruments 的 CPU、主线程、内存峰值和布局次数基线。
- 真机内存告警后媒体、列表、音频和视频封面恢复。
- 真实宿主中的快速滚动、旋转、窗口尺寸变化和深浅色切换。

在外部 Pods 阻断和上述运行时验证完成前，不宣称 5.9.4 完整验收通过，也不创建发布标签。
