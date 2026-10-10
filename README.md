# PooTools

<p align="center">
<a href=""><img src="https://img.shields.io/cocoapods/p/PooTools.svg"></a>
<a href=""><img src="https://img.shields.io/badge/platform-iOS%2017.0%2B-ff69b5152950834.svg"></a>
</p>

## About

PooTools 是面向 iOS 应用的 UIKit、Foundation、媒体、网络、权限和调试工具库。Core 是默认
基础边界，其他功能按需安装。

PTools 支持中文、粤语、英文和西班牙语资源。当前开发代码基线为 iOS 17+ / Swift 6+，版本事实
以 `VERSION`、`PooTools.podspec` 和正式 Git tag 为准；当前开发基线为 `5.63.0`，真机/宿主回归与发布证据完成前不创建正式 tag。

5.63.0 增加 iPhone Duo 自适应 Navigation / TabBar：默认复用 UIKit 的 Scene-aware 垂直 Bar 能力，旧系统和未提供 vertical edge 的场景保持横向 PTools 外观；几何、overflow、reserved region 和 DEBUG overlay 说明见 [iPhone Duo 自适应 Bar 指南](docs/guides/PTIPHONE_DUO_ADAPTIVE_BARS.md)。

DebugNetwork 2.0 是只读观测工具，支持 immutable capture、Timeline、过滤、脱敏 cURL/HAR/Text 导出和多 Scene presentation。使用方式见 [DebugNetwork 指南](docs/debug/DEBUG_NETWORK.md)。

5.61.0 增加 `PTSplitViewController` 的 iPhone / iPad 自适应分栏、compact 导航栈、Router、状态
恢复和 Inspector Demo，同时增加 `PTNetworkSpeedTester`、`PTPingSession`、HeartRate 安全状态和
`PTStorage` 文件 I/O 收口。使用示例见
[SplitView 指南](docs/splitview/PTSplitViewController_Guide.md)、[测速指南](docs/network/PTNetworkSpeedTester_Guide.md)、
[Ping 指南](docs/ping/PTPingSession_Guide.md) 和 [5.61.0 迁移说明](docs/migrations/5.61_RUNTIME_SAFETY.md)。

5.62.0 增加可选的应用基础设施：SQLite 数据库、认证、离线同步、后台传输、StoreKit 2、可观测性、
WKWebView Bridge、MapKit、App Attest/DeviceCheck、远程配置和 SSE/WebSocket 实时能力。它们不进入
默认 Core 或 `PooToolsAll`，按需选择 `PTools*` SwiftPM product 或 `PooTools/*` CocoaPods subspec。
使用边界和迁移示例见 [5.62.0 应用基础设施指南](docs/guides/PTOOLS_APPLICATION_INFRASTRUCTURE_5_62.md)。

5.62.1 解耦 TabBar 的选中背景 Insets、Item 内容 Insets 和内容 Offset，并修复 `UILabel` / `UIImageView`
使用 `backgroundGradient` 时渐变层遮挡文字或图片的问题。迁移方式见
[5.62.1 TabBar 与渐变迁移说明](docs/migration/5.62.1_TABBAR_CONTENT_SELECTION.md)。

5.62.2 修复 `tabItemContentInsets` 不改变真实 `content.view` 尺寸的问题：正值缩小内容、有限负值扩展内容，
并让 Badge、Mini、UIImage、Lottie 和自定义 Content 复用同一份尺寸计算。迁移方式见
[5.62.2 TabBar Content Size 修正](docs/migration/5.62.2_TABBAR_CONTENT_SIZE_FIX.md)。

`PTCollectionView` 的 Diffable 内容刷新、稳定身份、布局失效和快速更新用法见
[PTCollectionView Diffable 更新指南](docs/guides/PTCOLLECTIONVIEW_UPDATE_GUIDE.md)。

运行中切换 Normal、Gird、WaterFall、Horizontal、Tag 和 Custom 布局，以及保留位置、选中状态和配置同步，
见 [PTCollectionView Runtime Layout 切换指南](docs/guides/PTCOLLECTIONVIEW_LAYOUT_SWITCH_GUIDE.md)。

Core 的 `UIControl` 原生菜单、动态菜单和 Selection Menu 用法见
[UIControl Menu 指南](docs/guides/PTCONTROL_MENU_GUIDE.md)。

## Requirements

- iOS 17.0+
- Swift 6+
- Xcode 适配当前 SDK

## Installation

### Swift Package Manager

