# PTools 6.0 迁移清单

状态：5.9.7 Migration 进行中，当前源码基线和最新标签为 `5.9.6`。本文只覆盖 PooTools.podspec
default_subspec 声明的 Core 及其直接扩展边界，目标平台为 iOS 17+，语言模式为 Swift 6。

## 迁移原则

1. 5.9.x 不删除公开符号；旧入口只保留兼容转发。
2. 新代码优先使用表中的 canonical API，不再复制第二套业务实现。
3. 只有完成 API 差异、Xcode Debug/Release、CocoaPods、SwiftPM 和宿主项目回归后，才允许在 6.0.0 删除入口。
4. UIKit、PhotoKit、AVFoundation 和通知回调的 UI 结果统一回到 MainActor。

## Canonical API 清单

| 能力 | Canonical API | Deprecated API | 起始版本 | 6.0.0 处理 |
| --- | --- | --- | --- | --- |
| 网络 Codable 模型 | PTCodableModelProtocol | PTModelProtocol | 5.1.0 | 删除条件待验证 |
| 列表 Diffable 身份 | PTDiffableModel，稳定存储 diffId | PTModelProtocol 混合身份 | 5.1.0 | 删除混合协议 |
| 进度快照 | PTProgressSnapshot | Progress 跨并发边界 | 5.9.0 | 保留 |
| 响应元数据 | PTResponseMetadata | [AnyHashable: Any] 跨 actor | 5.9.0 | 保留 |
| 场景解析 | PTSceneContext | 全局 keyWindow/window 查询 | 5.0.0 | 删除旧查询 |
| 场景依赖注入 | PTSceneContextProviding / PTDefaultSceneContextProvider | 直接读取全局单例 | 5.9.0 | 保留 |
| UI 调度 | PTMainActorBridge | 重复 DispatchQueue.main.async | 5.0.0 | 保留 |
| 请求基础 URL | Network.globalURL() | Network.gobalUrl() | 5.9.0 | 删除拼写错误入口 |
| Socket 基础 URL | Network.socketGlobalURL() | Network.socketGobalUrl() | 5.9.0 | 删除拼写错误入口 |
| 导航栏样式 | PTBaseNavControl.globalNavControl | PTBaseNavControl.GobalNavControl | 5.9.0 | 删除拼写错误入口 |
| 网络图片配置 | PTAppBaseConfig.webImageLoadOptions | gobalWebImageLoadOption | 5.9.0 | 删除拼写错误入口 |
| 调试图片配置 | PTDevFunction.webImageLoadOptions | gobalWebImageLoadOption | 5.9.0 | 删除拼写错误入口 |
| ActionSheet 高亮色 | PTActionSheetItem.highlightColor | heightlightColor | 5.9.0 | 删除拼写错误入口 |
| 网络请求超时 | PTNetworkConfig.requestTimeout | netRequsetTime | 5.9.0 | 删除拼写错误入口 |
| 下载请求超时 | PTNetworkConfig.downloadRequestTimeout | downloadRequsetTime | 5.9.0 | 删除拼写错误入口 |
| 资源超时 | PTNetworkConfig.resourceTimeout | downloadEndTime | 5.9.0 | 删除拼写错误入口 |
| 缓存有效期 | PTNetworkConfig.networkCacheExpiration | networkCacheEXPTime | 5.9.0 | 删除拼写错误入口 |
| 去重策略 | PTNetworkConfig.networkDedupOption | networkDudupOption | 5.9.0 | 删除拼写错误入口 |
| 用户默认值包装器 | PTCoreUserDefaultsWrapper | PTCoreUserDefultsWrapper | 5.9.0 | 删除拼写错误入口 |
| 媒体保存 | PTMediaSaveService | UIImage/PHPhotoLibrary 重复保存实现 | 5.1.0 | 保留兼容层 |
| 图片加载 | PTLoadImageFunction.loadImage(source:) | 字符串和控件重复加载入口 | 5.1.0 | 保留兼容层 |
| 视频缩略图 | PTVideoThumbnailService | AVAsset、FileManager 旧入口 | 5.1.0 | 保留兼容层 |
| 空状态 | PTUnavailableManager.render | 控件内部独立空状态 | 5.1.0 | 保留 |

## 暂不重命名的兼容符号

- PTImagePicker.PickerError.ObjFetchFaild 是公开错误枚举成员。5.9.x 不直接替换
  枚举 case，避免改变外部 switch 的源码兼容性；6.0.0 迁移时再提供完整错误类型映射。
- CocoaPods 的 BilogyID、MeidaPermission 是历史 subspec 名称。5.9.x 保留原名，
  由发布检查和文档提示迁移，不通过新增同义 subspec 破坏依赖图。
