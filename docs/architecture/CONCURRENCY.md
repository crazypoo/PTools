# PTools Swift 6 并发边界

## 范围

本文档是 PTools Core 及其直接扩展的并发事实源，适用于 iOS 17+ / Swift 6+。它记录当前代码的
边界、例外和验证方式；一次性构建输出仍保留在 `report/`，不在这里复制日志。

## 五类问题的处理规则

| 类别 | 规则 | 当前实现 |
| --- | --- | --- |
| actor isolation warning | UIKit、WebKit、PhotoKit、权限和生命周期状态留在拥有它们的 actor；不在 `deinit` 或非隔离回调里触碰 UI。 | `PTHTMLHeightCalculator` 的销毁阶段只完成 continuation，WebKit 清理由对象生命周期处理；`PTMediaLibAlbumListViewController` 继续继承 `PTBaseViewController` 的 MainActor 边界。 |
| non-Sendable capture | 跨 actor 只传 `Data`、`URL`、字符串、数字、枚举或明确快照；系统引用只进入窄范围包装器。 | `PTBiometricsManager` 不再捕获 `LAContext` 到 detached 任务；颜色计算传递 PNG `Data`；Vision 传递 `CGImage`；视频缓存只在所属 actor 内编码 `UIImage`。 |
| MainActor violation | UI 更新、UI completion 和 UIKit/WebKit 对象访问统一回到 MainActor；后台任务只返回值。 | `PTMainActorBridge` 和既有 `@MainActor` 类型继续作为统一入口；质量门禁禁止 P0 模块新增 `nonisolated(unsafe)`。 |
| unsafe global mutable state | 可变全局状态必须由 MainActor、actor 或锁保护；纯常量和 associated-object key 不属于共享业务状态。 | `PTLanguage` 使用 `OSAllocatedUnfairLock`；路由和动画配置已是 MainActor；`UIWindow.lastTouch` 改为锁保护的 `CGPoint?` 快照。 |
| detached misuse | 只有明确不继承调用方 actor 的纯数据、文件 I/O 或系统框架适配工作可以使用 `Task.detached`；不得捕获 UIKit、WebKit、PhotoKit 或认证上下文。 | 保留缓存文件 I/O、纯图片/GIF 解码、Vision/AVFoundation 窄范围系统包装；移除 BioID、UIImage 颜色和视频封面中的不安全对象捕获。 |

## `@unchecked Sendable` 例外

生产代码的 `@unchecked Sendable` 只能来自
[`Scripts/unchecked_sendable_allowlist.txt`](../../Scripts/unchecked_sendable_allowlist.txt)，并且必须在
[`Scripts/concurrency_exception_registry.json`](../../Scripts/concurrency_exception_registry.json) 中登记：

- `SYSTEM_WRAPPER`：PhotoKit、AVFoundation、Vision、CoreNFC、URLProtocol 等系统对象的窄范围包装。
- `LOCK_PROTECTED`：共享传输、缓存、Socket 或语音状态由锁/串行队列保护。
- `LEGACY_MODEL`：旧公开引用模型只留在原 owner/actor，新接口使用不可变快照。
- `MAIN_ACTOR_ONLY`：UIKit、Debug UI、生命周期、指标或代理对象只在 MainActor 使用。

业务模型不得通过 `@unchecked Sendable` 隐藏共享可变状态；新代码也不得新增
`nonisolated(unsafe)`。

## 全局状态审计

状态处理顺序固定为：

1. 首选 `let` 常量或实例配置。
2. UI 配置使用 `@MainActor`。
3. 跨线程计数、缓存、状态快照使用 actor 或锁保护类型。
4. 不使用 `DispatchQueue` 作为隐式数据竞争修复，也不把所有任务机械改成 `Task.detached`。

`PTLanguage`、`PTRouterManager`、`PTListAnimationConfig` 和 `UIWindow.lastTouch` 分别代表锁保护、
MainActor 注册表、MainActor 配置和锁保护调试快照四种边界。新增共享状态必须先登记 owner、保护方式、
失效策略和 6.0 替代计划。

## 验证入口

```bash
bash Scripts/validate_concurrency_5_19.sh
bash Scripts/validate_quality_scans.sh
xcodebuild -workspace PooTools.xcworkspace -scheme PooTools-Example \
  -configuration Debug -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build
```

静态门禁只能证明源码边界和构建契约；PhotoKit、WebKit、Vision、权限弹窗和真实设备性能仍需要真实
宿主验证。