在 Xcode 中添加：

```text
https://github.com/crazypoo/PTools.git
```

最常用的 product 是 `ptools`（Core）。其他功能 product 和 CocoaPods subspec 的对应关系见
[模块选择与安装指南](docs/guides/MODULES.md)。

模型转换可以单独使用 Foundation-only 的 `PToolsModelCore` / `PToolsModel`，不需要引入
SmartCodable 或 KakaJSON：

```swift
struct User: Codable { let id: Int; let name: String }
let user = try User.pt.model(from: #"{"id":1,"name":"Jax"}"#)
let json = try user.pt.jsonString()
```

PTModel 与 Network 的嵌套模型、响应包裹和 `modelPath` 用法见
[5.60.0 Quick Start](docs/model/PTMODEL_NETWORK_QUICKSTART_5_60.md)。

设备身份与系统能力可单独使用 SwiftPM `PToolsDevice` 或 CocoaPods `PooTools/Device`，迁移方式见
[DeviceKit 迁移指南](docs/migrations/DEVICEKIT_TO_PTOOLS_DEVICE.md)。

### CocoaPods

```ruby
pod 'PooTools/Core'
pod 'PooTools/ModelCore' # 不依赖 SmartCodable / KakaJSON 的模型核心
pod 'PooTools/NetWork'
pod 'PooTools/PhotoPicker'
pod 'PooTools/Banner'
pod 'PooTools/HTTPServer'
# 需要原生锚点弹层和 Context Menu 时添加：
# pod 'PooTools/Popover'
# 需要原生分段与分页控件时添加：
# pod 'PooTools/PagingControl'
# 需要浏览器文件门户时再添加：
# pod 'PooTools/HTTPFilePortal'
# 需要原生 coach mark 引导时添加：
# pod 'PooTools/Instructions'
# 需要主题、页面状态、表单、文档、BLE、模拟或无障碍能力时按需添加：
# pod 'PooTools/Theme'
# pod 'PooTools/ContentState'
# pod 'PooTools/Form'
# pod 'PooTools/Bluetooth'
# pod 'PooTools/Documents'
# pod 'PooTools/Simulation'
# pod 'PooTools/Accessibility'
# 需要配置、触觉或音频基础设施时按需添加：
# pod 'PooTools/Configuration'
# pod 'PooTools/Feedback'
# pod 'PooTools/Audio'
# AppIntents、WidgetCore、Activities 面向扩展目标，单独添加并保持 extension-safe：
# pod 'PooTools/AppIntents'
# pod 'PooTools/WidgetCore'
# pod 'PooTools/Activities'
# 需要应用基础设施时按需添加：
# pod 'PooTools/Database'
# pod 'PooTools/Auth'
# pod 'PooTools/Sync'
# pod 'PooTools/Transfer'
# pod 'PooTools/StoreKit'
# pod 'PooTools/Observability'
# pod 'PooTools/Web'
# pod 'PooTools/Map'
# pod 'PooTools/AppIntegrity'
# pod 'PooTools/Realtime'
```

按功能选择最小 subspec；需要完整示例时才考虑 `PooToolsAll`。

Form 2.0 的多 Section、布局、校验、键盘、无障碍和自定义 Renderer 用法见
[PTools Form 2.0 指南](docs/guides/PTOOLS_FORM_GUIDE.md)，从 5.56.x 迁移请阅读
[Form 2.0 迁移说明](docs/migrations/5.57_FORM_2.md)。

引导提示使用 `PooToolsInstructions`（SwiftPM）或 `PooTools/Instructions`（CocoaPods）。它复用
Overlay 的 Scene、Anchor、定位和生命周期能力，不创建第三方引导窗口。使用示例见
[PooToolsInstructions 指南](docs/guides/PTINSTRUCTIONS_GUIDE.md)。

分段和分页控件从 5.31.1 起提供稳定 ID、动态角标更新、懒加载页面、生命周期、Header/固定 Header、内外层滚动协调、刷新控件和回顶入口。旧 JX 场景迁移请阅读
[YDShipOrder Paging 教程](docs/migrations/YD_SHIP_ORDER_PTOOLS_PAGING_TUTORIAL.md)。

包入口、直接依赖、测试领域、文档治理和公开 API 迁移分别见
[PACKAGE_MATRIX](docs/architecture/PACKAGE_MATRIX.md)、
[DEPENDENCY_MATRIX](docs/architecture/DEPENDENCY_MATRIX.md)、
[TEST_MATRIX](docs/maintainers/TEST_MATRIX.md)、
[PTools 文档索引](docs/index/README.zh-Hans.md) 和
[6.0 迁移说明](docs/migration/MIGRATION_6.md)。

