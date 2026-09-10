# PTools 5.9.x 依赖与供应链清单

当前仓库基线：`5.9.6`（最新标签 `5.9.6`）。`Core` 是
`PooTools.podspec` 的 `default_subspec`，其他模块都围绕 Core 扩展。本文件记录依赖所有权、
可复现约束、维护风险和替换路线；不修改第三方源码。

## 5.9.6 处理结果

| 项目 | 当前处理 | 证据或剩余工作 |
| --- | --- | --- |
| Branch 依赖 | 已完成 | AttributedString、SocketRocket 使用固定 revision；`Package.swift` 不含 `branch:` |
| Kitura 链 | 已评估 | PooTools 仅在 CheckUpdate 直接使用 Swift-JWT；Blue*、LoggerAPI、KituraContracts 为传递依赖，暂不重写 JWT |
| Codable 双栈 | 已评估 | SmartCodable 为主要模型入口；KakaJSON 限定为现有兼容路径，6.0 再评估拆出 Serialization |
| Bugly | 已完成示例工程解耦 | 删除旧 Bugly Pod；示例工程使用 `canImport(Bugly)`，宿主项目必须提供带 Simulator slice 的 XCFramework 才能重新接入 |
| 所有权文档 | 已完成 | 本文件和 `report/dependency_supply_chain_5_9_6.md` |

## 5.9.7 模块集合与直接依赖

以下只记录 CocoaPods subspec 的直接依赖；Core 的传递依赖不会因为选择上层模块而重复声明。
SwiftPM 使用对应 product 名称，详见 `Package.swift`。

| 模块集合 | CocoaPods 入口 | SwiftPM product | 直接依赖 | 不直接带入 |
|---|---|---|---|---|
| Minimal / UIKit Base | `PooTools/Core` | `ptools` | SwiftDate、SnapKit、SwifterSwift、CocoaLumberjack、DeviceKit、AttributedString、IQKeyboardManager、Kingfisher、SafeSFSymbols、SmartCodable、KakaJSON、Lottie | Alamofire、Kakapos、Harbeth、GCDWebServer |
| Network | `PooTools/NetWork` | `PooToolsNetWork` | `PooTools/Core`、`PooTools/Loading`、Alamofire | PhotoPicker、MediaViewer、VideoEditor |
| ImagePicker | `PooTools/ImagePicker` | `PooToolsImagePicker` | `PooTools/Core`、`PooTools/CameraPermission` | PhotoKit 浏览器和多选编辑流程 |
| PhotoPicker | `PooTools/PhotoPicker` | `PooToolsPhotoPicker` | `PooTools/Core`、`PooTools/ImagePicker`、`PooTools/NetWork`、`PooTools/Loading`、Kakapos | VideoEditor、MediaViewer |
| MediaViewer | `PooTools/MediaViewer` | `PooToolsMediaViewer` | `PooTools/Core`、ProgressBar、NetWork、PageControl、LivePhoto、Photos | ImagePicker、PhotoPicker 浏览器 |
| VideoEditor | `PooTools/VideoEditor` | `PooToolsVideoEditor` | `PooTools/Core`、HarbethKit、ProgressBar、Loading | PhotoPicker、Network 请求层 |
| ScrollBanner / PageControl | `PooTools/ScrollBanner`、`PooTools/PageControl` | `PooToolsScrollBanner`、`PooToolsPageControl` | ScrollBanner → Core + PageControl；PageControl → Core | Network、媒体模块 |
| Debug | `PooTools/DEBUG` | `PooToolsDEBUG` | Core、NetWork、Share、SearchBar、PDF | Bugly；宿主必须自行提供兼容 XCFramework |

`ImagePicker` 与 `PhotoPicker` 有意共存：前者是单媒体系统入口，后者是多选、编辑、原图和
Live Photo 的自定义 PhotoKit 浏览器。不要仅因为两者都能选图片就把它们合并为同一个依赖。

## Swift Package Manager

