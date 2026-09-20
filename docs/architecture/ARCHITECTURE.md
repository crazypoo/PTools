# PTools 当前架构

## 1. Architecture Principles

PTools 面向 iOS 17+ / Swift 6+，优先采用 UIKit、Foundation、PhotoKit、AVFoundation 和
Swift Concurrency 的系统能力。Core 是稳定契约边界，扩展模块可以依赖 Core，但 Core 不依赖
业务模块、Debug UI 或宿主应用。

架构治理遵循：

- 一个能力只保留一个 canonical implementation；旧入口只能做兼容转发。
- UI 状态和 UI completion 位于 `MainActor`。
- 跨 actor 只传不可变值类型、快照、URL、Data、字符串、数字和枚举。
- PhotoKit、AVFoundation、CoreNFC 等系统对象只在窄范围适配器中跨并发边界。
- 不用 `@unchecked Sendable`、`nonisolated(unsafe)`、`try!` 或 `as!` 掩盖业务状态问题。

## 2. Module Layers

```text
Foundation-only Core values / parsers
                ↓
PToolsCore + PToolsUIFoundation + PToolsPermissionCore
                ↓
ptools / PooTools Core (UIKit, Category, Base, Theme)
                ↓
Network / Media / Navigation / Permission / Feature modules
                ↓
Debug / PTInstruments adapters and Example host
```

`PooTools.podspec` 的 `default_subspec` 是 `Core`。SwiftPM 通过 `PToolsCore`、
`PToolsUIFoundation`、`PToolsPermissionCore` 和 `PToolsPermissionUI` 提供分层 target，
`ptools` 继续作为兼容 umbrella；CocoaPods 和 Xcode 保留公开 source membership。

## 3. Dependency Direction

- Core 可以提供 URL 解析、场景解析、MainActor bridge、值类型模型、缓存协议、日志契约和 UIKit 基础能力。
- Network、PhotoPicker、VideoEditor、ImageEditor、Picker、ScrollBanner 等模块依赖 Core。
- Debug 依赖 Core 和需要的功能模块；Core 不引用 `LocalConsole`、Inspector、Debug window、PTInstruments 或 Debug 偏好。
- Permission Core 只提供状态、结果、错误、请求协议和设置 URL；Permission UI 是可选上层。
- 第三方库的所有权、用途和替换策略见 [DEPENDENCIES.md](DEPENDENCIES.md)。

## 4. Core Boundary

Core 的长期 canonical 入口包括：

| 能力 | 唯一入口 | 兼容入口策略 |
| --- | --- | --- |
| 场景和当前页面 | `PTSceneContext` | 旧全局 window 查询转发并逐步弃用 |
| UI 调度 | `PTMainActorBridge` | `PTGCDManager` 保留兼容入口 |
| 图片加载 | `PTLoadImageFunction.loadImage(source:)` | 控件、字符串和旧来源入口转发 |
| 视频缩略图 | `PTVideoThumbnailService` | `AVAsset`、FileManager 旧方法转发 |
| 媒体保存 | `PTMediaSaveService` | UIImage、PHPhotoLibrary 和管理器入口转发 |
| 空状态 | `PTUnavailableManager.render` | Base 和 Collection 只做适配 |
| 网络请求 | Network request context / executor | Any、KakaJSON、callback 保留在兼容层 |
| 列表身份 | 稳定存储的 `PTDiffableModel.diffId` | 旧模型协议不再生成随机 ID |

## 5. Permission Boundary

系统权限请求由各自模块拥有系统 delegate 和请求生命周期，公共状态映射和完成语义放在
Permission Core。请求完成必须 exactly once，并回到 `MainActor`；restricted、denied、limited、
未决定和系统错误不能让 async 调用永久等待。

Photo Library、Camera、Location、Contacts、NFC、Motion、Notification、Health 等系统对象
不跨模块暴露可变共享状态；需要跨边界时使用结果快照或窄范围包装器。

## 6. Network Boundary

Network 的 Codable、Body、普通参数、上传、下载、callback、async 和 stream 入口最终进入统一
请求上下文。新代码使用 `PTNetworkRequest`、`PTNetworkResponse` 和 `PTNetworkExecutor`；请求上下文
负责 headers、cache policy、retry、dedup、cancellation、认证刷新、错误转换和脱敏日志。旧动态
`Any` 入口不得进入并发核心执行器，旧 callback 入口只负责适配结果。

缓存按 `none`、`cacheOnly`、`networkOnly`、`cacheElseNetwork` 和 `networkElseCache` 处理，并保留
ETag、Last-Modified、Cache-Control、304 与损坏缓存恢复信息。重试必须经过幂等性策略；认证刷新由
actor 合并，避免并发 401 产生刷新风暴。