5.35.0 的 P1 高阶能力使用说明见
[P1 Advanced Capabilities 指南](docs/guides/PTOOLS_P1_ADVANCED_CAPABILITIES.md)。

5.36.1 的 P0/P1/P2 收口与 P2 现代系统扩展使用说明见
[P2 Modern Extensions 指南](docs/guides/PTOOLS_P2_MODERN_EXTENSIONS.md)。

### Native HTTP Server

`PToolsHTTPServer` 基于 iOS 17+ `Network.framework` 和 Swift 6 actor，提供类型化请求/响应、
增量 HTTP/1.1 解析、Keep-Alive、静态文件 Range、SSE、gzip、TLS、Bonjour 和可选中间件。
文件浏览器单独位于 `PToolsHTTPFilePortal`；旧的 `PooTools/GCDWebServer` subspec 只保留为
兼容别名，不再引入 GCDWebServer 或 WebUploader。迁移示例见
[GCDWebServer 迁移指南](docs/migrations/GCDWEBSERVER_TO_PTOOLS_HTTP_SERVER.md)。

## Quick Start

### Base 页面

```swift
@MainActor
final class ExampleViewController: PTBaseViewController {
    override func preferredNavigationBarStyle() -> PTNavigationBarStyle {
        .solid(.systemBackground)
    }
}
```

### 列表页面

`PTListViewController` 只承载一个 `PTCollectionView`，`.Normal` 可用于类表格纵向列表，其他
布局类型继续提供 Gird（网格）、Waterfall、Tag、Horizontal 和 Custom；公开枚举使用历史拼写 `.Gird`。

```swift
@MainActor
final class ExampleListViewController: PTListViewController {
    override func makeListViewConfiguration() -> PTCollectionViewConfig {
        let configuration = PTCollectionViewConfig()
        configuration.viewType = .Normal
        return configuration
    }
}
```

已展示的列表也可以安全切换布局；`.Gird` 是当前公开 case 的历史拼写：

```swift
list.updateLayoutConfiguration(animated: true) { config in
    config.viewType = .Gird
    config.rowCount = 2
    config.cellLeadingSpace = 8
    config.cellTrailingSpace = 8
}

list.switchLayout(to: .Normal, scrollPolicy: .firstVisibleItem)
```

### 图片和媒体

图片加载优先使用 `PTLoadImageFunction.loadImage(source:)`，大图按 `targetSize` 通过
`PTImageDownsampler` 解码；视频缩略图使用 `PTVideoThumbnailService` 和变体缓存；保存图片或视频使用
`PTMediaSaveService`。旧入口仍兼容，迁移条件见
[MIGRATION_6.md](docs/migration/MIGRATION_6.md)。

### Rich Text

富文本统一使用 `PTRichText`，底层存储为 Foundation `AttributedString`，需要 UIKit 展示时显式桥接：

```swift
let title: PTRichText = "欢迎 \(userName, .foreground(.secondaryLabel))"
titleLabel.pt_apply(richText: title)
```

图片和视频附件通过 `PTLoadImageFunction` 的统一 source 入口加载；Core 模块只负责封面、播放标记、
时长和点击事件，不在富文本内持有播放器：

```swift
@MainActor
func applyMedia() {
    let text = PTRichText("封面：")
        .appendingImage(source: imageSource,
                        configuration: .init(estimatedAspectRatio: 1))
        .appendingVideo(source: videoURL,
                        configuration: .init(estimatedAspectRatio: 16.0 / 9.0))

    let loader = PTLoadImageFunction.makeRichTextMediaLoader()
    titleLabel.pt_apply(richText: text,
                        mediaLoader: loader) { interaction in
        if case .media(.video(let id)) = interaction {
            // 交给宿主播放器或 PTMediaBrowser 处理，不在 PTRichText 内创建 AVPlayer。
            print("播放视频附件：\(id)")
        }
    }
}
```

`imageSource` 可以直接使用 URL、String、UIImage、Data、AVAsset 或其他
`PTLoadImageFunction.loadImage(source:)` 支持的来源。下载中的内容先显示占位图，复用或替换富文本时旧请求会取消，
避免异步结果串写。Action、链接、匹配、Markdown、本地化和附件描述仍保持为值数据；点击行为通过
`PTTextActionRegistry` 或控件回调注册，不把闭包写进富文本模型。

