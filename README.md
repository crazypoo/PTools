# PooTools

<p align="center">
<a href=""><img src="https://img.shields.io/cocoapods/v/PooTools.svg"></a>
<a href=""><img src="https://img.shields.io/cocoapods/p/PooTools.svg"></a>
<a href=""><img src="https://img.shields.io/badge/platform-iOS%208.0%2B-ff69b5152950834.svg"></a>
<a href="https://github.com/ChenYilong/CYLTabBarController/blob/master/LICENSE"><img src="https://img.shields.io/github/license/mashape/apistatus.svg"></a>
</p>
<p align="center">
<a href="https://twitter.com/crazypeepoo"><img src="https://img.shields.io/twitter/url/http/shields.io.svg?style=social&maxAge=2592000"></a>
<a href="http://weibo.com/273277355"><img src="https://shutterstock.7eer.net/c/2204609/560528/1305?u=https%3A%2F%2Fwww.shutterstock.com%2Fimage-photo%2F1341179450"></a>
</p>

## About

PooTools是一款积累了好多比较适合本人开发的工具类,现在已经慢慢转向swift开发,工具大部分工具都是高度自定义,也有可能适合到一些有需要的人.有些工具是修改于一些老前辈不再维护的代码,或者有些代码年份可能跨度有点大作者忘记了(估计也是12年到现在的代码).如有侵犯,请issue.希望大家喜欢

## About iOS Kit
本工具运用到以下系统工具框架:</br>
'AssetsLibrary'</br>
'AudioToolbox'</br>
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

本工具集成了以下辅助第三方工具:</br>
'AFNetworking':https://github.com/AFNetworking/AFNetworking</br>
'CYLTabBarController':https://github.com/ChenYilong/CYLTabBarController</br>
'DHSmartScreenshot':https://github.com/davidman/DHSmartScreenshot</br>
'DZNEmptyDataSet':https://github.com/dzenbot/DZNEmptyDataSet</br>
'FDFullscreenPopGesture':https://github.com/forkingdog/FDFullscreenPopGesture</br>
'FMDB':https://github.com/ccgus/fmdb</br>
'GCDWebServer':https://github.com/swisspol/GCDWebServer</br>
'HTAutocompleteTextField':https://github.com/hoteltonight/HTAutocompleteTextField</br>
'IQKeyboardManager':https://github.com/hackiftekhar/IQKeyboardManager</br>
'JMHoledView':https://github.com/leverdeterre/JMHoledView</br>
'LTNavigationBar':https://github.com/ltebean/LTNavigationBar</br>
'Mantle':https://github.com/Mantle/Mantle</br>
'Masonry':https://github.com/SnapKit/Masonry</br>
'MJExtension':https://github.com/CoderMJLee/MJExtension</br>
'MJRefresh':https://github.com/CoderMJLee/MJRefresh</br>
'MYBlurIntroductionView':https://github.com/MatthewYork/MYBlurIntroductionView</br>
'pop':https://github.com/facebook/pop</br>
'SDWebImage':https://github.com/rs/SDWebImage</br>
'TextFieldEffects':https://github.com/raulriera/TextFieldEffects</br>
'UITextField+Shake':https://github.com/andreamazz/UITextField-Shake</br>
'UINavigation-SXFixSpace':https://github.com/spicyShrimp/UINavigation-SXFixSpace</br>
'UITableView+FDTemplateLayoutCell':https://github.com/forkingdog/UITableView-FDTemplateLayoutCell</br>
'UIViewController+Swizzled':https://github.com/RuiAAPeres/UIViewController-Swizzled</br>
'YCXMenu':https://github.com/Aster0id/YCXMenuDemo_ObjC</br>
'ZipArchive':https://github.com/ZipArchive/ZipArchive</br>
'CocoaLumberjack/Swift':https://github.com/ryan7cruise/YCSymbolTracker</br>
'SPPermissions':
'SkeletonView':
'FaceAware':
'CDDGroupAvatar':
'SwipeCellKit':
'JXPagingView/Paging':
'JXSegmentedView':
'NotificationBannerSwift':
'FloatingPanel':
'SnapshotKit':
'Aspects':
'FluentDarkModeKit':
'DeviceKit':
'SwiftDate':
'YCSymbolTracker':https://github.com/ryan7cruise/YCSymbolTracker</br>
## Requirements

使用工具时，一定要在Build Settings->other links flags加入-ObjC和-all_load,以防避免一些奇奇怪怪的问题发生.

## Attention

本工具使用了HealthKit之类的框架,审核时可能要集成,如果没需要,可以移除这些框架,使用压缩解压第三方库时,要添加libz.tbd

## Installation

PooTools is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'PooTools'
pod 'PooTools', :git => 'https://github.com/crazypoo/PTools.git'
```

## Author

crazypoo, 273277355@qq.com

## License

PooTools is available under the MIT license. See the LICENSE file for more info.
