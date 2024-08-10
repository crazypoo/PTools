# PooTools

<p align="center">
<!--<a href=""><img src="https://img.shields.io/cocoapods/v/PooTools.svg"></a>-->
<a href=""><img src="https://img.shields.io/cocoapods/p/PooTools.svg"></a>
<a href=""><img src="https://img.shields.io/badge/platform-iOS%2013.0%2B-ff69b5152950834.svg"></a>
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

默认

```ruby
pod 'PooTools/Core', :git => 'https://github.com/crazypoo/PTools.git'
```

其他根据自己个人喜好加载

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
### 语言设置
pod 'PooTools/LanguageSetting', :git => 'https://github.com/crazypoo/PTools.git'
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
### 颜色选择
pod 'PooTools/ColorPicker', :git => 'https://github.com/crazypoo/PTools.git'
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
```
## Author

crazypoo, 273277355@qq.com

## License

PooTools is available under the MIT license. See the LICENSE file for more info.
