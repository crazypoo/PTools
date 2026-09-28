# P2 现代系统扩展架构

5.36.1 收口六个可选产品。它们围绕 Core 扩展，但不进入 `PooTools.podspec` 的
`default_subspec = Core`，宿主必须按功能显式选择。

| Product | CocoaPods | 责任 | 平台边界 |
| --- | --- | --- | --- |
| `PToolsConfiguration` | `PooTools/Configuration` | typed config、环境、feature flag、snapshot、缓存与 override | Foundation + Storage |
| `PToolsFeedback` | `PooTools/Feedback` | 语义触觉、UIKit generator、CoreHaptics、能力查询 | UIKit/CoreHaptics |
| `PToolsAudio` | `PooTools/Audio` | AVAudioSession、录音、简单播放、电平、波形 | AVFoundation |
| `PToolsAppIntents` | `PooTools/AppIntents` | AppIntent/AppShortcut 静态声明与 RouteCore bridge | AppIntents，extension-safe |
| `PToolsWidgetCore` | `PooTools/WidgetCore` | App Group typed store、timeline payload、reload debounce、deep link | Foundation-first，WidgetKit |
| `PToolsActivities` | `PooTools/Activities` | ActivityKit start/update/end、push token、stale/relevance、诊断 | ActivityKit，extension-safe |

## 依赖和隔离

`PToolsConfiguration`、`PToolsWidgetCore` 复用已有 `PToolsStorage`；App Intents 和 Widget
deep link 复用 `PToolsRouteCore` / `PToolsDeepLink`。P2 不绑定 Firebase、LaunchDarkly、
CloudKit、SwiftUI 或具体推送服务。

`PToolsWidgetCore` 不导入 UIKit、SwiftUI 或 `UIApplication.shared`。AppIntents、WidgetCore
和 Activities 的 CocoaPods subspec 声明 `APPLICATION_EXTENSION_API_ONLY = YES`；扩展 Target
仍需由宿主提供 App Group、entitlements、Widget UI 和 ActivityAttributes UI。

## 并发契约

- 配置、共享存储和 Activity 状态由 actor 或 `@MainActor` 协调器保护。
- 跨边界只传 Codable/Sendable 值类型、URL、Data 和快照。
- 触觉、音频和 Activity 的 UIKit/系统对象只在对应的 MainActor 适配器内使用。
- 不新增 `@unchecked Sendable`、`nonisolated(unsafe)` 或动态 `Any` 公共并发契约。

## CocoaPods 选择规则

`PooTools/InputAll` 只包含 Configuration、Feedback、Audio 这三个普通 App Target 模块。
AppIntents、WidgetCore、Activities 保持显式选择，避免把 extension-only 编译设置扩散到包含
大量 UIKit 代码的聚合 Target。SwiftPM `PooToolsAll` 仍发布六个 P2 product。
