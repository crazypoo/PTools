# PooTools

<p align="center">
<a href=""><img src="https://img.shields.io/cocoapods/p/PooTools.svg"></a>
<a href=""><img src="https://img.shields.io/badge/platform-iOS%2017.0%2B-ff69b5152950834.svg"></a>
</p>

## About

PooTools 是面向 iOS 应用的 UIKit、Foundation、媒体、网络、权限和调试工具库。Core 是默认
基础边界，其他功能按需安装。

PTools 支持中文、粤语、英文和西班牙语资源。当前开发代码基线为 iOS 17+ / Swift 6+，版本事实
以 `VERSION`、`PooTools.podspec` 和正式 Git tag 为准；当前开发基线为 `5.67.0`，真机/宿主回归与发布证据完成前不创建正式 tag。

`5.67.0` 新增独立 `PToolsConstraintLayout` 原生布局产品。它只依赖 UIKit/Foundation，提供结构化诊断、原子事务、更新/重建/移除、组约束、Safe Area、键盘和 RTL 支持；旧 `.snp` 入口保持兼容。接入与迁移请参阅 [PTLayout 5.67 兼容指南](docs/guides/PTLAYOUT_567_COMPATIBILITY.md) 和 [迁移清单](docs/guides/PTLAYOUT_MIGRATION_CHECKLIST.md)。

`5.66.1` 修复 `PTSearchViewController` 清空输入框后列表被错误清空的问题；点击 clear button 会恢复调用方提供的完整未筛选数据，并保留搜索过程中的结果状态隔离。

5.66.0 新增离线开源许可证能力：只需要 Foundation 的 `PToolsAcknowledgementsCore` 可提供清单查询、统计和导出；需要 UIKit 页面时使用 `PToolsAcknowledgements`。UIKit 适配层可用时，`PTAcknowledgementsViewController` 和 `PTAcknowledgementDetailViewController` 都优先继承 `PTBaseViewController`，复用 PTools 的导航与生命周期逻辑。构建期生成和接入方式见 [PTAcknowledgements 指南](docs/guides/PTACKNOWLEDGEMENTS_GUIDE.md)。

```sh
bash Scripts/pt_acknowledgements_build.sh
bash Scripts/validate_acknowledgements.sh .build/acknowledgements/PTAcknowledgements.json
```

`5.65.8` 将已有的 `PToolsNetworkModelCore` 与 `PToolsFontCatalogCore` target 正式发布为独立 SwiftPM product，调用方可以分别使用类型化网络响应契约和 Foundation-only 字体目录，不必依赖完整 `ptools` 聚合入口。

`5.65.7` 修复 SwiftPM 独立消费者的 BioID → KeyChain 和 ScrollBanner/Guide/MediaViewer → PageControl 依赖边界；新增覆盖全部 library products 的 iOS Xcode consumer host、Debug/Release 矩阵、诊断合并和发布门禁。BaboBuy/YD1688 属于外部宿主，必须在真实项目中完成最终回归。

`5.65.6` 修复 MediaViewer、ScrollBanner 跨 SwiftPM target 访问 Core 内部视频扩展名集合的问题，统一使用公开的 `URL.pt_isVideoResource` 入口；并将该入口纳入全模块符号审计。

`5.65.5` 修复 `PooToolsInput` 的 `YoshikoTextField` 富文本导入，并将 MediaViewer、ScrollBanner、WhatsNewsKit 的 `PToolsUIFoundation` 直接依赖纳入 SwiftPM target 声明；全模块跨 target 符号审计保持通过。

`5.65.4` 全量收口 SwiftPM 独立 target 的导入和直接依赖边界，覆盖 SmartScreenshot、ProgressBar 以及 C7Collector、Hud、Network、Paging、SplitView、Debug、权限等可选模块；同时新增跨 target 符号归属门禁，避免 CocoaPods 聚合模块掩盖独立编译错误。

`5.65.3` 修复 WhatsNewsKit 跨 target 访问内部 `HSL` 类型的问题，改用 Core 公开颜色 API。

`5.65.2` 修复 Banner、WhatsNewsKit 和 Vision 的 SwiftPM 独立 target 依赖与导入边界；CocoaPods 聚合模块不再掩盖这些缺失声明。

`5.65.1` 修复骨架显示时真实 Cell 文案透出的问题，并让 `shimmer-avatar` 的头像占位保持为圆形；骨架隐藏后会恢复调用方原先设置的列表透明度。

`5.65.0` 为 `PTCollectionView` 提供了独立骨架覆盖层。骨架不会修改 Diffable 数据或触发业务 Cell 回调，旧入口仍可直接使用；需要自定义布局、内容和动画时，参见 [PTCollectionView Skeleton 指南](docs/guides/PTCOLLECTIONVIEW_SKELETON_GUIDE.md)。

5.64.10 为所有 `TextFieldEffects` 样式提供统一的输入活动状态回调：`activityChangeHandler` 会在获得焦点、失去焦点、文本变化或程序化赋值导致状态改变时通知外部调用方，`isActive` 可随时读取当前状态。详见 [Input 输入框指南](docs/guides/PTINPUT_TEXTFIELD_EFFECTS.md)。