- Network、PhotoPicker、VideoEditor 的 Any/KakaJSON 入口只停留在兼容层，
  类型化入口进入并发核心执行器前必须先完成宿主迁移。

## 使用示例

    let baseURL = await Network.globalURL()
    var configuration = PTNetworkConfig()
    configuration.requestTimeout = 30
    configuration.networkDedupOption = .disabled

    let item = PTActionSheetItem(title: "确定")
    item.highlightColor = .systemGray5

## 5.9.7 迁移配方

下表按照 `Before / After / Reason / Automatic migration possibility / Behavior difference` 记录
5.x 兼容入口。5.9.x 仍保留旧入口；6.0.0 只有在删除门槛全部满足后才移除。

| Before | After | Reason | Automatic migration possibility | Behavior difference |
|---|---|---|---|---|
| `PTModelProtocol` 同时承担 Codable 和 Diffable | `PTCodableModelProtocol` + `PTDiffableModel` | 分离解析能力和列表身份 | 可以按协议声明批量替换；`diffId` 需人工确认是否稳定 | Codable 不再隐含列表身份 |
| `Network.gobalUrl()` | `Network.globalURL()` | 修复公开拼写并统一 async 入口 | 可用 Swift Rename 或全局替换 | 返回值和请求行为保持兼容 |
| `Network.socketGobalUrl()` | `Network.socketGlobalURL()` | 修复公开拼写 | 可自动替换 | 行为不变 |
| `PTBaseNavControl.GobalNavControl` | `PTBaseNavControl.globalNavControl` | 修复公开拼写 | 可自动替换 | 仍指向同一导航控制器配置 |
| `gobalWebImageLoadOption` | `webImageLoadOptions` | 统一图片加载配置命名 | 可自动替换 | 配置值保持不变 |
| `PTActionSheetItem.heightlightColor` | `highlightColor` | 修复公开拼写 | 可自动替换 | 高亮颜色行为不变 |
| `PTNetworkConfig.netRequsetTime` | `requestTimeout` | 统一请求超时字段 | 可自动替换 | 超时单位和默认值不变 |
| `PTCoreUserDefultsWrapper` | `PTCoreUserDefaultsWrapper` | 修复公开类型拼写 | 可自动替换类型名 | UserDefaults key 不变 |
| `PTCycleScrollView` | `PTBannerView` | 统一 ScrollBanner 实现 | 不能安全自动替换初始化参数和回调 | 轮播、分页和媒体回调以 `PTBannerView` 为准 |
| `PTImagePicker` 旧闭包入口 | `PTSystemMediaPicker` | 统一系统单媒体选择结果 | 不能自动替换权限和结果处理 | 视频 URL 使用独立临时文件，Live Photo 仍需 PhotoPicker |
| `PTMediaLibManager.fetchImage` | `PTMediaLibManager.requestImage` | 统一 request ID、取消、降级和复用保护 | 方法名可替换，Cell 复用逻辑需人工检查 | 结果状态更明确，旧 completion 继续兼容 |
| Network `Any` / KakaJSON 请求 | 类型化 Codable 请求 | 避免动态值跨 Swift 6 并发边界 | 只能按 modelType 逐接口迁移 | 解析失败从运行时动态失败变为明确错误 |

### Example 迁移顺序

仓库内示例页面的入口和回归范围见
[`EXAMPLE_MODULES_5_9.md`](EXAMPLE_MODULES_5_9.md)。推荐迁移顺序：

1. 先将宿主的 Core、Navigation、Collection 页面切换到稳定的 Base 和场景入口。
2. 再按单媒体/多媒体边界选择 `PTSystemMediaPicker` 或 `PTMediaLibViewController`。
3. 将 Network 的 Codable 请求迁移到类型化入口，再处理上传、下载和取消。
4. 最后迁移 Debug、Alert、Theme 和 Accessibility 场景，并删除宿主侧重复的全局窗口查找。

真实宿主项目不在本仓库内；宿主迁移必须单独记录编译错误、运行时差异和待删除入口，不能以
`PooTools-Example` 的通过替代真实宿主验收。

## 6.0.0 删除门槛

- PUBLIC_API_5_8.json 与 PUBLIC_API_5_9.json 的删除差异已人工批准。
- 兼容入口至少经过一个完整 5.9.x 发布周期。
- PooTools Example、CrazyDashboard 和真实业务宿主不再调用待删除入口。
- Core 的 Swift 6 strict concurrency、iOS 17 Simulator Debug/Release 和依赖矩阵通过。
- 迁移文档、CHANGELOG、RELEASE 和包管理入口同步完成。