### 搜索页面

需要完整搜索容器时选择 `PooTools/Search` 或 `PooToolsSearch`；只使用输入框时继续选择
`PooTools/SearchBar` 或 `PooToolsSearchBar`。搜索基类复用 `PTListViewController`、`PTCollectionView`
和 `PTSearchBar`，统一处理取消、防抖、竞态、历史、分页、刷新、空状态和错误状态。

```swift
@MainActor
final class ExampleSearchViewController: PTSearchViewController<String> {
    private let source: [String] = []

    override func search(keyword: String) async throws -> [String] {
        source.filter { $0.localizedCaseInsensitiveContains(keyword) }
    }

    override func didSelect(item: String, at indexPath: IndexPath) {
        // English: Handle the selected result.
        // Español: Procesa el resultado seleccionado.
        // 中文：处理用户选中的搜索结果。
    }
}
```

### Picker

- 单图片、单视频和相机：`PooToolsImagePicker` / `PooTools/ImagePicker`。
- 多选、原图、Live Photo、自定义 PhotoKit 浏览：`PooToolsPhotoPicker` / `PooTools/PhotoPicker`。
- 需要把滚轮选择器放入已有页面时，先 `configure(...)`，再添加到宿主 View；覆盖层展示才调用 `show()`。

### Network

新代码使用 `PTNetworkRequest` 与 `PTNetworkExecutor`，普通参数、Body、上传、下载、取消、缓存、
重试、去重和认证刷新统一由 Network 请求管线处理。动态 `Any` 与 KakaJSON 入口仅作为兼容层保留。

### SF Symbols

Core 使用 `PToolsSymbols` 提供类型化 SF Symbols、别名、回退和可选变量值解析。新代码优先使用
`UIImage(ptSymbol:)` 或 `UIImage.pt_symbol(_:fallback:)`；只有服务端或运行时拼接名称才使用
`PTSymbol(rawValue:)`。具体迁移规则见
[SafeSFSymbols 迁移指南](docs/migrations/SAFESFSYMBOLS_TO_PTSYMBOL.md)。

### Socket / Security

新 WebSocket 代码使用 actor 隔离的 `PTWebSocketClient`；旧 `PTSocketManager` 和 SocketRocket
入口继续作为 5.x 兼容层。新安全代码使用 `PTSecurity` 的 CryptoKit/Security.framework 入口；
旧 DataEncrypt、KeyChain 和 SecuritySuite API 保持兼容，不把第三方类型暴露到新入口。

### Debug

Debug 和 PTInstruments 不会自动进入 Core 运行路径；测试环境显式安装 `PooToolsDEBUG` 后，
使用 `LocalConsole.console(for:)` 或 `PTInstrumentRecorder`。多 Scene 页面应传入明确的
`UIWindowScene`，避免控制台显示到错误窗口。5.18.0 起可通过 `PTDebugHookRegistry` 统一安装/卸载
诊断 Hook，并使用 `.pttrace` 的导入、回放和对比入口分析录制结果。

## Documentation

- [模块选择与安装](docs/guides/MODULES.md)
- [Example 页面与回归入口](docs/guides/EXAMPLE.md)
- [当前架构](docs/architecture/ARCHITECTURE.md)
- [Swift 6 并发边界](docs/architecture/CONCURRENCY.md)
- [Debug 与 PTInstruments](docs/architecture/DEBUG_AND_INSTRUMENTS.md)
- [依赖与模块边界](docs/architecture/DEPENDENCIES.md)
- [CocoaPods / SwiftPM 包矩阵](docs/architecture/PACKAGE_MATRIX.md)
- [直接依赖矩阵](docs/architecture/DEPENDENCY_MATRIX.md)
- [5.x 到 6.0 迁移](docs/migration/MIGRATION_6.md)
- [测试矩阵](docs/maintainers/TEST_MATRIX.md)
- [发布流程](docs/maintainers/RELEASE.md)
- [质量与验收](docs/maintainers/QUALITY.md)
- [路线图](ROADMAP.md)
- [变更记录](CHANGELOG.md)

## Privacy and Permissions

使用相机、相册、麦克风、定位、联系人、蓝牙、健康数据或其他系统能力时，请在宿主 App 的
Info.plist 配置对应的隐私权限说明。压缩/解压相关能力按项目需要链接 `libz.tbd`。

## License

PooTools 使用 MIT License，详见 [LICENSE](LICENSE)。