5.64.9 修复 `YoshikoTextField` 的边框颜色与占位符配置耦合问题：`activeBorderColor` 只控制激活边框，默认沿用共享占位符配置，需要时可单独设置 `activePlaceholderColor`、`activePlaceholderFont` 和 `activePlaceholderAtt`；悬浮状态会按占位符实际高度动态预留输入区域。

5.64.8 起默认 `Core` / `Device` 不链接 CoreNFC；未使用 NFC 的 App 不会因设备能力检测被动携带 NFC 框架。需要 NFC 时请显式选择 `PooTools/NFCKit`，并由宿主配置对应的使用说明和 entitlement；否则不要添加 NFC 使用说明或能力声明，并在 App Review Notes 中说明未使用 NFC。

5.64.6 统一了 Input TextFieldEffects / `PTHoshiTextField` 的占位符、富文本和间距配置，并补齐 Input 的 SwiftPM / CocoaPods 直接依赖。图片加载现在按窗口屏幕比例统一点尺寸与像素尺寸，图片视图和按钮会先显示占位图，待布局稳定后再进行高分辨率解码。详见 [Input 输入框指南](docs/guides/PTINPUT_TEXTFIELD_EFFECTS.md) 与 [高分辨率图片加载指南](docs/guides/PTIMAGE_HIRES_LOADING.md)。

5.64.5 完成 SwiftPM 全仓跨 target 兼容性治理：补齐跨模块源码的直接 import 和 target 依赖，Banner 的轻量清理逻辑改用 UIKit 原生 API，并新增 target、符号、条件编译、资源和消费者矩阵报告。SwiftPM 使用说明见 [SwiftPM Product / Module 矩阵](docs/guides/SPM_PRODUCT_MODULE_IMPORT_MATRIX.md)。

5.64.4 修复 SwiftPM 与 CocoaPods 独立 Target 对聚合模块符号的隐式依赖：调试诊断显式导入 UIKit，Input、Stepper、Router、SocketKit、Share、DEBUG 和权限相关入口的模块依赖保持显式且一致。

5.64.1 为 `PTRichText` 的 `.image`、远程图片和动态图片附件增加 `baselineOffset`。例如：

```swift
let richText: PTRichText = "图片 \(.image(image, .custom(size: CGSize(width: 24, height: 24)), baselineOffset: -2))"
let configuration = PTRichTextImageConfiguration(size: CGSize(width: 24, height: 24), baselineOffset: 2)
let remoteText = PTRichText.image(source: imageURL, configuration: configuration)
```

5.64.0 将 `PTCustomerAlertController` 的操作按钮统一为 iOS 17+ 可用的胶囊布局：支持长文案、多按钮滚动、主/取消操作排序、Dynamic Type、Reduce Transparency 和 iOS 26 原生 Glass 回退。使用方式见 [PTCustomerAlertController 胶囊操作指南](docs/guides/PTCUSTOMER_ALERT_CAPSULE_ACTIONS.md)。

5.63.6 修复 `PTNavBar` 作为普通 View 使用时的自定义按钮布局：按钮尺寸会在重新挂载前从 `bounds` 快照，伪导航栏使用宿主的实际高度，并与系统导航栏复用同一套按钮布局逻辑。

5.63.5 为 TabBar 选中背景增加独立样式覆盖。旧配置保持原有材质继承行为；需要普通颜色时，可以这样配置：

```swift
let layout = PTTabBarLayoutAppearance(
    tabSelectedMetail: true,
    tabSelectedMetailColor: .systemBlue,
    tabSelectedMetailStyle: .classic
)
let appearance = PTTabBarAppearance(layout: layout)
```

`tabSelectedMetailStyle` 使用 `nil` 时继续继承 TabBar 的整体样式；`.classic` 为纯色，`.material` 和 `.glass` 分别使用系统材质或玻璃效果。

5.63.4 修复 `pt_loadCoreImage` 在异步加载开始前未显示 `emptyImage` 的问题，避免图片视图在请求期间继续展示旧内容。

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

5.63.3 修复 Header / Cell 重复间距，补充 Section 外边距、Header spacing、嵌套 Grid 宽度和
真实 layout attributes 测量方式，详见 [PTCollectionView Header / Cell 间距指南](docs/guides/PTCOLLECTIONVIEW_HEADER_CELL_SPACING.md)。

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

内嵌图片需要参与多行布局时，直接使用 `UILabel.pt_apply(richText:)` 即可；渲染器会在 UIKit 显示副本上
安全处理附件的 `baselineOffset`，不会强制修改调用方的 `numberOfLines` 或 `lineBreakMode`。可在 Example
中打开 `Rich Text · Attachment Multiline Regression` 验证 24×24 图片、不同高度和换行 Action。
详见 [PTRichText 多行附件布局指南](docs/guides/PTRICHTEXT_MULTILINE_ATTACHMENTS.md)。

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
