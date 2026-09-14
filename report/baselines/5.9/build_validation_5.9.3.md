# PTools 5.9.3 Lifecycle 构建验证记录

验证日期：2026-09-10（北京时间）

本记录区分 PooTools 源码诊断、外部 Pods 阻断和真实宿主回归；外部依赖失败不能记为
PooTools 源码或生命周期功能通过。

## 静态与契约验证

| 项目 | 结果 |
| --- | --- |
| 修改文件 Swift 前端语法解析 | 通过 |
| `swift package dump-package` | 通过 |
| `Scripts/validate_lifecycle_5_9.sh` | 通过 |
| `git diff --check` | 通过 |
| 单例报告 | 92 个声明，A=5、B=5、C=54、D=28，`.shared` / `.share` 调用计数 1566 |
| PooTools 源码 Xcode warning/error | 当前日志未发现 |

## Xcode 完整构建

使用 `/Applications/Xcode-beta.app`，通过 `PooTools.xcworkspace` 的
`PooTools-Example` scheme，目标为 iOS Simulator，分别执行 Debug 和 Release 完整构建。

| 配置 | 结果 | 阻断位置 |
| --- | --- | --- |
| `PooTools-Example` Debug | 阻断 | 外部 `Pods/Appz` 的 `UIApplication` 协议扩展 Swift 6 隔离诊断 |
| `PooTools-Example` Release | 阻断 | 外部 `Pods/KituraContracts` 的 Swift 6 并发诊断 |

阻断错误包括 Appz 的 `UIApplication` 协议扩展跨越 MainActor 隔离，以及 KituraContracts 中
`BodyFormat.json` 的非 Sendable 静态属性和 `CodableQuery/Extensions.swift` 中
`_iso8601Formatter` 的共享可变状态。两份日志均未出现 `PooToolsSource` 路径的 warning 或
error；Pods 的弃用提示、链接搜索路径和工具链提示不计入 PooTools 源码结果。本轮没有修改
Pods 源码、第三方依赖或用户的 `Podfile.lock` 改动。

原始日志：

- `/tmp/ptools-593-final2.7jNkLh/debug.log`
- `/tmp/ptools-593-final2.7jNkLh/release.log`

## 真实宿主回归

以下场景仍需在可运行的 Xcode/真实宿主环境验证：

- 两个前台 Scene 同时存在时的 Alert、Console、NavigationBar、HUD、Ruler 和 Color Picker 隔离。
- Scene 断开、重连和窗口尺寸变化后的状态清理与布局恢复。
- 多导航栈并行 push/pop、interactive-pop 取消和转场进度同步。

在外部 Pods 阻断解除并完成上述回归前，不能宣称 5.9.3 完整验收通过，也不创建发布标签。
