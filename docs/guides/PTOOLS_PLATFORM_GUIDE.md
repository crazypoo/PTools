# PTools 5.34.0 平台能力使用示例

## Connectivity

```swift
let monitor = PTConnectivityMonitor.shared
let snapshot = await monitor.current()
for await next in await monitor.snapshots() {
    print(next.status, next.interfaces)
}
```

## Storage

```swift
let storage = PTStorage(
    namespace: PTStorageNamespace(module: "Account", feature: "Session"),
    backend: PTCompositeStorage(primary: PTKeychainStorage(service: "com.example.app"),
                                fallback: PTUserDefaultsStorage())
)
let tokenKey = PTStorageKey<String>("accessToken")
try await storage.set(token, for: tokenKey)
let savedToken = try await storage.value(for: tokenKey)
```

## Deep Link 和 Router

```swift
let request = try PTDeepLinkParser.request(
    from: URL(string: "myapp://orders/42")!,
    configuration: PTDeepLinkConfiguration(schemes: ["myapp"])
)

await PooToolsRouter.shared.register("orders") { request, context in
    // 在 MainActor 内使用 context.navigationController 完成展示。
    return .completed
}
try await PooToolsRouter.shared.open(request)
```

## Notifications

```swift
let notifications = PTNotificationCenter.shared
_ = try await notifications.requestAuthorization()
try await notifications.schedule(
    PTNotificationRequest(
        id: "welcome",
        payload: PTNotificationPayload(title: "Welcome", body: "Hello PTools"),
        trigger: .timeInterval(1, repeats: false)
    )
)
```

## BackgroundTasks

```swift
let registration = PTBackgroundTaskRegistration(
    identifier: "com.example.app.refresh",
    kind: .appRefresh
)
_ = PTBackgroundTasks.shared.register(registration) {
    // 返回 true 表示任务完成；系统过期时由框架取消 Task。
    await refreshData()
    return true
}
try PTBackgroundTasks.shared.schedule(registration)
```

生产应用仍需在 `Info.plist` 配置 `BGTaskSchedulerPermittedIdentifiers`，并在系统允许的生命周期入口注册任务。
