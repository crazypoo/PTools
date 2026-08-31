# PooTools

<p align="center">
<!--<a href=""><img src="https://img.shields.io/cocoapods/v/PooTools.svg"></a>-->
<a href=""><img src="https://img.shields.io/cocoapods/p/PooTools.svg"></a>
<a href=""><img src="https://img.shields.io/badge/platform-iOS%2017.0%2B-ff69b5152950834.svg"></a>
</p>
<p align="center">
<a href="https://twitter.com/crazypeepoo"><img src="https://img.shields.io/twitter/url/http/shields.io.svg?style=social&maxAge=2592000"></a>
<a href="https://weibo.com/273277355"><img src="https://img.shields.io/badge/weibo-@雀屎桑-red.svg?style=plastic"></a>
</p>

## About

该框架集成了一个APP该有的开发框架,工具大部分工具都是高度自定义,一直在自嗨

## Languages
🇨🇳 Chinese, 🇭🇰/🇲🇴 Cantonese, 🇺🇸 English, 🇪🇸 Spanish.

## Attention

如果全部导入本工具须要注意APP隐私权限配置,使用压缩解压第三方库时,要添加libz.tbd

## Installation

PTools 当前支持 iOS 17.0+ 和 Swift 6.0。按需选择模块，避免无关功能进入宿主 App。

### Swift Package Manager

在 Xcode 中添加：

```text
https://github.com/crazypoo/PTools.git
```

常用产品：`ptools`、`PooToolsNetWork`、`PooToolsPhotoPicker`、
`PooToolsVideoEditor`、`PooToolsMediaViewer`、`PooToolsRouter`。

### CocoaPods

```ruby
pod 'PooTools/Core', :git => 'https://github.com/crazypoo/PTools.git', :tag => '5.6.3'
pod 'PooTools/NetWork', :git => 'https://github.com/crazypoo/PTools.git', :tag => '5.6.3'
pod 'PooTools/PhotoPicker', :git => 'https://github.com/crazypoo/PTools.git', :tag => '5.6.3'
```

### Swift 6 迁移要点

- UI 配置、空状态和媒体保存回调在 `MainActor` 上执行。
- ScrollBanner 新代码使用 `PTBannerView`；`PTCycleScrollView` 仍可使用，但已作为 deprecated
  兼容入口转发到统一实现。
- PageControl 的系统和自定义样式继续保留，进度更新、无障碍和 Reduce Motion 由统一基类处理。
- 图片请求统一使用 `PTMediaLibManager.requestImage`；旧 `fetchImage` 入口继续兼容。
- 媒体保存优先使用 `PTMediaSaveService.save(image:videoURL:completion:)`；旧保存入口保留并逐步弃用。
- Network 普通请求和 Body 请求共用取消、缓存、去重和错误处理管线。

完整发布和迁移清单见 [RELEASE.md](RELEASE.md)，5.x Core 治理进度见
[ROADMAP_5X.md](ROADMAP_5X.md)，5.x 兼容入口和 6.0.0 删除条件见
[MIGRATION_5X.md](MIGRATION_5X.md)。

### Language

语言功能随 `PooTools/Core` 提供，没有独立的 `LanguageSetting` subspec。语言资源
支持英文、西班牙文、简体中文、繁体中文和香港繁体中文：

```swift
PTLanguage.share.setLanguage(.zh_Hans)
let cancelTitle = "PT Button cancel".localized()
let formatted = "PT Photo picker video size less than".localizedFormat(10)
```

如果需要让界面在语言切换后刷新，可以使用 `pt_observerLanguage(didChanged:)`，页面
销毁或不再需要监听时调用 `pt_removeObserverLanguage()`。监听器现在使用独立的通知 token，
不会被宿主对象的其他 `removeObserver` 调用误删；同一有效语言重复赋值不会发送通知。旧的
`PTLanguage.share.language = "zh-Hans"` 写法继续兼容。

#### Xcode String Catalog 兼容

新项目可以在 Xcode 的 Localization 设置中使用 `Localizable.xcstrings`，不需要再手动
创建每个语言的 `.lproj` 目录。只要 String Catalog 已加入 App target 或资源 bundle 的
Target Membership，并且 Catalog 中的 key 与调用方一致，以下现有入口就可以直接使用：

