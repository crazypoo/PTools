# PTools 5.12.0 Core 边界

## 目的

5.12.0 将 `PToolsCore` 收口为 Foundation-only 的稳定底层。它不承担 UIKit、网络、媒体、Debug
或业务 Feature 的实现，也不直接暴露第三方类型。

## 依赖方向

```text
Foundation / Objective-C runtime / os.lock
                    ↓
                PToolsCore
                    ↓
          PToolsUIFoundation / PermissionCore
                    ↓
             ptools / Feature modules
                    ↓
                 Debug
```

Core 禁止反向依赖 Navigation、Network、Media、Debug 和 Feature。5.x 期间旧的
`PooToolsSource/Core` UIKit 兼容实现继续保留，作为公开 API 适配层；它们会在后续 5.13–5.19
按模块迁移，不能在 5.12.0 直接删除。

## Foundation-only 契约

当前由 `PToolsCore` 提供：

- `PTProgressSnapshot`、`PTResponseMetadata`、`PTBaseStructModel` 等不可变值类型。
- `PTURLParser` 和 `URL.pt_queryParameters`。
- `PTAssociatedObjectStore` 运行时兼容协议。
- `PTLocked`、`PTAtomic`、`PTCancellationToken`、`PTCancellationBag`。
- `PTLifecycleToken`、`PTTaskStore` 和 `PTInvalidating`。
- `PTMainActorBridge`。
- `PTCacheStorage`、`PTMemoryCache`。
- `PTLogEvent`、`PTLogSeverity`、`PTLogging`。
- `PTCoreError`。

这些类型只传递值类型或明确的 Sendable 闭包，不使用 `@unchecked Sendable`、
`nonisolated(unsafe)`、`try!` 或 `as!`。

## 第三方适配器边界

第三方库仍可由兼容层和上层 Feature 使用，但不能进入 `PToolsCore`：

| 第三方能力 | 5.12 边界 | 后续迁移方向 |
| --- | --- | --- |
| SnapKit | `PToolsUIFoundation` 兼容适配器 | UIFoundation 按模块迁移到原生约束 |
| Kingfisher | 图片加载 Feature | 继续通过 `PTLoadImageFunction` 收口 |
| CocoaLumberjack | Log 兼容后端 | 保留 `PTLogging`，后续评估 OSLog-only |
| SmartCodable / KakaJSON | Model / Network 兼容层 | 新代码使用类型化 Codable 边界 |
| Lottie | UI / Debug Feature | 不进入 Foundation-only Core |

公共 Core 契约不得出现这些库的类型。检查入口为：

```bash
bash Scripts/validate_core_boundary_5_12.sh
```

## 兼容策略

- `PooTools/Core` 继续作为 CocoaPods `default_subspec`，并依赖 `PooTools/PToolsCore`。
- SwiftPM `ptools` 继续作为 umbrella target；`PToolsCore` 可单独依赖。
- URL 解析、MainActor 调度和日志契约的旧符号通过 typealias / forwarding 保留。
- 5.12.0 不删除公开 API，也不提前迁移 UIKit、媒体和业务代码。
