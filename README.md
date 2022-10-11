# PooTools

<p align="center">
<!--<a href=""><img src="https://img.shields.io/cocoapods/v/PooTools.svg"></a>-->
<a href=""><img src="https://img.shields.io/cocoapods/p/PooTools.svg"></a>
<a href=""><img src="https://img.shields.io/badge/platform-iOS%2010.0%2B-ff69b5152950834.svg"></a>
</p>
<p align="center">
<a href="https://twitter.com/crazypeepoo"><img src="https://img.shields.io/twitter/url/http/shields.io.svg?style=social&maxAge=2592000"></a>
<a href="https://weibo.com/273277355"><img src="https://img.shields.io/badge/weibo-@雀屎桑-red.svg?style=plastic"></a>
</p>

## About

PooTools是一款积累了好多比较适合本人开发的工具类,工具大部分工具都是高度自定义,也有可能适合到一些有需要的人.有些工具是修改于一些老前辈不再维护的代码,或者有些代码年份可能跨度有点大作者忘记了(估计也是12年到现在的代码).如有侵犯,请issue.希望大家喜欢

## About iOS Kit
本工具运用到以下系统工具框架:</br>
'AVFoundation'</br>
'CoreImage'</br>
'CoreMotion'</br>
'CoreTelephony'</br>
'CoreText'</br>
'ExternalAccessory'</br>
'Foundation'</br>
'HealthKit'</br>
'LocalAuthentication'</br>
'Photos'</br>
'QuartzCore'</br>
'Security'</br>
'SceneKit'</br>
'Speech'</br>
'SystemConfiguration'</br>
'UIKit'</br>
'WebKit'</br>

## Assist

推荐以下辅助第三方工具:</br>
'AFNetworking':https://github.com/AFNetworking/AFNetworking</br>
'CYLTabBarController':https://github.com/ChenYilong/CYLTabBarController</br>
'FDFullscreenPopGesture':https://github.com/forkingdog/FDFullscreenPopGesture</br>
'GCDWebServer':https://github.com/swisspol/GCDWebServer</br>
'IQKeyboardManager':https://github.com/hackiftekhar/IQKeyboardManager</br>
'Masonry':https://github.com/SnapKit/Masonry</br>
'MJExtension':https://github.com/CoderMJLee/MJExtension</br>
'MJRefresh':https://github.com/CoderMJLee/MJRefresh</br>
'pop':https://github.com/facebook/pop</br>
'SDWebImage':https://github.com/rs/SDWebImage</br>
'TextFieldEffects':https://github.com/raulriera/TextFieldEffects</br>
'UITextField+Shake':https://github.com/andreamazz/UITextField-Shake</br>
'UIViewController+Swizzled':https://github.com/RuiAAPeres/UIViewController-Swizzled</br>
'ZipArchive':https://github.com/ZipArchive/ZipArchive</br>
'CocoaLumberjack/Swift':https://github.com/CocoaLumberjack/CocoaLumberjack</br>
'SPPermissions':https://github.com/ivanvorobei/SPPermissions</br>
'SkeletonView':https://github.com/Juanpe/SkeletonView</br>
'FaceAware':https://github.com/BeauNouvelle/FaceAware</br>
'CDDGroupAvatarSwift':https://github.com/RocketsChen/CDDGroupAvatarSwift</br>
'SwipeCellKit':https://github.com/SwipeCellKit/SwipeCellKit</br>
'JXPagingView/Paging':https://github.com/pujiaxin33/JXPagingView</br>
'JXSegmentedView':https://github.com/pujiaxin33/JXSegmentedView</br>
'NotificationBannerSwift':https://github.com/maheshbutani/NotificationBannerSwift-customizable-in-app-notification-</br>
'FloatingPanel':https://github.com/scenee/FloatingPanel</br>
'SnapshotKit':https://github.com/YK-Unit/SnapshotKit</br>
'Aspects':https://github.com/steipete/Aspects</br>
'FluentDarkModeKit':https://github.com/microsoft/FluentDarkModeKit</br>
'DeviceKit':https://github.com/devicekit/DeviceKit</br>
'SwiftDate':https://github.com/malcommac/SwiftDate</br>
'YCSymbolTracker':https://github.com/ryan7cruise/YCSymbolTracker</br>
'UIColor_Hex_Swift':https://github.com/yeahdongcn/UIColor-Hex-Swift</br>
## Requirements

## Attention

本工具使用了HealthKit之类的框架,审核时可能要集成,如果没需要,可以移除这些框架,使用压缩解压第三方库时,要添加libz.tbd

## Installation

默认

```ruby
pod 'PooTools/Core', :git => 'https://github.com/crazypoo/PTools.git'
```

其他根据自己个人喜好加载

