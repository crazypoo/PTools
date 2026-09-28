# P2 示例入口

这里保留可复制的最小示例，不创建第二套 Demo 架构，也不把 Widget/Activity 的业务 UI 放进
PTools。宿主按需要把示例放入自己的 App 或 Extension Target。

## FeatureFlagDemo

```swift
let key = PTConfigKey(name: "newCheckout", defaultValue: false)
let store = PTConfigurationStore()
try await store.setLocalOverride(true, for: key)
let snapshot = try await store.refresh()
let enabled = try snapshot.value(for: key)
```

## HapticsDemo

```swift
await PTHapticEngine.shared.prepare()
await PTHapticEngine.shared.play(.actionConfirmed)
```

## AudioDemo

```swift
guard await PTAudioPermission.requestMicrophoneAccess() else { return }
try await PTAudioSessionCoordinator.shared.configure(.init(category: .record))
try await PTAudioSessionCoordinator.shared.activate()
let recorder = PTAudioRecorder()
try await recorder.record(to: outputURL)
```

## AppIntentsDemo

在 AppIntent Extension 中声明 Apple 的 `AppIntent`，将参数转换成
`PTAppIntentRouteDescriptor`，再交给已注册的 `PTAppIntentRouteBridge` 适配器。无 UI 动作不要
强制打开 App。

## WidgetDemo

在 Widget Extension 中显式配置 App Group，使用 `PTWidgetSharedStore` 保存最小快照，在宿主
更新数据后调用 `PTWidgetReloadCoordinator`。WidgetKit 的 `TimelineProvider` 和 SwiftUI View
继续由 Extension 自己实现。

## LiveActivityDemo

在宿主定义 `ActivityAttributes` 与 `ContentState`，通过 `PTActivityCoordinator` 调用
`start/update/end`，并从 `pushTokens()` 转发 token。保存 `generation`，在更新时传入旧代次即可让
协调器拒绝过期回写；`PTActivityBackgroundAdapter` 可接入宿主已有的 BackgroundTasks 调度。
不要将订单隐私或用户凭据写入锁屏内容。Widget 的实际 SwiftUI UI 和 Live Activity 的
`ActivityAttributes` 必须位于宿主自己的 Extension Target，不复制进 PTools。

## SemanticFeedbackDemo

Core 只负责发出语义信号，触觉模块按需安装为适配器：

```swift
PTHapticEngine.shared.installAsDefault()
PTFeedbackCenter.shared.emit(.actionConfirmed)
```

业务 UI 不直接创建触觉生成器；测试或无障碍场景可以设置
`PTHapticEngine.shared.policy = .disabled`。
