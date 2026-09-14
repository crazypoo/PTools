# PTools 依赖与供应链

本文件描述当前依赖的用途、所有权、风险和替换策略，不绑定某个历史版本。当前版本号和一次
解析结果分别由 `PooTools.podspec`、`Podfile.lock` 和 `report/current/` 维护；本文件不修改
第三方源码。

## Ownership rules

- `PooTools/Core` 是 `PooTools.podspec` 的 `default_subspec`，其他能力围绕 Core 扩展。
- SwiftPM 的 `PToolsCore`、`PToolsUIFoundation`、`PToolsPermissionCore` 和 `PToolsPermissionUI`
  提供分层契约；`ptools` 是兼容 umbrella。
- 功能模块只声明直接依赖，不在文档中重复计算传递依赖。
- 第三方依赖的版本、revision 和实际解析状态以 `Package.swift`、`Podfile.lock` 和自动报告为准。
- 不为了解决外部 Pods 的 Swift 6 警告修改 Pods 源码或把依赖错误归因于 PTools Core。

## Direct dependency groups

| 模块 | CocoaPods | SwiftPM | 主要直接依赖 | 不应直接带入 |
| --- | --- | --- | --- | --- |
| Core / UIKit Base | `PooTools/Core` | `ptools` | SwiftDate、SnapKit、SwifterSwift、CocoaLumberjack、DeviceKit、AttributedString、IQKeyboardManager、Kingfisher、SmartCodable、KakaJSON、Lottie | Network、PhotoKit 浏览器、Debug UI |
| Network | `PooTools/NetWork` | `PooToolsNetWork` | Core、Loading、Alamofire | PhotoPicker、MediaViewer、VideoEditor |
| ImagePicker | `PooTools/ImagePicker` | `PooToolsImagePicker` | Core、CameraPermission | PhotoKit 多选浏览器 |
| PhotoPicker | `PooTools/PhotoPicker` | `PooToolsPhotoPicker` | Core、ImagePicker、Network、Loading、Kakapos | VideoEditor、MediaViewer |
| MediaViewer | `PooTools/MediaViewer` | `PooToolsMediaViewer` | Core、ProgressBar、Network、PageControl、LivePhoto、Photos | ImagePicker、PhotoPicker 浏览器 |
| ImageEditor | `PooTools/ImageEditor` | `PooToolsImageEditor` | Core、HarbethKit、PhotoPicker | Network 请求层 |
| VideoEditor | `PooTools/VideoEditor` | `PooToolsVideoEditor` | Core、HarbethKit、ProgressBar、Loading | Network 请求层 |
| ScrollBanner / PageControl | `PooTools/ScrollBanner`、`PooTools/PageControl` | 对应 `PooToolsScrollBanner`、`PooToolsPageControl` | Core；ScrollBanner 使用 PageControl | Network、媒体模块 |
| Debug | `PooTools/DEBUG` | `PooToolsDEBUG` | Core、Network、Share、SearchBar、PDF | Core 反向依赖 Debug；生产不隐式启动诊断 |

ImagePicker 与 PhotoPicker 有意共存：前者负责单媒体系统选择和相机，后者负责多选、编辑、原图、
Live Photo、自定义 Cell 和 iCloud 进度。不要因都能选择图片就合并成一条不清晰的依赖。

## Third-party inventory

| 依赖 | 所属边界 | 用途 | 维护风险 | 替换方向 |
| --- | --- | --- | --- | --- |
| SwiftDate | Core | 日期解析和格式化 | 中 | Foundation `Calendar` / ISO8601 |
| SnapKit | Core / UI | UIKit 布局 DSL | 低至中 | 原生 `NSLayoutConstraint`，按模块迁移 |
| SwifterSwift | Core | Foundation/UIKit 扩展 | 中 | 按调用点迁移系统 API |
| CocoaLumberjack | Core / Debug | 日志 sink 和文件日志 | 中 | OSLog + 内部日志适配器 |
| DeviceKit | Core | 设备型号和能力判断 | 中 | `UIDevice` / `utsname` 封装 |
| AttributedString | Core / Button | 富文本构造 | 中 | Foundation `AttributedString` 适配层 |
| IQKeyboardManager | Core / UI | 键盘避让兼容 | 中 | `keyboardLayoutGuide` 和通知 |
| Kingfisher | Core / Image | 图片缓存和加载 | 中 | `PTLoadImageFunction` + URLSession/cache |
| SmartCodable | Core / Network | 类型化模型解析 | 中 | Foundation Codable 或独立 Serialization |
| KakaJSON | 兼容层 | 历史动态模型解析 | 高 | 只保留兼容包装器，6.0 评估移出 Core |
| Lottie | UI / Debug | 动画资源播放 | 中 | UIKit / Core Animation |
| Alamofire | Network | 上传、下载和请求适配 | 中 | URLSession 统一执行器 |
| NotificationBanner / MarqueeLabel | UI | 提示条和滚动文本 | 中 | UIKit 自实现 |
| Swift-JWT | CheckUpdate | Apple API JWT 签名 | 高 | CryptoKit/Security 窄适配器 |
| SocketRocket | SocketKit | WebSocket 兼容 | 中 | URLSessionWebSocketTask |

## Fixed revisions

当前已固定的外部 revision：

| 依赖 | URL | Revision |
| --- | --- | --- |
| AttributedString | `https://github.com/lixiang1994/AttributedString.git` | `d8a72a7e29e8699979b052b59659720087bc2ea0` |
| SocketRocket | `https://github.com/robnadin/SocketRocket.git` | `fe86ec01176ea3365ffa2d04a2bb6dd7a9e6c01e` |

固定 revision 只保证可复现，不等价于上游 release 稳定；升级必须经过构建、API 和运行时回归。

## Kitura / JWT boundary

`PTCheckUpdateFunction.swift` 是仓库内直接使用 `Swift-JWT` 的生产路径。BlueCryptor、BlueRSA、
BlueECC、LoggerAPI 和 KituraContracts 是传递依赖，不在 PTools Core 重复声明。当前 5.x 保留 JWT
行为；6.0 再评估使用 CryptoKit/Security 的窄范围实现。外部依赖的 Swift 6 诊断属于环境阻断，
不应通过修改 Pods 源码解决。

## Codable dual stack

SmartCodable 是当前类型化入口；KakaJSON 只留在 `PTBaseModel` 和 Network 的历史兼容边界。新
代码不得让 `Any` 或 KakaJSON 动态结果进入 Swift 6 并发核心执行器。后续可在独立 Serialization
feature 中完成迁移，不能在兼容版本中直接删除公开模型。

## Binary and validation

Bugly 等二进制 SDK 必须提供与目标平台匹配的 XCFramework 或 simulator/device slices；缺失产物、
Metal toolchain、签名和链接搜索路径单独记入 `report/baselines/`。依赖图、module parity、branch
扫描和供应链事实以 `report/current/` 为准。
