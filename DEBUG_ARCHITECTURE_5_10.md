# PTools 5.10.x Debug Foundation 架构记录

状态：已完成源码落地和 PooTools-Example Debug 完整 Xcode 构建；多 Scene、真机和真实宿主回归仍需人工验证。

## 边界

```text
PToolsCore / ptools
        ↓  Core runtime hooks + PTLogEvent
PooToolsDEBUG
        ↓  adapters / collectors / UI
LocalConsole / Inspector / Network / Lifecycle / Crash / Leak / MockLocation
```

- Core 不直接引用 `LocalConsole`、`PTLogLevel`、`PTConsoleWindow`、`Inspector`、`TouchInspectorWindow` 或 Debug 偏好类型。
- Debug 依赖 Core；Core 不依赖 Debug。
- Core 只提供通用 `PTUIKitRuntimeHooks` 和 `PTLogSinkCenter`，具体调试语义由 `PTDebugRuntimeAdapter` 安装。
- `PooToolsDEBUG` 的 SwiftPM 与 CocoaPods 入口仍使用各自原有源文件集合，不修改第三方依赖。

## Foundation

`PTDebugConfiguration` 是 `Sendable` 不可变快照；`PTDebugPreferences` 是 `@MainActor` 的 UserDefaults 所有者，并同时读取、写入旧 key，保证 5.x 迁移期间不丢失配置。

`PTDebugManager` 只负责插件/Collector 注册和生命周期。`PTDebugEventCenter` 只传递 `String` 快照，避免 UIKit、`Any` 或可变系统对象跨 actor 传递。

LocalConsole 通过 `PTLogSink` 接收 Core 日志，通过事件中心接收网络状态。多 Scene 控制台使用带 owner 的 Debug session 引用计数，关闭一个场景不会停止其他场景仍在使用的 Collector。

## Collector 所有权

| Collector | 负责内容 | 停止语义 |
| --- | --- | --- |
| `PTConsoleCollector` | stdout / stderr | 最后一个 Debug session 释放时停止 |
| `PTNetworkCollector` | URLSession hook、网络状态事件 | 请求监控关闭时停止状态任务和辅助监控 |
| `PTLifecycleCollector` | 启动时间、生命周期和窗口 hook | swizzle 不回滚，owner 记录保留 |
| `PTInspectorCollector` | Inspector 生命周期 | 由 manager 幂等停止 |
| `PTCrashCollector` | 崩溃处理器注册 | 底层 signal hook 只注册一次，不强行回滚 |
| `PTLeakCollector` | 泄漏检测和事件快照 | 清除 callback、observer 和检测任务 |
| `PTMockLocationCollector` | 模拟定位兼容 hook | 不可逆 swizzle，只有启用偏好时启动 |

## 兼容策略

- `LocalConsole.shared`、`LocalConsole.console(for:)`、`show/hide/print` 保留。
- `PTCoreUserDefultsWrapper` 中历史 Debug 属性迁到 Debug 产品的 deprecated extension，至少保留到 6.0.0。
- Core 缺少 Debug 产品时，runtime hook 默认为空，不创建调试窗口、不显示控制台。

## 本轮边界

本轮没有删除公开符号、升级依赖、修改 Pods 源码或创建版本 tag。完整验收仍包括真实多 Scene、Scene 断开重连、键盘/分屏、性能和真机行为验证。