## 6.1 Socket / Security Boundary

新 WebSocket 入口是 actor 隔离的 `PTWebSocketClient`，只交换 `PTWebSocketMessage`、状态和配置值；
`PTSocketManager` 与 SocketRocket 仅作为兼容适配层保留。连接状态、发送队列、心跳、路径变化和前后台
生命周期由客户端统一管理。

新安全入口是 `PTSecurity`，只暴露 Foundation、CryptoKit 和 Security.framework 可表达的值类型；
Keychain accessibility、生物识别项目、AES-GCM、HMAC、摘要、P-256 签名和验签不把 CryptoSwift、
IOSSecuritySuite 或其他第三方类型泄漏到公共契约。旧安全 API 由兼容层继续维护。

## 7. Navigation / TabBar

`PTBaseViewController`、`PTBaseNavControl` 和 `PTBaseTabBarViewController` 共享
`PTSceneContext` 与导航栏样式解析。页面样式按当前栈顶控制器和交互式转场进度刷新，不能读取
另一个导航栈的全局样式。TabBar 外观使用值快照，iOS 26+ 的系统玻璃效果只在可用系统版本启用，
旧系统保持动态颜色和材质回退。

5.13.0 起，导航栏项目在转场回调中绑定到具体的 UINavigationController 和目标控制器；TabBar
 的过期转场完成回调会被丢弃，并在安全区、旋转、分屏和台前调度变化后显式恢复可见性状态。

## 8. Collection / List

`PTCollectionView` 是列表和集合的统一实现；`PTListViewController` 只承载一个
`PTCollectionView`，`.Normal` 提供类表格布局，其他 `viewType` 提供 Grid、Waterfall、Tag、
Horizontal 和 Custom。Diffable 更新使用稳定 ID，Cell 复用清理旧请求、generation、手势、
播放器和动画。Skeleton、empty、loading、error 和 content 由统一状态入口管理。

5.13.0 起，Diffable 快照提交在组件内部串行化并报告重叠更新，空 Row 身份和非法列数在进入布局
 引擎前被拒绝；`PTReusableTaskBag` 为高频 Cell 提供统一的异步任务取消和内容重置契约。

## 9. Media

ImagePicker 是轻量系统单媒体入口，PhotoPicker 是自定义 PhotoKit 多媒体入口；两者共存但不
重复承担同一职责。图片请求、视频缩略图、原图数据、媒体保存和导出均使用类型化结果与取消路径。
大图、GIF、视频原始数据和导出对象不能无界长期持有。

## 10. Theme / Appearance

Theme、DarkMode、Colors、Font 和 Alert/ActionSheet 使用动态系统颜色、trait collection 和
safe-area。`nil` 的背景配置表示使用系统默认动态背景，而不是黑色兜底。Reduce Motion、Reduce
Transparency、Dynamic Type 和 VoiceOver 是组件契约的一部分。

## 11. Scene / Lifecycle

所有窗口、当前页面、Alert、Debug window 和媒体 UI 都通过 `PTSceneContext` 解析所属 Scene。
不得用全局 key window 代替场景上下文。Scene disconnect 时释放窗口、sink、observer、Task、
delegate 和临时资源；不可逆 runtime hook 由 owner registry 记录，不伪造 undo。

## 12. Concurrency Model

- UI 类型默认 `@MainActor`。
- 共享缓存、去重、计数器和可变采样状态使用 actor 或锁保护状态对象。
- `PTProgressSnapshot`、`PTResponseMetadata` 等快照是跨 actor 的公共契约。
- `@unchecked Sendable` 只允许系统对象兼容包装器并登记在 allowlist；业务模型优先改成值类型。
- Crash signal / NSException handler 不调用 Swift actor、UI、文件导出或日志 sink。

## 13. Compatibility Layer

5.x 不删除公开符号。旧入口通过薄包装器调用 canonical implementation，并在
[`MIGRATION_6.md`](../migration/MIGRATION_6.md) 登记起始版本和 6.0 删除条件。兼容层不得再复制
业务实现、维护第二套缓存或产生随机 Diffable 身份。

## 14. Debug Boundary

Debug 与 PTInstruments 的结构、采样边界、隐私和多 Scene 规则见
[`DEBUG_AND_INSTRUMENTS.md`](DEBUG_AND_INSTRUMENTS.md)。

## 15. Verification

当前 module graph、source parity、API baseline、并发 allowlist 和回归结果位于 `report/`。
静态报告不替代 Xcode iOS 构建、真机、真实宿主和 Instruments 验收。
