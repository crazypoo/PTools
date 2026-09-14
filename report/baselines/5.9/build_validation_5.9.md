# PTools 5.9.x 构建验证记录

验证日期：2026-09-09（北京时间）

本记录区分 PooTools 源码结果、外部 Pods 阻断和宿主环境警告；外部依赖失败不能记为
PooTools 源码通过。

## 静态与契约验证

| 项目 | 结果 |
| --- | --- |
| Swift 前端语法解析 | 通过，当前变更的 24 个 Swift 文件 |
| `swift package dump-package` | 通过 |
| `Scripts/validate_59_contracts.sh` | 通过 |
| `Scripts/validate_quality_scans.sh` | 通过；仅保留繁简中文翻译重复提示 |
| `Scripts/validate_build_entries.sh` | 通过 |
| `Scripts/validate_release.sh` | 通过，当前稳定基线 5.8.9 |
| `git diff --check` | 通过 |

## Xcode 验证

使用 `/Applications/Xcode-beta.app`，目标为 iOS Simulator，分别执行 Example Debug 和
Release 完整构建。

| 配置 | 结果 | 阻断位置 |
| --- | --- | --- |
| `PooTools-Example` Debug | 未通过 | 外部 `Pods/Bugly` 真机二进制被链接到 Simulator；未发现 PooTools 源码编译错误 |
| `PooTools-Example` Release | 未通过 | 外部 `Pods/Bugly` 真机二进制被链接到 Simulator；未发现 PooTools 源码编译错误 |
| `PooTools`（Pods 工程 scheme）Debug | 未通过 | 外部 `Pods/KituraContracts` 的 Swift 6 并发诊断 |

已确认的外部错误包括 `Bugly.framework` 只包含 iOS 真机架构、`KituraContracts/BodyFormat.swift`
的非 Sendable 静态属性、`CodableQuery/Extensions.swift` 的共享 formatter，以及另一个直接构建路径中
`Appz` 对 `UIApplication` 协议扩展的 Swift 6 隔离错误。源码警告门禁没有发现 `PooToolsSource` 路径错误；
Pods 的弃用、Metal 工具链和脚本输出单独保留在原始日志中。

原始日志：

- `/tmp/PTools-5.9-api-freeze-debug.log`
- `/tmp/PTools-5.9-api-freeze-release.log`
- `/tmp/PTools-5.9-final-xcode-debug-3.log`
- `/tmp/PTools-5.9-final-xcode-release-3.log`
- `/tmp/PTools-5.9-final-poo-tools-scheme.log`
- `/tmp/PTools-5.9-PooTools-Target-Debug.log`（历史直接 target 路径）

## 5.9.1 Concurrency follow-up（2026-09-09）

本轮并发改动的静态门禁、变更文件解析、SwiftPM manifest、构建入口契约和 `git diff --check`
均已通过。`PooToolsSource` 过滤后的 Xcode 日志没有新增源码错误或警告。

本轮实际修改并解析通过 19 个已纳入版本控制的 Swift 文件；并发支撑类型已归并到已有的
`PooToolsSource/NetWork/NetworkTypes.swift`，避免旧的 CocoaPods 工程因新增源文件未刷新而出现
`cannot find in scope`。

| 配置 | 结果 | 阻断位置 |
| --- | --- | --- |
| `PooTools-Example` Debug | 未通过 | 外部 `KituraContracts` Swift 6 并发诊断；同时出现 `swift-syntax` 更新获取失败 |
| `PooTools-Example` Release | 未通过 | 外部 `KituraContracts` Swift 6 并发诊断 |

原始日志：

- `/tmp/PTools-5.9.1-final-release-3.log`

本轮没有修改 Pods 源码、第三方依赖版本或产品版本号，也没有创建 5.9.1 标签。

## 发布结论

5.9.x 目前不能标记为完整 Xcode 验收通过，也不能创建 5.9.x 发布标签。需要先由依赖
维护方提供可链接 Simulator 的 Bugly 产物、Swift 6 可用的 KituraContracts/Appz 版本或完成替代方案，
再重新执行完整矩阵。

## 5.9.5 UI Quality follow-up（2026-09-10）

本轮新增视觉策略和无障碍适配已完成静态解析；变更后的完整 Xcode Debug / Release 构建均实际执行，
但仍在进入 PooTools 源码前被外部 `Pods/KituraContracts` 的 Swift 6 并发诊断阻断。

| 配置 | 结果 | 阻断位置 |
| --- | --- | --- |
| `PooTools-Example` Debug | 未通过 | 外部 `KituraContracts/BodyFormat.swift` 和 `CodableQuery/Extensions.swift` 的非 Sendable 共享状态 |
| `PooTools-Example` Release | 未通过 | 外部 `KituraContracts/BodyFormat.swift` 和 `CodableQuery/Extensions.swift` 的非 Sendable 共享状态 |

本轮日志中没有命中 `PooToolsSource` 的编译错误或警告；没有修改 Pods、第三方依赖版本或工程配置。
完整人工回归（动态字体、减弱动态效果、降低透明度、iOS 26 系统效果和深色模式）仍需在可运行宿主中执行。

原始日志：

- `build/xcode-5.9.5-final-debug.log`
- `build/xcode-5.9.5-final-release.log`
- `build/xcode-5.9.5-final3-debug.log`
- `build/xcode-5.9.5-final3-release.log`

最终收口构建（2026-09-10）再次实际执行：

- `build/xcode-5.9.5-final4-debug.log`
- `build/xcode-5.9.5-final4-release.log`

源文件收口后再次执行的最终构建（2026-09-10）：

- `build/xcode-5.9.5-final5-debug.log`
- `build/xcode-5.9.5-final5-release.log`

两种配置仍在外部 `KituraContracts` 的 Swift 6 并发诊断处阻断；这次视觉策略已经并入
现有 `PooToolsSource/Core/PTUtils.swift`，因此无需依赖未登记的新 CocoaPods 源文件。
最终日志没有命中 `PooToolsSource` 的编译错误或警告。

两种配置均在外部 `KituraContracts` 的 Swift 6 并发诊断处终止；最终日志没有命中
`PooToolsSource` 的编译错误或警告。Release 额外出现的诊断同样来自 Pods，未修改任何
Pods 源码或依赖配置。

导航栏 UI 收口后再次执行完整构建（2026-09-10）：

- `build/xcode-5.9.5-final6-debug.log`
- `build/xcode-5.9.5-final6-release.log`

Debug 与 Release 均实际执行到依赖编译阶段，并在外部 `KituraContracts` 的
`BodyFormat.swift` 非 Sendable 静态属性和 `CodableQuery/Extensions.swift` 共享 formatter
诊断处阻断；两份日志均没有 `PooToolsSource` 编译错误或警告。
