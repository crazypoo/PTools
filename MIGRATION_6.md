# PTools 6.0 迁移清单

状态：5.9.x 进行中，当前源码基线为 5.8.9。本文只覆盖 PooTools.podspec
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

## 6.0.0 删除门槛

- PUBLIC_API_5_8.json 与 PUBLIC_API_5_9.json 的删除差异已人工批准。
- 兼容入口至少经过一个完整 5.9.x 发布周期。
- PooTools Example、CrazyDashboard 和真实业务宿主不再调用待删除入口。
- Core 的 Swift 6 strict concurrency、iOS 17 Simulator Debug/Release 和依赖矩阵通过。
- 迁移文档、CHANGELOG、RELEASE 和包管理入口同步完成。
