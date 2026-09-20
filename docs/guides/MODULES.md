# PTools 模块与安装指南

## 选择原则

`PooTools/Core`（SwiftPM product `ptools`）是默认基础边界。功能模块按需选择；不要为了使用
一个 UI 组件把所有 subspec 或 `PooToolsAll` 带入宿主。实际依赖图以 `report/current/` 中的
生成报告为准。

## 推荐入口

| 能力 | CocoaPods | Swift Package Manager | 典型用途 |
| --- | --- | --- | --- |
| Core / UIKit Base | `PooTools/Core` | `ptools` | Base、Category、Theme、列表和基础权限 |
| MediaCore | `PooTools/MediaCore` | `PooToolsMediaCore` | 媒体值类型、来源、元数据和并发契约 |
| Network | `PooTools/NetWork` | `PooToolsNetWork` | Codable、上传、下载、缓存和取消 |
| Security | `PooTools/Security` | `PooToolsSecurity` | Keychain、CryptoKit 摘要、HMAC、AES-GCM、签名和验签 |
| Socket | `PooTools/SocketKit` | `PooToolsSocketKit` | actor WebSocket、心跳、重连和发送队列 |
| ImagePicker | `PooTools/ImagePicker` | `PooToolsImagePicker` | 单媒体系统选择、相机 |
| PhotoPicker | `PooTools/PhotoPicker` | `PooToolsPhotoPicker` | 多选、PhotoKit、原图、Live Photo、编辑 |
| MediaViewer | `PooTools/MediaViewer` | `PooToolsMediaViewer` | 图片、GIF、视频预览 |
| ImageEditor | `PooTools/ImageEditor` | `PooToolsImageEditor` | 图片裁剪、贴纸、滤镜、编辑导出 |
| VideoEditor | `PooTools/VideoEditor` | `PooToolsVideoEditor` | 视频编辑和导出 |
| PDF / SVG / Screenshot / QRCode | `PooTools/PDF`、`PooTools/SVG`、`PooTools/SmartScreenshot`、`PooTools/ScanQRCode` | 对应 products | 文档渲染、矢量、截图和二维码 |
| ScrollBanner | `PooTools/ScrollBanner` | `PooToolsScrollBanner` | `PTBannerView` 轮播 |
| PageControl | `PooTools/PageControl` | `PooToolsPageControl` | 分页指示器 |
| Picker | `PooTools/Picker` | `PooToolsPicker` | 嵌入式或覆盖层滚轮选择器 |
| Router | `PooTools/Router` | `PooToolsRouter` | 类型化路由和安全实例化 |
| Debug | `PooTools/DEBUG` | `PooToolsDEBUG` | LocalConsole、Inspector、PTInstruments |

## CocoaPods

```ruby
pod 'PooTools/Core'
pod 'PooTools/NetWork'
pod 'PooTools/PhotoPicker'
```

不在文档中固定未发布 Git tag。正式版本从 CocoaPods 或对应正式 tag 安装；当前开发线请先确认
`PooTools.podspec` 与 `Podfile.lock` 的版本事实。

## SwiftPM

在 Xcode 中添加：

```text
https://github.com/crazypoo/PTools.git
```

优先选择最小 product。`PooToolsAll` 只适合示例工程或确实需要完整功能的宿主。

## Core 与基础 UI

`ptools` 通过 re-export 保持旧 `import ptools` 入口；`PToolsCore`、`PToolsUIFoundation`、
`PToolsPermissionCore` 和 `PToolsPermissionUI` 是内部边界明确的分层 product。Core 不包含 Debug UI、
完整 Network 实现或特定业务页面。

## Permission

系统权限产品按能力选择：`PTCameraPermission`、`PTLocationPermission`、`PTCalendarPermission`、
`PTContactsPermission`、`PTMicPermission`、`PTNotificationPermission`、`PTBluetoothPermission`、
`PTSpeechPermission`、`PTHealthPermission`、`PTFaceIDPermission`、`PTMotionPermission`、
`PTTrackingPermission`、`PTRemindersPermission`、`PTSiriPermission` 和 `PTMediaPermission`。
公共状态和结果来自 Permission Core；UI 页面属于可选 Permission UI/兼容层。

5.16.0 起新代码优先读取 `authorizationState`，不要把旧 `Bool` 或四值 `PTPermissionStatus` 当作完整
权限语义。系统服务退出页面时调用对应的 `stop()` 或 `invalidate()`：IAP、NFC、Motion、HealthKit、
MetricKit 和 GPS 会释放各自的观察者、会话、查询和代理；Notification、Photos 和 Location 的 callback
兼容入口仍保证只完成一次。

## UI / Data / Device

常用 UI products 包括 `PooToolsCustomerLabel`、`PooToolsProgressBar`、`PooToolsLoading`、
`PooToolsHud`、`PooToolsSearchBar`、`PooToolsSegmented`、`PooToolsSlider`、`PooToolsStepper`、
`PooToolsPagingControl`、`PooToolsRateView`、`PooToolsTipsView`、`PooToolsNotificationBanner`、
`PooToolsPopoverKit` 和 `PooToolsInput`。

5.17.x 的 UI/Utility 全量结账清单见
[`UI_COMPONENTS_5_17.md`](../ui/UI_COMPONENTS_5_17.md)。SearchBar、Picker、HUD/Loading/Tips、
WebKit、ZipArchive 和 GCDWebServer 的生命周期与外部依赖边界由 `Scripts/validate_517_ui.sh`
统一检查；清单中的真实宿主回归不能由静态门禁代替。

数据、设备和网络 products 包括 `PooToolsDataEncrypt`、`PooToolsKeyChain`、`PooToolsPhoneInfo`、
`PooToolsTelephony`、`PooToolsVision`、`PooToolsScanQRCode`、`PooToolsSocketKit`、
`PooToolsNetworkSpeedTest`、`PooToolsSpeedPanel`、`PooToolsPDF`、`PooToolsSVG`、
`PooToolsZipArchive` 和 `PooToolsWebKit`。

完整 CocoaPods subspec 名称以 `PooTools.podspec` 为准，完整 SwiftPM product/target 以
`swift package dump-package` 和 `report/current` 为准。新增模块应先更新 podspec/manifest，
再更新本文件，不在这里复制依赖实现。

Network 新代码从 `PTNetworkExecutor` 开始；Socket 新代码从 `PTWebSocketClient` 开始；安全存储和
密码学新代码从 `PTSecurity` 开始。旧入口只用于兼容既有宿主，迁移时不要同时维护第二套请求、重连
或密钥存储逻辑。

Media 新代码从 `PTMediaCore` 的值类型、`PTLoadImageFunction.loadImage(source:)`、
`PTVideoThumbnailService`、`PTMediaSaveService` 和 `PTMediaCache` 开始。单媒体选择使用
`PTSystemMediaPicker`，多媒体 PhotoKit 浏览使用 `PTMediaLibViewController`；`targetSize` 应传入
图片加载入口，避免在 Cell 或 Viewer 内自行完整解码大图。

## 依赖与迁移

每个模块的直接依赖、第三方风险和替换策略见
[`DEPENDENCIES.md`](../architecture/DEPENDENCIES.md)。5.x 兼容入口、canonical 入口和 6.0
删除条件见 [`MIGRATION_6.md`](../migration/MIGRATION_6.md)。
