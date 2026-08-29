# PTools 5.x Core 迁移与兼容说明

本文记录 `PooTools.podspec` 的 `Core` 范围在 5.x 中的唯一实现入口、兼容包装器和
6.0.0 删除条件。5.x 不删除现有公开符号；旧入口只在确认调用方完成迁移后，才允许
在 6.0.0 评估中移除。

## 唯一实现入口

| 能力 | 5.x 推荐入口 | 旧入口处理 |
| --- | --- | --- |
| 图片加载 | `PTLoadImageFunction.loadImage(source:)` | 保留动态来源适配器 |
| 图片、原图数据和视频请求 | `PTMediaLibManager` 类型化请求入口 | `fetch*` 入口保留为兼容包装器 |
| 视频缩略图 | `PTVideoThumbnailService` | 保留 `UIImage`/`PHAsset` 便捷入口 |
| 媒体保存 | `PTMediaSaveService` | `PHPhotoLibrary`、`UIImage` 和媒体管理器入口代理到服务 |
| 空状态 | `PTUnavailableManager.render` | UIView 和 UIViewController 入口只负责适配 |
| 场景窗口和当前页面 | `PTSceneContext` | 旧 `PTUtils` 查询入口逐步迁移 |
| UI 调度 | `PTMainActorBridge` | `PTGCDManager` 主线程入口保留兼容性 |
| 网络请求 | `Network` 内部执行管线 | `Any`、KakaJSON 和 callback 入口保留在兼容层 |

### 5.6.1 ScrollBanner 与 PageControl

- 新代码使用 `PTBannerView`，统一轮播、分页、标题、箭头、媒体播放和生命周期处理。
- `PTCycleScrollView` 在 5.x 继续保留，但已作为 deprecated 兼容适配器转发到 `PTBannerView`；
  现有的图片、标题、箭头、PageControl 和滚动入口无需立即修改。
- 自定义 PageControl 统一使用 `PTBasePageControl` 的进度、无障碍和 Reduce Motion 边界；
  旧的各个具体 PageControl 类型继续保留。
- `PTCycleScrollViewCell` 是无仓库调用的内部实现，已移除；外部只应依赖公开的 Banner 类型和
  `PTBannerCell` 入口。

重复入口的当前状态由 [重复入口报告](Scripts/report_duplicate_entries.sh) 输出，并由质量
检查执行时校验。每一组都必须明确 canonical、deprecated wrapper、semantic difference、
pending 和 removal gate，避免将语义不同的功能机械合并。

## Swift 6 迁移边界

- UI 状态和 UI completion 在 `MainActor` 上执行。
- 网络结果、请求上下文和进度跨 actor 时使用 Sendable 快照。
- PhotoKit、AVFoundation 等系统对象只在窄范围适配器中跨边界传递。
- 不将 `Any`、`[String: Any]`、`[AnyHashable: Any]` 或 `Progress` 引入并发核心执行器。
- 仅在系统对象兼容确有必要时保留 `@unchecked Sendable`，并登记在
  `Scripts/unchecked_sendable_allowlist.txt`。

## 6.0.0 删除评估条件

以下条件必须全部满足，才能删除对应的 deprecated 或动态兼容入口：

1. 仓库源码和示例工程中没有调用方，且重复报告中的 pending 已变为 `none`。
2. 至少一个完整的 5.x 版本周期提供类型化入口和迁移说明。
3. CocoaPods、SwiftPM 和 Xcode 的 Core 源文件契约保持一致，公开符号回归通过。
4. Swift 6 严格并发检查不再需要旧动态入口提供的非 Sendable 参数。
5. 迁移后不存在依赖 `PTAlertDebugView`、旧媒体保存回调或旧 Network 动态返回值的外部
   兼容承诺；必要时提供替代适配器，而不是直接删除符号。

当前结论：5.x 继续保留上述兼容层；5.6.1 只完成 ScrollBanner/PageControl 治理和兼容迁移，
不提前删除公开 API。