```swift
PTLanguage.share.language = "es"
let title = "PT Upgrade".localized()
let customTitle = "welcome_title".localized(using: "AppLocalizable", in: .main)
```

PooTools 不会在运行时解析 `.xcstrings` 源文件，而是使用 Foundation 的
`LocalizedStringResource` 读取 Xcode 编译后的 Catalog；因此同时兼容旧的
`Localizable.strings` 和新的 String Catalog。Catalog 语言标识符建议使用 Xcode 提供的
标准语言代码，例如 `en`、`es`、`zh-Hans` 和 `zh-Hant`。

## Quality and release

项目统一要求 iOS 17.0+ 与 Swift 6.0。提交代码前运行：

```bash
bash Scripts/validate_build_entries.sh
bash Scripts/validate_release.sh
bash Scripts/validate_quality_scans.sh
git diff --check
```

版本发布流程、版本号同步范围和发布前检查见 [RELEASE.md](RELEASE.md)。5.x Core
的阶段任务和完成状态见 [ROADMAP_5X.md](ROADMAP_5X.md)，重复入口报告见
`Scripts/report_duplicate_entries.sh`。

其他模块根据项目需要选择：

```ruby
### 数据加密
pod 'PooTools/DataEncrypt', :git => 'https://github.com/crazypoo/PTools.git'
### 银行卡
pod 'PooTools/BankCard', :git => 'https://github.com/crazypoo/PTools.git'
### 生物验证(Face ID/Touch ID)
pod 'PooTools/BilogyID', :git => 'https://github.com/crazypoo/PTools.git'
### 日历
pod 'PooTools/Calendar', :git => 'https://github.com/crazypoo/PTools.git'
### 电话
pod 'PooTools/Telephony', :git => 'https://github.com/crazypoo/PTools.git'
### 勾选框
pod 'PooTools/CheckBox', :git => 'https://github.com/crazypoo/PTools.git'
### 检查是否包含敏感词
pod 'PooTools/CheckDirtyWord', :git => 'https://github.com/crazypoo/PTools.git'
### 验证码
pod 'PooTools/CodeView', :git => 'https://github.com/crazypoo/PTools.git'
### 国家代号
pod 'PooTools/Country', :git => 'https://github.com/crazypoo/PTools.git'
### 引导模式
pod 'PooTools/Guide', :git => 'https://github.com/crazypoo/PTools.git'
### 文字输入
pod 'PooTools/Input', :git => 'https://github.com/crazypoo/PTools.git'
### 数字键盘
pod 'PooTools/CustomerNumberKeyboard', :git => 'https://github.com/crazypoo/PTools.git'
### KeyChain
pod 'PooTools/KeyChain', :git => 'https://github.com/crazypoo/PTools.git'
### Label
pod 'PooTools/CustomerLabel', :git => 'https://github.com/crazypoo/PTools.git'
### 语言设置（已包含在 Core）
pod 'PooTools/Core', :git => 'https://github.com/crazypoo/PTools.git'
### 线
pod 'PooTools/Line', :git => 'https://github.com/crazypoo/PTools.git'
### 加载功能
pod 'PooTools/Loading', :git => 'https://github.com/crazypoo/PTools.git'
### 媒体浏览
pod 'PooTools/MediaViewer', :git => 'https://github.com/crazypoo/PTools.git'
### Motion
pod 'PooTools/Motion', :git => 'https://github.com/crazypoo/PTools.git'
### 电话信息
pod 'PooTools/PhoneInfo', :git => 'https://github.com/crazypoo/PTools.git'
### 评分
pod 'PooTools/RateView', :git => 'https://github.com/crazypoo/PTools.git'
### 屏幕旋转
pod 'PooTools/Rotation', :git => 'https://github.com/crazypoo/PTools.git'
### PageControl
pod 'PooTools/PageControl', :git => 'https://github.com/crazypoo/PTools.git'
### Banner
pod 'PooTools/ScrollBanner', :git => 'https://github.com/crazypoo/PTools.git'
### SearchBar
pod 'PooTools/SearchBar', :git => 'https://github.com/crazypoo/PTools.git'
### Semgented
pod 'PooTools/Segmented', :git => 'https://github.com/crazypoo/PTools.git'
### Slider
pod 'PooTools/Slider', :git => 'https://github.com/crazypoo/PTools.git'
### 网络层
pod 'PooTools/NetWork', :git => 'https://github.com/crazypoo/PTools.git'
### 检测更新
pod 'PooTools/CheckUpdate', :git => 'https://github.com/crazypoo/PTools.git'
### CollectionView Layout
pod 'PooTools/Layout', :git => 'https://github.com/crazypoo/PTools.git'
### Tabbar
pod 'PooTools/Tabbar', :git => 'https://github.com/crazypoo/PTools.git'
### 屏幕截图
pod 'PooTools/SmartScreenshot', :git => 'https://github.com/crazypoo/PTools.git'
### 解压
pod 'PooTools/ZipArchive', :git => 'https://github.com/crazypoo/PTools.git'
### GCDWebServer
pod 'PooTools/GCDWebServer', :git => 'https://github.com/crazypoo/PTools.git'
### 图片颜色
pod 'PooTools/ImageColors', :git => 'https://github.com/crazypoo/PTools.git'
### 头像头部居中
pod 'PooTools/FocusFaceImageView', :git => 'https://github.com/crazypoo/PTools.git'
### CollectionView/TableView Swipe
pod 'PooTools/SwipeCell', :git => 'https://github.com/crazypoo/PTools.git'
### PagingControl
pod 'PooTools/PagingControl', :git => 'https://github.com/crazypoo/PTools.git'
### 图片选择器
pod 'PooTools/PhotoPicker', :git => 'https://github.com/crazypoo/PTools.git'
### Picker
pod 'PooTools/Picker', :git => 'https://github.com/crazypoo/PTools.git'
### 功能介绍
pod 'PooTools/Instructions', :git => 'https://github.com/crazypoo/PTools.git'
### App的Secheme
pod 'PooTools/Appz', :git => 'https://github.com/crazypoo/PTools.git'
### App启动时间检测
pod 'PooTools/LaunchTimeProfiler', :git => 'https://github.com/crazypoo/PTools.git'
### 语音识别
pod 'PooTools/Speech', :git => 'https://github.com/crazypoo/PTools.git'
### HealthKit
pod 'PooTools/HealthKit', :git => 'https://github.com/crazypoo/PTools.git'
### 颜色控件
pod 'PooTools/ColorFunction', :git => 'https://github.com/crazypoo/PTools.git'
### 弹出框控件
pod 'PooTools/PopoverKit', :git => 'https://github.com/crazypoo/PTools.git'
### 扫描二维码/条形码控件
pod 'PooTools/ScanQRCode', :git => 'https://github.com/crazypoo/PTools.git'
### Stepper控件
pod 'PooTools/Stepper', :git => 'https://github.com/crazypoo/PTools.git'
### Location相關
pod 'PooTools/Location', :git => 'https://github.com/crazypoo/PTools.git'
### Permission相关
pod 'PooTools/NotificationPermission', :git => 'https://github.com/crazypoo/PTools.git'
pod 'PooTools/CameraPermission', :git => 'https://github.com/crazypoo/PTools.git'
pod 'PooTools/LocationPermission', :git => 'https://github.com/crazypoo/PTools.git'
pod 'PooTools/CalendarPermission', :git => 'https://github.com/crazypoo/PTools.git'
pod 'PooTools/MotionPermission', :git => 'https://github.com/crazypoo/PTools.git'
pod 'PooTools/TrackingPermission', :git => 'https://github.com/crazypoo/PTools.git'
pod 'PooTools/RemindersPermission', :git => 'https://github.com/crazypoo/PTools.git'
pod 'PooTools/SpeechRecognizerPermission', :git => 'https://github.com/crazypoo/PTools.git'
pod 'PooTools/HealthPermission', :git => 'https://github.com/crazypoo/PTools.git'
pod 'PooTools/FaceIDPermission', :git => 'https://github.com/crazypoo/PTools.git'
pod 'PooTools/ContactsPermission', :git => 'https://github.com/crazypoo/PTools.git'
pod 'PooTools/MicPermission', :git => 'https://github.com/crazypoo/PTools.git'
pod 'PooTools/MeidaPermission', :git => 'https://github.com/crazypoo/PTools.git'
pod 'PooTools/BluetoothPermission', :git => 'https://github.com/crazypoo/PTools.git'
pod 'PooTools/SiriPermission', :git => 'https://github.com/crazypoo/PTools.git'
### Harbeth照片特效
pod 'PooTools/Harbeth', :git => 'https://github.com/crazypoo/PTools.git'
### ScrollRefresh刷新
pod 'PooTools/ScrollRefresh', :git => 'https://github.com/crazypoo/PTools.git'
### SVG相关(关联了kingfisher)
pod 'PooTools/SVG', :git => 'https://github.com/crazypoo/PTools.git'
### 分享
pod 'PooTools/Share', :git => 'https://github.com/crazypoo/PTools.git'
### FloatPanel
pod 'PooTools/FloatPanel', :git => 'https://github.com/crazypoo/PTools.git'

FloatPanel 支持 intrinsic、固定高度、百分比、顶部间距和全屏尺寸。所有 UI 配置与回调都应在主线程使用：

```swift
let sheet = PTSheetViewController(
    controller: contentViewController,
    sizes: [.intrinsic, .percent(0.8), .fullscreen]
)
sheet.didDismiss = { _ in
    // 面板完成关闭后只回调一次
}
present(sheet, animated: true)
```

如果内容控制器包含 `UIScrollView`，在内容控制器中注册它，让面板在滚动到顶部时接管上下拖动：

```swift
sheetViewController?.handleScrollView(tableView)
```

`PTSheetOptions.pullDismissThreshold` 是新的正确拼写；旧的
`pullDismissThreshod` 继续保留并标记为 deprecated。键盘、旋转、动态字体和
NavigationController intrinsic 高度由 FloatPanel 自动重新计算。
### 空数据
pod 'PooTools/ListEmptyData', :git => 'https://github.com/crazypoo/PTools.git'
### DEBUG工具
pod 'PooTools/DEBUG', :git => 'https://github.com/crazypoo/PTools.git'
pod 'PooTools/DEBUG_TrackingEyes', :git => 'https://github.com/crazypoo/PTools.git'
### Vision
pod 'PooTools/Vision', :git => 'https://github.com/crazypoo/PTools.git'
### 导航栏相关
pod 'PooTools/NavBarController', :git => 'https://github.com/crazypoo/PTools.git'
### 软件内通知栏
pod 'PooTools/NotificationBanner', :git => 'https://github.com/crazypoo/PTools.git'
### Controller Router
pod 'PooTools/Router', :git => 'https://github.com/crazypoo/PTools.git'
### Ping
pod 'PooTools/Ping', :git => 'https://github.com/crazypoo/PTools.git'
### 视频编辑
pod 'PooTools/VideoEditor', :git => 'https://github.com/crazypoo/PTools.git'
### APP安全
pod 'PooTools/SecuritySuite', :git => 'https://github.com/crazypoo/PTools.git'
### SF
pod 'PooTools/SF', :git => 'https://github.com/crazypoo/PTools.git'
### iOS17Tips
pod 'PooTools/iOS17Tips', :git => 'https://github.com/crazypoo/PTools.git'
### WhatsNewsKit
pod 'PooTools/WhatsNewsKit', :git => 'https://github.com/crazypoo/PTools.git'
### FilterCamera
pod 'PooTools/FilterCamera', :git => 'https://github.com/crazypoo/PTools.git'
### ImageEditor
pod 'PooTools/ImageEditor', :git => 'https://github.com/crazypoo/PTools.git'
### Circle
pod 'PooTools/Circle', :git => 'https://github.com/crazypoo/PTools.git'
### MessageKit
pod 'PooTools/MessageKit', :git => 'https://github.com/crazypoo/PTools.git'
### IAPManager
pod 'PooTools/IAP', :git => 'https://github.com/crazypoo/PTools.git'
### LivePhoto
pod 'PooTools/LivePhoto', :git => 'https://github.com/crazypoo/PTools.git'
```
## Author

crazypoo, 273277355@qq.com

## License

PooTools is available under the MIT license. See the LICENSE file for more info.
