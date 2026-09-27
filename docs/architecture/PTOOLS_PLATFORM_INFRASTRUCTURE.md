# PTools 5.34.0 平台基础设施

5.34.0 将平台服务拆成可选的 Foundation-first 模块，默认 `Core` 不反向依赖 Debug 或具体业务 UI：

```text
PToolsCore
├── PToolsConnectivity
├── PToolsStorageCore → PToolsStorage
├── PToolsRouteCore → PToolsDeepLink → PooToolsRouter
├── PToolsNotifications
└── PToolsBackgroundTasks
```

## 边界

- `PToolsConnectivity` 只输出 `PTConnectivitySnapshot`，网络层仍负责 HTTP 语义，不能把 `NWPath` 的离线状态当成请求绝对失败。
- `PToolsStorageCore` 只定义 typed key、namespace、backend 和 migration 契约；`PToolsStorage` 提供原生后端。
- `PToolsRouteCore` 和 `PToolsDeepLink` 不导入 UIKit；它们只把 URL 归一化成 `PTRouteRequest`。
- `PooToolsRouter` 的 UI 入口运行在 `MainActor`，通过显式 `PTRoutePresentationContext` 接收 Scene、Window 和 NavigationController。
- `PToolsNotifications` 的动态 `UNUserNotificationContent.userInfo` 只存在于系统边界；跨 actor 的 payload 使用 `PTNotificationPayload`。
- `PToolsBackgroundTasks` 把系统任务过期转换为 `Task.cancel()`，并提供后台 URLSession 配置和事件完成入口。

## 构建入口

SwiftPM 产品：`PToolsConnectivity`、`PToolsStorageCore`、`PToolsStorage`、`PToolsRouteCore`、`PToolsDeepLink`、`PToolsNotifications`、`PToolsBackgroundTasks`。

CocoaPods subspec：`Connectivity`、`StorageCore`、`Storage`、`RouteCore`、`DeepLink`、`Notifications`、`BackgroundTasks`。

新层不会自动加入默认 `PooTools/Core`，需要的宿主按功能选择 subspec 或 SwiftPM product。这样可以避免系统服务、通知权限和后台调度改变既有 Core 的启动行为。

## 验证

每次修改后执行：

```text
bash Scripts/CI/check_p0_platform_modules.sh
bash Scripts/validate_module_parity.sh --check
swift package dump-package
```

宿主工程还需要执行 iOS Simulator Debug/Release 构建，并在真机验证通知授权、后台任务和 Universal Link 生命周期。
