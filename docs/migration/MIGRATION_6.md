# PTools 5.x → 6.0 迁移清单

本文只覆盖 `PooTools.podspec` `default_subspec` 声明的 Core 及其直接扩展边界。目标平台为
iOS 17+，语言模式为 Swift 6+。

## 1. Migration Policy

5.x 保留公开符号和模块路径；新能力进入 canonical API，旧入口作为薄兼容包装器并标记迁移方向。
6.0 只有在仓库、Example 和至少一个真实宿主完成回归后，才删除已批准的入口。删除清单不能仅
根据静态搜索生成，必须人工确认公开调用方和行为差异。

## 2. Canonical API

| 能力 | 推荐入口 | 旧入口/兼容层 | 起始版本 | 6.0 条件 |
| --- | --- | --- | --- | --- |
| 网络 Codable 模型 | `PTCodableModelProtocol` | `PTModelProtocol` | 5.1.0 | 所有模型迁移且 API baseline 批准 |
| 列表身份 | `PTDiffableModel` + 稳定 `diffId` | 混合模型身份 | 5.1.0 | 无随机 ID 和旧混合协议调用 |
| 进度 | `PTProgressSnapshot` | 跨 actor `Progress` | 5.9.0 | 全部并发入口使用快照 |
| 响应元数据 | `PTResponseMetadata` | `[AnyHashable: Any]` | 5.9.0 | 动态字典只留边界适配 |
| 场景 | `PTSceneContext` | 全局 keyWindow/window 查询 | 5.0.0 | 无宿主依赖旧查询 |
| UI 调度 | `PTMainActorBridge` | 重复 `DispatchQueue.main.async` | 5.0.0 | 兼容调用方迁移完成 |
| 图片加载 | `PTLoadImageFunction.loadImage(source:)` | 控件和字符串重复入口 | 5.1.0 | 旧入口调用方清零 |
| 视频缩略图 | `PTVideoThumbnailService` | AVAsset/FileManager 旧入口 | 5.1.0 | 结果和缓存回归通过 |
| 媒体保存 | `PTMediaSaveService` | UIImage/PHPhotoLibrary 重复保存 | 5.1.0 | 兼容包装器调用方清零 |
| 媒体值类型 | `PTMediaAsset` / `PTMediaMetadata` / `PTMediaSource` | Picker/Viewer/Editor 自定义基础模型 | 5.15.0 | 所有新跨模块接口使用值快照 |
| 图片降采样 | `PTImageDownsampler` | `UIImage(data:)` 和本地文件重复解码 | 5.15.0 | 大图入口全部提供目标尺寸 |
| 媒体缓存 | `PTMediaCache` | 模块私有原图/缩略图/GIF 缓存 | 5.15.0 | 旧缓存目录迁移或自然淘汰 |
| 空状态 | `PTUnavailableManager.render` | Base/Collection 独立状态实现 | 5.1.0 | 状态机回归通过 |
| 基础 URL | `Network.globalURL()` | `Network.gobalUrl()` | 5.9.0 | 删除拼写兼容入口 |
| Socket URL | `Network.socketGlobalURL()` | `Network.socketGobalUrl()` | 5.9.0 | 删除拼写兼容入口 |
| 导航栏配置 | `PTBaseNavControl.globalNavControl` | `GobalNavControl` | 5.9.0 | 删除拼写兼容入口 |
| 图片配置 | `webImageLoadOptions` | `gobalWebImageLoadOption` | 5.9.0 | 删除拼写兼容入口 |
| ActionSheet 高亮色 | `highlightColor` | `heightlightColor` | 5.9.0 | 删除拼写兼容入口 |
| 网络超时 | `requestTimeout` 等 | `netRequsetTime` 等 | 5.9.0 | 删除拼写兼容入口 |
| UserDefaults | `PTCoreUserDefaultsWrapper` | `PTCoreUserDefultsWrapper` | 5.9.0 | 删除拼写兼容类型 |
| ScrollBanner | `PTBannerView` | `PTCycleScrollView` | 5.6.1 | 轮播迁移和宿主回归通过 |
| 单媒体选择 | `PTSystemMediaPicker` | `PTImagePicker` 旧闭包入口 | 5.6.5 | 宿主迁移完成 |
| PTInstruments | `PTInstrumentRecorder` | 无自动兼容入口 | 5.11.x | 6.0 稳定契约冻结 |

## 3. Core

- UI、配置和 UI completion 使用 `MainActor`。
- 跨 actor 只传 `Data`、`URL`、字符串、数字、枚举和不可变快照。
- PhotoKit、AVFoundation、CoreNFC 等系统对象只通过窄范围包装器跨边界。
- `@unchecked Sendable` 必须登记在 `Scripts/unchecked_sendable_allowlist.txt`；业务模型不得新增。
- Network 的 `Any`、KakaJSON 和 callback 入口留在兼容层，不进入新的并发执行器。

## 4. Network

新代码优先使用 `PTNetworkRequest` 和 `PTNetworkExecutor`。普通参数、Body、上传、下载、cache、
retry、dedup、认证刷新和 cancellation 统一走内部请求上下文。迁移动态请求时要人工确认参数编码、
错误映射、进度和取消语义，不要仅替换方法名。

### 4.1 Socket / Security

新 WebSocket 代码使用 `PTWebSocketClient`；新安全代码使用 `PTSecurity`。`PTSocketManager`、
SocketRocket、DataEncrypt、KeyChain 和 SecuritySuite 入口在 5.x 保留为兼容层，6.0 删除前必须
完成真实宿主迁移、Keychain 数据迁移和断网/认证回归。

## 5. Navigation

