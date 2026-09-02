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

### 5.7.0 PTListViewController

`PTListViewController` 是 Core 的列表页面基类。它只承载一个 `PTCollectionView`：`.Normal`
用于类表格的纵向列表，Grid、Waterfall、Tag、Horizontal 和 Custom 继续使用
`PTCollectionView` 的集合布局能力。它不引入第二套 `UITableView` 数据源，也不改变现有
`PTCollectionView` 的 Diffable、Cell 或公开回调入口。

```swift
@MainActor
final class ExampleListController: PTListViewController {
    override func makeListViewConfiguration() -> PTCollectionViewConfig {
        let configuration = PTCollectionViewConfig()
        configuration.viewType = .Normal
        return configuration
    }

    override func configureListView(_ listView: PTCollectionView) {
        listView.collectionDidSelect = { _, _, _ in
            // Configure the page-specific selection behavior here.
            // Configura aquí el comportamiento de selección específico de la página.
            // 在这里配置页面专属的选择行为。
        }
    }
}
```

默认列表使用安全区约束；需要全屏列表或额外头部时，覆盖
`prepareListViewLayout(_:)` 和 `installListViewConstraints(_:)`。控制器不会接管
`PTCollectionView` 的 delegate，基类的大标题滚动过渡与原有业务滚动回调会同时保留。

### 5.6.3 ScreenShot 与 MessageKit

- ScreenShot 的 UIView、UIScrollView、UITableView、UIWindow 和 WKWebView 继续保留原有公开入口；新的统一渲染器负责场景缩放、像素上限、长截图状态恢复和取消。
- MessageKit 的消息模型和列表 Row 使用稳定 Diffable 身份；现有 `PTChatView`、Cell、媒体、地图、文件、音频和输入动画入口无需修改。
- 复用 Cell 的异步资源会校验当前代次；外部无法取消的旧回调仍会安全忽略，不需要调用方增加取消代码。

### 5.6.2 Language 通知修复

- `PTLanguage.share.language` 现在比较解析后的有效语言；同一有效语言重复赋值不会发送通知，异常存储值会安全归一化。
- `LanguageDidChangedKey` 在主线程投递。`pt_observerLanguage(didChanged:)` 和
  `pt_viewObserverLanguage(didChanged:)` 的公开签名不变，监听状态改由独立通知 token 管理，
  支持重复注册、显式移除和宿主对象销毁时自动清理。
- 既有监听入口继续提供注册时立即回调；无需修改现有调用方。`PTLanguage.share.language = ...`
  仍然兼容，推荐继续在不需要监听时调用对应的 `pt_removeObserverLanguage()`。
- `.localized()` 现在优先通过 Foundation 的 `LocalizedStringResource` 解析 Xcode
  String Catalog（`.xcstrings`）以及旧的 `.strings` 资源；手动语言选择和旧 `.lproj` bundle
  调用方式继续兼容。新项目只需将 Catalog 加入对应 target 的 Target Membership。

### 5.6.1 ScrollBanner 与 PageControl

- 新代码使用 `PTBannerView`，统一轮播、分页、标题、箭头、媒体播放和生命周期处理。
- `PTCycleScrollView` 在 5.x 继续保留，但已作为 deprecated 兼容适配器转发到 `PTBannerView`；
  现有的图片、标题、箭头、PageControl 和滚动入口无需立即修改。
- 自定义 PageControl 统一使用 `PTBasePageControl` 的进度、无障碍和 Reduce Motion 边界；
  旧的各个具体 PageControl 类型继续保留。
- `PTCycleScrollViewCell` 是无仓库调用的内部实现，已移除；外部只应依赖公开的 Banner 类型和
  `PTBannerCell` 入口。

### 5.6.4 Button 模块

- `PTLoginDescButton` 可通过 `PTLoginDescConfig.leftAttributedDesc` 和
  `PTLoginDescConfig.rightAttributedDesc` 配置富文本；纯文本 `leftDesc`、`rightDesc` 和原有
  `descHandler` 继续兼容。
- Layout、Action 和 Sort 按钮继续保留原有状态、图片和初始化入口；新代码会自动处理异步图片
  取消、状态代次和安全布局，不需要调用方增加取消代码。
- `PTMenuSheetButtonItems` 的尺寸、边距、标题对齐、图片模式和 highlighted 图文现在都会生效；
  `PTMenuSheetButtonView` 的 `open()`/`close()` 支持快速反向调用，并遵循 Reduce Motion。

### 5.6.5 ImagePicker 与 PhotoPicker

- `PooToolsImagePicker` / `PooTools/ImagePicker` 是轻量系统媒体入口：图片库使用
  `PHPickerViewController`，相机使用 `UIImagePickerController`，适合单张图片、单个视频、图片或视频的选择。
- 推荐使用 `@MainActor` 的 `PTSystemMediaPicker.pick(_:from:)` 和
  `PTSystemMediaPicker.capture(_:from:)`，结果为 `PTSystemMediaPickerResult`；视频 URL 已复制到独立临时文件，成功后由调用方负责后续生命周期。
- `PooToolsPhotoPicker` / `PooTools/PhotoPicker` 继续保留自定义 PhotoKit 浏览器，负责多选、编辑、原图、Live Photo、自定义 Cell 和 iCloud 进度；它通过 ImagePicker 复用相机权限和 metadata 结果适配，不改为 PHPicker。
- `PTImagePicker` 的泛型 `Controller`、旧 `openAlbum`、`photograph` 和闭包便利入口继续保留，但已标记 deprecated；5.x 不删除，迁移目标为 `PTSystemMediaPicker`，计划在 6.0.0 再评估移除。
- 轻量系统入口中的 Live Photo 按静态图片返回；需要完整 Live Photo 资源时继续使用 PhotoPicker 的自定义 PhotoKit 路径。

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

当前结论：5.x 继续保留上述兼容层；5.6.5 只完成 ImagePicker/PhotoPicker 的边界拆分和入口统一，
不提前删除公开 API。
