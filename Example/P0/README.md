# P0 宿主接入示例

## 路由与多 Scene

在 `scene(_:willConnectTo:options:)` 完成窗口挂载后，使用当前 `UIWindowScene` 调用
`PTRouteHostCoordinator.shared.resume(scene:)`。URL Scheme、Universal Link、Spotlight、
通知和 AppIntent 最终都应转换为 `PTRouteRequest`，再通过同一个 Scene 上下文执行。

```swift
func scene(_ scene: UIScene, openURLContexts contexts: Set<UIOpenURLContext>) {
    guard let windowScene = scene as? UIWindowScene,
          let url = contexts.first?.url else { return }
    Task { @MainActor in
        try? await PTRouteHostCoordinator.shared.handle(url: url, in: windowScene)
    }
}
```

## 后台任务

在 App 启动阶段注册宿主自己的标识和操作；后台任务标识必须同步到
`BGTaskSchedulerPermittedIdentifiers`。后台 URLSession 的系统回调仍由 AppDelegate 接收，
再转交给 `PTBackgroundTransferCoordinator.completeRestoredEvents()`。

```swift
let host = PTBackgroundTaskHostCoordinator(configuration: .init(
    registrations: [
        .init(identifier: "com.example.refresh", kind: .appRefresh)
    ],
    backgroundURLSessionIdentifiers: ["com.example.transfer"]
))
_ = host.register(["com.example.refresh": { true }])
```
