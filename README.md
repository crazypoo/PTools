# PooTools

<p align="center">
<a href=""><img src="https://img.shields.io/cocoapods/v/PooTools.svg"></a>
<a href=""><img src="https://img.shields.io/cocoapods/p/PooTools.svg"></a>
<a href=""><img src="https://img.shields.io/badge/platform-iOS%208.0%2B-ff69b5152950834.svg"></a>
<a href="https://github.com/ChenYilong/CYLTabBarController/blob/master/LICENSE"><img src="https://img.shields.io/github/license/mashape/apistatus.svg"></a>
</p>
<p align="center">
<a href="https://twitter.com/crazypeepoo"><img src="https://img.shields.io/twitter/url/http/shields.io.svg?style=social&maxAge=2592000"></a>
<a href="http://weibo.com/273277355"><img src="http://i67.tinypic.com/wbulbr.jpg"></a>
</p>

## About

PooTools是一款积累了好多比较适合本人开发的工具类,工具大部分工具都是高度自定义,也有可能适合到一些有需要的人.有些工具是修改于一些老前辈不再维护的代码,或者有些代码年份可能跨度有点大作者忘记了(估计也是12年到现在的代码).如有侵犯,请issue.希望大家喜欢

## Tool's Infomation

本工具内集成了:</br>
'小视频录制'</br>
```objc
PVideoViewController *videoVC = [[PVideoViewController alloc] initWithRecordTime:20 video_W_H:(4.0/3) withVideoWidthPX:200 withControViewHeight:120];
videoVC.delegate = self;
[videoVC startAnimationWithType:PVideoViewShowTypeSmall];

---Delegate
- (void)videoViewController:(PVideoViewController *)videoController
didRecordVideo:(PVideoModel *)videoModel;
- (void)videoViewControllerDidCancel:(PVideoViewController *)videoController;
```
'同意勾选框按钮'</br>
'虚线View'</br>
'温度计View'</br>
'Slider'</br>
'按钮内的文图扩展'</br>
'iPhone生物验证'</br>
```objc
PBiologyID *touchID = [PBiologyID defaultBiologyID];
touchID.biologyIDBlock = ^(BiologyIDType biologyIDType) {
PNSLog(@"%ld",(long)biologyIDType);
};
[self.touchID biologyAction];
```
'以CollectionView展示方式的广告View'</br>
```objc
CGAdBannerModel *aaaaa = [[CGAdBannerModel alloc] init];
aaaaa.bannerTitle = @"111111";

PADView *adaaaa = [[PADView alloc] initWithAdArray:@[aaaaa,aaaaa] singleADW:kSCREEN_WIDTH singleADH:150 paddingY:5 paddingX:5 placeholderImage:@"DemoImage" pageTime:1 adTitleFont:kDEFAULT_FONT(FontName, 19)];
[self.view addSubview:adaaaa];
[adaaaa mas_makeConstraints:^(MASConstraintMaker *make) {
make.left.right.equalTo(self.view);
make.top.offset(100);
make.height.offset(150);
}];
```
'CollectionViewLayout的快速初始化'</br>
```objc
+(UICollectionViewFlowLayout *)createLayoutNormalScrollDirection:(UICollectionViewScrollDirection)sd;
+(UICollectionViewFlowLayout *)createLayoutItemW:(CGFloat)w itemH:(CGFloat)h paddingY:(CGFloat)pY paddingX:(CGFloat)pX scrollDirection:(UICollectionViewScrollDirection)sd;
+(UICollectionViewFlowLayout *)createLayoutItemW:(CGFloat)w itemH:(CGFloat)h sectionInset:(UIEdgeInsets)inset minimumLineSpacing:(CGFloat)mls minimumInteritemSpacing:(CGFloat)mis scrollDirection:(UICollectionViewScrollDirection)sd;
```
'清理缓存'</br>
'AES加密'</br>
'Base64加密/RSA加密'</br>
'图片展示View'</br>
```objc
PooShowImageModel *imageModel = [[PooShowImageModel alloc] init];
imageModel.imageUrl = @"http://p3.music.126.net/VDn1p3j4g2z4p16Gux969w==/2544269907756816.jpg";
imageModel.imageShowType = PooShowImageModelTypeFullView;
imageModel.imageInfo = @"11111111241241241241928390128309128";
imageModel.imageTitle = @"22222212312312312312312312312";

PooShowImageModel *imageModelV = [[PooShowImageModel alloc] init];
imageModelV.imageUrl = @"http://clips.vorwaerts-gmbh.de/big_buck_bunny.mp4";
imageModelV.imageShowType = PooShowImageModelTypeVideo;
imageModelV.imageInfo = @"11111111241241241241928390128309128";
imageModelV.imageTitle = @"22222212312312312312312312312";

PooShowImageModel *imageModel2 = [[PooShowImageModel alloc] init];
imageModel2.imageUrl = @"http://ww4.sinaimg.cn/bmiddle/677febf5gw1erma1g5xd0j20k0esa7wj.jpg";
imageModelV.imageShowType = PooShowImageModelTypeNormal;
imageModel2.imageInfo = @"6666666";
imageModel2.imageTitle = @"5555555";

PooShowImageModel *imageModel3 = [[PooShowImageModel alloc] init];
imageModel3.imageUrl = @"https://timgsa.baidu.com/timg?image&quality=80&size=b9999_10000&sec=1535114837724&di=c006441b6c288352e1fcdfc7b47db2b3&imgtype=0&src=http%3A%2F%2Fimg5.duitang.com%2Fuploads%2Fitem%2F201412%2F13%2F20141213142127_yXadz.thumb.700_0.gif";
imageModelV.imageShowType = PooShowImageModelTypeGIF;
imageModel3.imageInfo = @"444444";
imageModel3.imageTitle = @"333333";

NSArray *arr = @[imageModel,imageModelV,imageModel2,imageModel3];

YMShowImageView *ymImageV = [[YMShowImageView alloc] initWithByClick:YMShowImageViewClickTagAppend appendArray:arr titleColor:[UIColor whiteColor] fontName:FontName showImageBackgroundColor:[UIColor blackColor] showWindow:[PTAppDelegate appDelegate].window loadingImageName:@"DemoImage" deleteAble:YES saveAble:YES moreActionImageName:@"DemoImage"];
[ymImageV showWithFinish:^{
[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
}];
[ymImageV mas_makeConstraints:^(MASConstraintMaker *make) {
make.left.right.top.bottom.equalTo([PTAppDelegate appDelegate].window);
}];
ymImageV.saveImageStatus = ^(BOOL saveStatus) {
PNSLog(@"%d",saveStatus);
};
```
'简单的饼状图'</br>
'自定义AlertView'</br>
'日期选择器/时间选择器'</br>
'以Scroll展示方式的广告View'</br>
'自定义ActionSheet'</br>
'带动画的TextField'</br>
'DES加密'</br>
'以KeyChain方式保存帐号密码'</br>
'可以变大的TextView'</br>
'iOS黑魔法'</br>
'随机数组'</br>
'字符串数组更换'</br>
'MD5加密'</br>
'正则表达式'</br>
'富文本'</br>
'在线获取App版本'</br>
'Bug报告'</br>
'运营商获取'</br>
'GifLoading框'</br>
'HealthKit'</br>
'带穿过线的Label'</br>
'App启动广告View'</br>
'一些常用的宏定义'</br>
'M7+处理器数据获取'</br>
'加入到日历提醒'</br>
'验证码生成'</br>
'简单的Loading动画'</br>
'数字键盘'</br>
'打电话模块'</br>
'SearchBar'</br>
'分段选择器'</br>
'系统信息'</br>
'标签Label'</br>
'带有Placeholder的TextView'</br>
'UDID生成'</br>
'语音翻译'</br>
'评分View'</br>
'TextField类似TextView那样最左有图片'</br>
'浮动按钮'</br>
'后台界面模糊效果'</br>
'按钮扩展'</br>
'颜色扩展'</br>
'图片模糊化'</br>
'图片大小切换'</br>
'跳动数字Label'</br>
'导航栏按钮扩展'</br>
'界面的XYWH边界获取'</br>
'StatusBar的信息提醒'</br>
'一些其他工具集合'</br>
'类似Google的Loading'</br>
'Layer的AutoLayout'</br>

## About iOS Kit

本工具运用到以下系统工具:</br>
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
'TOWebViewController':https://github.com/TimOliver/TOWebViewController</br>
'UITextField+Shake':https://github.com/andreamazz/UITextField-Shake</br>
'UINavigation-SXFixSpace':https://github.com/spicyShrimp/UINavigation-SXFixSpace</br>
'UITableView+FDTemplateLayoutCell':https://github.com/forkingdog/UITableView-FDTemplateLayoutCell</br>
'UIViewController+Swizzled':https://github.com/RuiAAPeres/UIViewController-Swizzled</br>
'YCXMenu':https://github.com/Aster0id/YCXMenuDemo_ObjC</br>

## Requirements

使用工具时，一定要在Build Settings->other links flags加入-ObjC和-all_load,以防避免一些奇奇怪怪的问题发生.

## Attention

本工具使用了HealthKit之类的框架,审核时可能要集成,如果没需要,可以移除这些框架

## Installation

PooTools is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'PooTools'
```

## Author

crazypoo, 273277355@qq.com

## License

PooTools is available under the MIT license. See the LICENSE file for more info.