```ruby
pod 'PooTools/Core', :git => 'https://github.com/crazypoo/PTools.git'
pod 'PooTools/DataEncrypt', :git => 'https://github.com/crazypoo/PTools.git'
pod 'PooTools/Animation', :git => 'https://github.com/crazypoo/PTools.git'
pod 'PooTools/YB_Attributed', :git => 'https://github.com/crazypoo/PTools.git'
pod 'PooTools/BankCard', :git => 'https://github.com/crazypoo/PTools.git'
pod 'PooTools/BilogyID', :git => 'https://github.com/crazypoo/PTools.git'
pod 'PooTools/Calendar', :git => 'https://github.com/crazypoo/PTools.git'
pod 'PooTools/Telephony', :git => 'https://github.com/crazypoo/PTools.git'
pod 'PooTools/CheckBox', :git => 'https://github.com/crazypoo/PTools.git'
pod 'PooTools/CheckDirtyWord', :git => 'https://github.com/crazypoo/PTools.git'
pod 'PooTools/CodeView', :git => 'https://github.com/crazypoo/PTools.git'
pod 'PooTools/Country', :git => 'https://github.com/crazypoo/PTools.git'
pod 'PooTools/DarkModeSetting', :git => 'https://github.com/crazypoo/PTools.git'
pod 'PooTools/Guide', :git => 'https://github.com/crazypoo/PTools.git'
pod 'PooTools/Input', :git => 'https://github.com/crazypoo/PTools.git'
pod 'PooTools/CustomerNumberKeyboard', :git => 'https://github.com/crazypoo/PTools.git'
pod 'PooTools/KeyChain', :git => 'https://github.com/crazypoo/PTools.git'
pod 'PooTools/CustomerLabel', :git => 'https://github.com/crazypoo/PTools.git'
pod 'PooTools/LanguageSetting', :git => 'https://github.com/crazypoo/PTools.git'
pod 'PooTools/Line', :git => 'https://github.com/crazypoo/PTools.git'
pod 'PooTools/Loading', :git => 'https://github.com/crazypoo/PTools.git'
pod 'PooTools/MediaViewer', :git => 'https://github.com/crazypoo/PTools.git'
pod 'PooTools/Motion', :git => 'https://github.com/crazypoo/PTools.git'
pod 'PooTools/PhoneInfo', :git => 'https://github.com/crazypoo/PTools.git'
pod 'PooTools/RateView', :git => 'https://github.com/crazypoo/PTools.git'
pod 'PooTools/Rotation', :git => 'https://github.com/crazypoo/PTools.git'
pod 'PooTools/ScrollBanner', :git => 'https://github.com/crazypoo/PTools.git'
pod 'PooTools/SearchBar', :git => 'https://github.com/crazypoo/PTools.git'
pod 'PooTools/Segmented', :git => 'https://github.com/crazypoo/PTools.git'
pod 'PooTools/Slider', :git => 'https://github.com/crazypoo/PTools.git'
pod 'PooTools/Thermometer', :git => 'https://github.com/crazypoo/PTools.git'
pod 'PooTools/NetWork', :git => 'https://github.com/crazypoo/PTools.git'
pod 'PooTools/CheckUpdate', :git => 'https://github.com/crazypoo/PTools.git'
pod 'PooTools/Layout', :git => 'https://github.com/crazypoo/PTools.git'
pod 'PooTools/Tabbar', :git => 'https://github.com/crazypoo/PTools.git'
pod 'PooTools/SmartScreenshot', :git => 'https://github.com/crazypoo/PTools.git'
pod 'PooTools/ZipArchive', :git => 'https://github.com/crazypoo/PTools.git'
pod 'PooTools/GCDWebServer', :git => 'https://github.com/crazypoo/PTools.git'
pod 'PooTools/ColorPicker', :git => 'https://github.com/crazypoo/PTools.git'
pod 'PooTools/ImageColors', :git => 'https://github.com/crazypoo/PTools.git'
pod 'PooTools/FocusFaceImageView', :git => 'https://github.com/crazypoo/PTools.git'
pod 'PooTools/SwipeCell', :git => 'https://github.com/crazypoo/PTools.git'
pod 'PooTools/PagingControl', :git => 'https://github.com/crazypoo/PTools.git'
pod 'PooTools/ImagePicker', :git => 'https://github.com/crazypoo/PTools.git'
pod 'PooTools/Picker', :git => 'https://github.com/crazypoo/PTools.git'
pod 'PooTools/Instructions', :git => 'https://github.com/crazypoo/PTools.git'
pod 'PooTools/Appz', :git => 'https://github.com/crazypoo/PTools.git'
pod 'PooTools/LaunchTimeProfiler', :git => 'https://github.com/crazypoo/PTools.git'
```
## Author

crazypoo, 273277355@qq.com

## License

PooTools is available under the MIT license. See the LICENSE file for more info.