使用所属 `UIWindowScene` 的 `PTSceneContext`，不要读取全局 key window。`PTBaseViewController`、
`PTBaseNavControl` 和 TabBar 样式依据当前导航栈顶页面与交互式转场进度刷新，避免 A/B/C 页面
之间复用错误的导航栏状态。

## 6. Collection

使用稳定 `diffId`；不要用每次读取生成的 UUID。列表页面优先继承 `PTListViewController` 并使用
单一 `PTCollectionView`，不要为类表格页面再维护独立 UITableView 数据源。Cell 复用时取消旧
请求、清理动画和 generation，并确认 skeleton/empty/error/content 的状态转换。

## 7. Media

单媒体系统选择使用 `PTSystemMediaPicker`；多选、原图、Live Photo、编辑和 iCloud 进度使用
`PTMediaLibViewController`。图片加载使用 `PTLoadImageFunction`，视频首帧使用
`PTVideoThumbnailService`，保存使用 `PTMediaSaveService`。视频临时 URL 的生命周期由调用方明确管理。
跨模块描述使用 `PTMediaAsset`、`PTMediaType`、`PTMediaMetadata`、`PTMediaResource` 和
`PTMediaSource`。大图优先传递 `targetSize`，缓存使用 `PTMediaCacheKey` 的明确变体；编辑结果不
覆盖原图缓存键。视频缓存支持取消、并发去重、Range 续传和原子提交，退出 Viewer/Editor 时调用
对应媒体对象的 `invalidate()`。

## 8. Permissions

权限请求应使用统一状态和 exactly-once completion，并回到 `MainActor`。denied、restricted、
limited、provisional、ephemeral、cancelled 和系统错误都必须有终态；不要让调用方等待一个不会再次
到来的 delegate 回调。5.16.0 起系统服务在页面退出时调用 `stop()` 或 `invalidate()`，尤其是 IAP、
NFC、Motion、HealthKit、MetricKit 和 GPS；旧 callback 入口仍保留，但内部统一经过异步状态桥接。

## 9. Debug / PTInstruments

Debug 和 PTInstruments 是可选产品。新宿主通过 `LocalConsole.console(for:)` 绑定 Scene，使用
`PTInstrumentRecorder` 显式开始采样；Core 不自动创建诊断 UI、DisplayLink、采样 Task 或日志 sink。
`.pttrace` 归档前后都应脱敏。

## 10. Renamed / Typo APIs

以下旧入口在 5.x 保留，但新代码不得继续使用：

```text
Network.gobalUrl()                 → Network.globalURL()
Network.socketGobalUrl()           → Network.socketGlobalURL()
PTBaseNavControl.GobalNavControl   → PTBaseNavControl.globalNavControl
gobalWebImageLoadOption            → webImageLoadOptions
heightlightColor                   → highlightColor
netRequsetTime                     → requestTimeout
PTCoreUserDefultsWrapper           → PTCoreUserDefaultsWrapper
```

历史公开拼写 `BilogyID`、`MeidaPermission` 和 `ObjFetchFaild` 暂不直接重命名，以免破坏外部
`switch`、Podfile 或类型引用；6.0 需先提供完整映射和迁移期。

## 11. Before / After Recipes

```swift
// Before: global window and dynamic request result.
// Antes: ventana global y resultado dinámico de la solicitud.
// 之前：全局窗口和动态请求结果。
let window = UIApplication.shared.keyWindow
let value = try await Network.requestApi(...)

// After: scene-aware UI and typed request result.
// Después: interfaz consciente de la escena y resultado tipado.
// 之后：按场景处理界面并使用类型化请求结果。
guard let scene = view.window?.windowScene else { return }
let console = LocalConsole.console(for: scene)
let value: User = try await Network.requestCodableApi(...)
```

```swift
// Before: legacy media and scrolling implementation.
// Antes: implementación heredada de medios y desplazamiento.
// 之前：旧媒体和滚动实现。
PTImagePicker.openAlbum(...)
let banner = PTCycleScrollView(...)

// After: choose the smallest canonical boundary.
// Después: elige el límite canónico más pequeño.
// 之后：选择最小的 canonical 边界。
let picker = PTSystemMediaPicker()
let banner = PTBannerView(...)
```

## 12. Real Project Checklist

- [ ] 记录宿主使用的 deprecated API、动态字典和全局 window 查询。
- [ ] 先迁移 Core、Scene、Navigation、Collection，再迁移 Network、Media 和 Debug。
- [ ] 验证图片/GIF/视频/iCloud、权限、保存失败、取消和 Cell 复用。
- [ ] 验证 Light/Dark、Dynamic Type、Reduce Motion、Reduce Transparency 和 VoiceOver。
- [ ] 在真实设备和真实宿主完成 Debug/PTInstruments 性能与隐私检查。
- [ ] 更新 API baseline、module graph、CHANGELOG 和迁移记录。

## 13. Deprecated APIs

兼容入口至少保留一个完整发布周期。`@available(*, deprecated, message:)` 的迁移提示必须
指向 canonical API，不得在兼容包装器内复制实现。删除前需要：仓库和 Example 无调用方、真实
宿主完成迁移、API 差异获批、三套构建入口通过，以及对应回滚方案已准备。

## 14. 6.0 Removed APIs

只有满足第 13 节条件后，才可删除：已明确迁移的拼写错误入口、重复媒体保存实现、旧图片/视频
请求包装器、全局窗口查询和 `PTModelProtocol` 的混合身份职责。系统对象兼容包装器、必要的
二进制适配器和仍有外部调用的公开符号不能为了“干净”直接删除。

仓库内 Example 页面和回归范围见 [`EXAMPLE.md`](../guides/EXAMPLE.md)；当前 API 和 deprecated
扫描结果见 `report/current/`。