| Dependency | Module | Reason | Maintainer Risk | Replacement |
| --- | --- | --- | --- | --- |
| SwiftDate | Core | 日期解析和格式化扩展 | 中；Core API 覆盖面较广 | Foundation `Calendar` / `ISO8601Format`，6.0 评估 |
| SnapKit | Core/Base/UI | 现有 UIKit 布局 DSL | 低；公开代码大量使用 | 原生 `NSLayoutConstraint`，不在 5.x 强制迁移 |
| SwifterSwift | Core | 常用 Foundation/UIKit 扩展 | 中；扩展调用分散 | 按调用点迁移到系统 API |
| CocoaLumberjack | Core/Log | 文件与控制台日志 | 中；日志行为需兼容 | `OSLog` 与内部日志适配器 |
| DeviceKit | Core | 设备型号和能力判断 | 中；版本覆盖需维护 | `UIDevice` / `utsname` 封装 |
| AttributedString | Core/Button | 富文本构造 | 中；上游为 revision 固定 | Foundation `AttributedString` 与 UIKit 转换层 |
| IQKeyboardManager | Core | 键盘避让兼容 | 中；影响宿主全局行为 | UIKit 键盘通知和 `keyboardLayoutGuide` |
| Kingfisher | Core/Image | 图片缓存和加载 | 中；图片路径调用较多 | `PTLoadImageFunction` + URLSession/缓存适配器 |
| SmartCodable | Core/Network | 主要 Codable 模型解析 | 中；Swift 6 兼容和宏/运行时行为需跟踪 | Foundation Codable 或独立 Serialization feature |
| KakaJSON | Core/Network | 历史动态模型兼容 | 高；动态 API 和 Swift 6 边界不安全 | 仅保留兼容包装器，6.0 评估移出 Core |
| Lottie | Core/组件 | 动画资源播放 | 中 | UIKit/Core Animation，按组件逐步替换 |
| Alamofire | Network | 上传、下载和请求适配 | 中；必须经过统一执行器 | URLSession 原生执行器，6.0 评估 |
| NotificationBanner / MarqueeLabel | Core/UI | 提示条和滚动文本 | 中 | UIKit 自实现 |
| Swift-JWT | CheckUpdate | Apple API JWT 签名 | 高；Kitura 链旧且触发 Swift 6 诊断 | CryptoKit/Security + 内部 JWT 适配器，目标 6.0 |
| SocketRocket | SocketKit | WebSocket 兼容 | 中；仓库使用固定 revision | URLSessionWebSocketTask，6.0 评估 |

### 固定 revision

| Dependency | URL | Revision |
| --- | --- | --- |
| AttributedString | `https://github.com/lixiang1994/AttributedString.git` | `d8a72a7e29e8699979b052b59659720087bc2ea0` |
| SocketRocket | `https://github.com/robnadin/SocketRocket.git` | `fe86ec01176ea3365ffa2d04a2bb6dd7a9e6c01e` |

固定 revision 解决可复现性问题，但不等价于上游稳定 release；后续应在经过构建和 API 回归后再升级到稳定 tag。

## Kitura 依赖评估

- `PooToolsSource/CheckUpdate/PTCheckUpdateFunction.swift` 是仓库内唯一直接导入 `SwiftJWT` 的生产源码。
- `BlueCryptor`、`BlueRSA`、`BlueECC`、`LoggerAPI` 和 `KituraContracts` 由 Swift-JWT 传递引入；它们不再在
  `Package.swift` 作为 PTools 直接依赖重复声明，但仍会出现在解析结果中。
- 5.9.x 保留现有 JWT 行为，不在稳定版本中进行加密实现替换。
- 6.0 迁移目标是使用 CryptoKit/Security 实现窄范围 JWT 签名适配，并在删除 Swift-JWT 前完成 Apple API 回归。
- 当前 CocoaPods 的 Swift-JWT/KituraContracts 仍可能被外部 Swift 6 诊断阻断；这属于依赖环境阻断，不能归因于 Core 源码。

## SmartCodable / KakaJSON 双栈边界

- SmartCodable：用于 Core 模型、网络模型及部分组件，是 5.x 的主要类型化解析入口。
- KakaJSON：保留在 `PTBaseModel` 和 Network 的历史兼容边界；新代码不得让 `Any` 或 KakaJSON 动态结果穿过并发执行器。
- 两者暂不在 5.x 强制删除，避免破坏公开模型和旧请求入口。
- 6.0 计划将兼容层移动到独立 Serialization feature，并提供 Codable 迁移说明。

## CocoaPods 与二进制框架

- 当前 `Podfile.lock` 的 PooTools 版本为 `5.9.6`。
- 旧版 Bugly `2.6.1` 仅提供 `Bugly.framework`，没有 XCFramework，也没有 arm64 Simulator slice；已从示例工程 Podfile 和 lockfile 移除。
- `PooTools/AppDelegate.swift` 的 Bugly 启动保留在 `#if canImport(Bugly)` 中。真实宿主如需崩溃上报，必须自行提供同时包含 Simulator slice 和通用 device archive 的供应商 XCFramework。
- 本轮未修改 Pods 源码，也未主动升级其他依赖版本。

## 验证记录

| 检查 | 结果 |
| --- | --- |
| `pod install --no-repo-update` | 通过，移除 Bugly，其他依赖保持解析结果 |
| `Package.swift` branch 扫描 | 通过 |
| AttributedString / SocketRocket revision 扫描 | 通过 |
| 直接 Kitura 源码使用扫描 | 仅 CheckUpdate 使用 Swift-JWT |
| Xcode Debug / Release | 需以当前依赖状态重新执行；外部 KituraContracts Swift 6 诊断仍可能阻断 |

详细证据和未完成项见 `report/dependency_supply_chain_5_9_6.md`。
