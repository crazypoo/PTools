# PooTools

<p align="center">
<a href=""><img src="https://img.shields.io/cocoapods/p/PooTools.svg"></a>
<a href=""><img src="https://img.shields.io/badge/platform-iOS%2017.0%2B-ff69b5152950834.svg"></a>
</p>

## About

PooTools 是面向 iOS 应用的 UIKit、Foundation、媒体、网络、权限和调试工具库。Core 是默认
基础边界，其他功能按需安装。

PTools 支持中文、粤语、英文和西班牙语资源。当前开发代码基线为 iOS 17+ / Swift 6+，版本事实
以 `PooTools.podspec` 和正式 Git tag 为准；当前开发基线为 `5.18.0`。

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

### CocoaPods

```ruby
pod 'PooTools/Core'
pod 'PooTools/NetWork'
pod 'PooTools/PhotoPicker'
```

按功能选择最小 subspec；需要完整示例时才考虑 `PooToolsAll`。

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
布局类型继续提供 Grid、Waterfall、Tag、Horizontal 和 Custom。

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

### 图片和媒体

图片加载优先使用 `PTLoadImageFunction.loadImage(source:)`，大图按 `targetSize` 通过
`PTImageDownsampler` 解码；视频缩略图使用 `PTVideoThumbnailService` 和变体缓存；保存图片或视频使用
`PTMediaSaveService`。旧入口仍兼容，迁移条件见
[MIGRATION_6.md](docs/migration/MIGRATION_6.md)。

### Picker

- 单图片、单视频和相机：`PooToolsImagePicker` / `PooTools/ImagePicker`。
- 多选、原图、Live Photo、自定义 PhotoKit 浏览：`PooToolsPhotoPicker` / `PooTools/PhotoPicker`。
- 需要把滚轮选择器放入已有页面时，先 `configure(...)`，再添加到宿主 View；覆盖层展示才调用 `show()`。

### Network

新代码使用 `PTNetworkRequest` 与 `PTNetworkExecutor`，普通参数、Body、上传、下载、取消、缓存、
重试、去重和认证刷新统一由 Network 请求管线处理。动态 `Any` 与 KakaJSON 入口仅作为兼容层保留。

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
- [Debug 与 PTInstruments](docs/architecture/DEBUG_AND_INSTRUMENTS.md)
- [依赖与模块边界](docs/architecture/DEPENDENCIES.md)
- [5.x 到 6.0 迁移](docs/migration/MIGRATION_6.md)
- [发布流程](docs/maintainers/RELEASE.md)
- [质量与验收](docs/maintainers/QUALITY.md)
- [路线图](ROADMAP.md)
- [变更记录](CHANGELOG.md)

## Privacy and Permissions

使用相机、相册、麦克风、定位、联系人、蓝牙、健康数据或其他系统能力时，请在宿主 App 的
Info.plist 配置对应的隐私权限说明。压缩/解压相关能力按项目需要链接 `libz.tbd`。

## License

PooTools 使用 MIT License，详见 [LICENSE](LICENSE)。
