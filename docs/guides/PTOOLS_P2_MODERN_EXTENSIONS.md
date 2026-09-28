# PTools 5.36.0 P2 现代系统扩展指南

这些能力都是可选模块，Core 默认不携带。所有示例面向 iOS 17+ / Swift 6+；涉及 AppIntent、
Widget 或 Live Activity 时，宿主还必须配置对应的 Extension Target 和 entitlements。

## 安装

SwiftPM 选择：

```text
PToolsConfiguration
PToolsFeedback
PToolsAudio
PToolsAppIntents
PToolsWidgetCore
PToolsActivities
```

CocoaPods：

```ruby
pod 'PooTools/Configuration'
pod 'PooTools/Feedback'
pod 'PooTools/Audio'
# Extension Target 中按需单独添加：
pod 'PooTools/AppIntents'
pod 'PooTools/WidgetCore'
pod 'PooTools/Activities'
```

## Configuration / Feature Flags

```swift
let checkoutEnabled = PTConfigKey(name: "checkout.enabled", defaultValue: false)
let store = PTConfigurationStore(
    context: .init(environment: .staging, appVersion: "5.36.0"),
    defaults: [checkoutEnabled.name: try JSONEncoder().encode(false)]
)

try await store.setLocalOverride(true, for: checkoutEnabled)
let snapshot = try await store.refresh()
let enabled = try snapshot.value(for: checkoutEnabled)
```

来源优先级为 defaults → bundle → environment → local override → remote → debug override。
Remote 只实现 `PTConfigurationProvider`；不要把 token、密码或个人隐私放入配置源。Debug
override 仅在 Debug 编译中可见。

## Feedback / Haptics

```swift
await PTHapticEngine.shared.prepare()
await PTHapticEngine.shared.play(.selectionChanged)
await PTHapticEngine.shared.play(.success)
```

自定义 CoreHaptics 模式通过 `PTHapticPattern`，硬件不支持时会安全跳过；业务层使用语义事件，
不要在每个按钮里重复创建 generator。`policy = .disabled` 可用于无障碍或测试环境。

## Audio

```swift
let audio = PTAudioSessionCoordinator.shared
try await audio.configure(.init(category: .playAndRecord, mode: "default"))
try await audio.activate()
let recorder = PTAudioRecorder()
guard await PTAudioPermission.requestMicrophoneAccess() else { return }
try await recorder.record(to: outputURL)
```

录音前必须显式请求麦克风权限；`PTAudioPlayer` 只负责本地简单播放，流媒体继续使用 AVPlayer
或业务媒体模块。`events()` 提供中断、路由变化和 media services reset 快照，`waveform()` 返回
无 UI 依赖的有界采样值。

## App Intents / Router

```swift
let descriptor = PTAppIntentRouteDescriptor(
    route: PTRoute(id: "orders"),
    mode: .routeToApp
)
try await PTAppIntentRouteBridge.shared.execute(descriptor)
```

AppIntent 的静态声明仍由 Apple `AppIntent` / `AppShortcutsProvider` 管理；PTools 只将安全的
`PTRouteRequest` 交给宿主适配器。无 UI 的动作使用 `.headless`，需要唤起 App 的动作使用
`.routeToApp`。危险支付、删除等动作不要默认暴露给 Siri。

## WidgetCore

```swift
let store = try PTWidgetSharedStore(appGroupIdentifier: "group.example.app")
try await store.write(PTWidgetSnapshot(value: payload), for: widgetKey)
PTWidgetReloadCoordinator.shared.requestReload(kind: "OrderWidget")
let request = try PTWidgetDeepLink(url: widgetURL).route()
```

App Group 必须由宿主显式传入并配置 entitlement；PTools 不猜 identifier。WidgetCore 不提供
SwiftUI View，TimelineProvider 和 Widget UI 保留在宿主 Widget Extension。

## Activities

宿主定义自己的 `ActivityAttributes` 和 UI，PTools 只负责生命周期：

```swift
let coordinator = PTActivityCoordinator<OrderAttributes>()
let id = try await coordinator.start(attributes: attributes, state: initialState,
                                     staleDate: Date(timeIntervalSinceNow: 900),
                                     relevanceScore: 0.5)
for await token in coordinator.pushTokens() {
    await uploadPushToken(token, for: id)
}
```

更新支持 deduplicated/throttled policy，结束支持 immediate/afterStaleDate。Push Server、
锁屏/Dynamic Island 业务 UI、敏感信息脱敏由宿主负责。若需要后台刷新，宿主可实现
`PTActivityBackgroundAdapter`，将 `staleDate` 转发给已有的 BackgroundTasks 或通知调度器；
PTools 不会在 Activities 内部创建循环依赖。`generation` 可用于丢弃旧请求的异步回写。

## 示例与验证

最小示例片段位于 [`Example/P2/README.md`](../../Example/P2/README.md)。脚本
`Scripts/CI/check_p2_modern_modules.sh` 检查产品、subspec、并发边界和 extension-safe 规则；
完整 UIKit 验证使用 Xcode Simulator，而不是 macOS `swift build` 代替。
