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
```objc
```
'虚线View'</br>
```objc
```
'温度计View'</br>
```objc
```
'Slider'</br>
```objc
```
'按钮内的文图扩展'</br>
```objc
```
'iPhone生物验证'</br>
```objc
PBiologyID *touchID = [PBiologyID defaultBiologyID];
touchID.biologyIDBlock = ^(BiologyIDType biologyIDType) {
PNSLog(@"%ld",(long)biologyIDType);
};
[self.touchID biologyAction];
```
'以CollectionView展示方式的广告View/以Scroll展示方式的广告View'</br>
```objc
---CollectionView方式
CGAdBannerModel *aaaaa = [[CGAdBannerModel alloc] init];
aaaaa.bannerTitle = @"111111";

PADView *adaaaa = [[PADView alloc] initWithAdArray:@[aaaaa,aaaaa] singleADW:kSCREEN_WIDTH singleADH:150 paddingY:5 paddingX:5 placeholderImage:@"DemoImage" pageTime:1 adTitleFont:kDEFAULT_FONT(FontName, 19)];
[self.view addSubview:adaaaa];
[adaaaa mas_makeConstraints:^(MASConstraintMaker *make) {
make.left.right.equalTo(self.view);
make.top.offset(100);
make.height.offset(150);
}];

--Scroll方式
IGBannerView *banner = [[IGBannerView alloc] initWithFrame:CGRectMake(0, HEIGHT_NAVBAR*2+100+10, kSCREEN_WIDTH, 100) bannerItems:@[[IGBannerItem itemWithTitle:@"广告1" imageUrl:@"" tag:0],[IGBannerItem itemWithTitle:@"广告2" imageUrl:@"http://p3.music.126.net/VDn1p3j4g2z4p16Gux969w==/2544269907756816.jpg" tag:1]] bannerPlaceholderImage:kImageNamed(@"DemoImage")];
banner.pageControlBackgroundColor = [UIColor clearColor];
banner.titleBackgroundColor = [UIColor clearColor];
banner.titleColor = [UIColor clearColor];
//            banner.delegate                   = self;
banner.autoScrolling              = YES;
banner.titleFont = kDEFAULT_FONT(FontName,14);
[self.view addSubview:banner];
banner.bannerTapBlock = ^(IGBannerView *bannerView, IGBannerItem *bannerItem) {
PNSLog(@">>>>>>>>>>%@",bannerItem);
};
```
'CollectionViewLayout的快速初始化'</br>
```objc
+(UICollectionViewFlowLayout *)createLayoutNormalScrollDirection:(UICollectionViewScrollDirection)sd;
+(UICollectionViewFlowLayout *)createLayoutItemW:(CGFloat)w itemH:(CGFloat)h paddingY:(CGFloat)pY paddingX:(CGFloat)pX scrollDirection:(UICollectionViewScrollDirection)sd;
+(UICollectionViewFlowLayout *)createLayoutItemW:(CGFloat)w itemH:(CGFloat)h sectionInset:(UIEdgeInsets)inset minimumLineSpacing:(CGFloat)mls minimumInteritemSpacing:(CGFloat)mis scrollDirection:(UICollectionViewScrollDirection)sd;
```
'清理缓存'</br>
```objc
[PooCleanCache getCacheSize];
[PooCleanCache clearCaches];
```
'AES加密'</br>
```objc
```
'Base64加密/RSA加密'</br>
```objc
```
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
```objc
```
'自定义AlertView'</br>
```objc
YXCustomAlertView *alert = [[YXCustomAlertView alloc] initAlertViewWithSuperView:self.view alertTitle:@"111123123" withButtonAndTitleFont:[UIFont systemFontOfSize:20] titleColor:kRandomColor bottomButtonTitleColor:kRandomColor verLineColor:kRandomColor moreButtonTitleArray:@[@"111",@"222"] viewTag:1 setCustomView:^(YXCustomAlertView *alertView) {

} clickAction:^(YXCustomAlertView *alertView, NSInteger buttonIndex) {
switch (buttonIndex) {
case 0:
{
[alertView dissMiss];
alertView = nil;
}
break;
case 1:
{
[alertView dissMiss];
alertView = nil;
}
break;
default:
break;
}

} didDismissBlock:^(YXCustomAlertView *alertView) {

}];
[alert mas_makeConstraints:^(MASConstraintMaker *make) {
make.width.height.offset(310);
make.centerX.centerY.equalTo(self.view);
}];
```
'日期选择器/时间选择器'</br>
```objc
---DatePicker
PooDatePicker *viewDate = [[PooDatePicker alloc] initWithTitle:@"1111" toolBarBackgroundColor:kRandomColor labelFont:APPFONT(16) toolBarTitleColor:kRandomColor pickerFont:APPFONT(16) pickerType:PPickerTypeY];
[self.view addSubview:viewDate];
[viewDate mas_makeConstraints:^(MASConstraintMaker *make) {
make.left.right.top.bottom.equalTo(self.view);
}];
viewDate.block = ^(NSString *dateString) {
PNSLog(@">>>>>>>>>>>%@",dateString);
};

---TimePicker
PooTimePicker *view = [[PooTimePicker alloc] initWithTitle:@"1111" toolBarBackgroundColor:kRandomColor labelFont:APPFONT(16) toolBarTitleColor:kRandomColor pickerFont:APPFONT(16)];
view.delegate = self;
[[PTAppDelegate appDelegate].window addSubview:view];
[view mas_makeConstraints:^(MASConstraintMaker *make) {
make.left.right.top.bottom.equalTo(self.view);
}];
[view customPickerView:view.pickerView didSelectRow:10 inComponent:0];
[view customSelectRow:10 inComponent:0 animated:YES];

[view customPickerView:view.pickerView didSelectRow:1 inComponent:1];
[view customSelectRow:1 inComponent:1 animated:YES];
view.dismissBlock = ^(PooTimePicker *timePicker) {
[timePicker removeFromSuperview];
timePicker = nil;
};

---TimePickerDelegate
-(void)timePickerReturnStr:(NSString *)timeStr timePicker:(PooTimePicker *)timePicker
{
PNSLog(@">>>>>>>>>>>>>%@",timeStr);
}

-(void)timePickerDismiss:(PooTimePicker *)timePicker
{
PNSLog(@">>>>>>>>>>>>>%@",timePicker);
}
```
'自定义ActionSheet'</br>
```objc
ALActionSheetView *actionSheet = [[ALActionSheetView alloc] initWithTitle:@"11111" cancelButtonTitle:@"11111" destructiveButtonTitle:@"11111" otherButtonTitles:@[@"1231",@"1231",@"1231",@"1231"] buttonFontName:FontNameBold handler:^(ALActionSheetView *actionSheetView, NSInteger buttonIndex) {

}];
[actionSheet show];
```
'带动画的TextField'</br>
```objc
```
'DES加密'</br>
```objc
```
'以KeyChain方式保存帐号密码'</br>
```objc
```
'可以变大的TextView'</br>
```objc
```
'iOS黑魔法'</br>
```objc
```
'随机数组'</br>
```objc
```
'字符串数组更换'</br>
```objc
```
'MD5加密'</br>
```objc
```
'正则表达式'</br>
```objc
```
'富文本'</br>
```objc
```
'在线获取App版本'</br>
```objc
```
'Bug报告'</br>
```objc
```
'运营商获取'</br>
```objc
[PCarrie currentRadioAccessTechnology];
```
'GifLoading框'</br>
```objc
[PGifHud gifHUDShowIn:self.view];
[PGifHud setGifWithURL:[NSURL URLWithString:@"https://timgsa.baidu.com/timg?image&quality=80&size=b9999_10000&sec=1535114837724&di=c006441b6c288352e1fcdfc7b47db2b3&imgtype=0&src=http%3A%2F%2Fimg5.duitang.com%2Fuploads%2Fitem%2F201412%2F13%2F20141213142127_yXadz.thumb.700_0.gif"]];
[PGifHud showWithOverlay];
dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC*DelaySecond*3), dispatch_get_main_queue(), ^{
[PGifHud dismiss];
});
```
'HealthKit'</br>
```objc
```
'带穿过线的Label'</br>
```objc
PLabel *aaaaaaaaaaaaaa = [PLabel new];
aaaaaaaaaaaaaa.backgroundColor = kRandomColor;
[aaaaaaaaaaaaaa setVerticalAlignment:VerticalAlignmentMiddle strikeThroughAlignment:StrikeThroughAlignmentMiddle setStrikeThroughEnabled:YES];
aaaaaaaaaaaaaa.text = @"111111111111111";
[self.view addSubview:aaaaaaaaaaaaaa];
[aaaaaaaaaaaaaa mas_makeConstraints:^(MASConstraintMaker *make) {
make.top.equalTo(self.view).offset(HEIGHT_NAVBAR);
make.left.right.equalTo(self.view);
make.height.offset(44);
}];

```
'App启动广告View'</br>
```objc
[PLaunchAdMonitor showAdAtPath:@[@"http://p3.music.126.net/VDn1p3j4g2z4p16Gux969w==/2544269907756816.jpg"] onView:self.window.rootViewController.view timeInterval:100 detailParameters:@{} years:@"2000" skipButtonFont:APPFONT(16) comName:@"11111" comNameFont:APPFONT(12) callback:^{
}];
```
'一些常用的宏定义'</br>
```objc
#pragma mark ---------------> 判断当前的iPhone设备/系统版本
/*! @brief 当前系统版本与系统v是否匹配
*/
#define SYSTEM_VERSION_EQUAL_TO(v)                  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedSame)
/*! @brief 当前系统版本是否大于v系统
*/
#define SYSTEM_VERSION_GREATER_THAN(v)              ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedDescending)
/*! @brief 当前系统版本是否大于等于v系统
*/
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
/*! @brief 当前系统版本是否小于v系统
*/
#define SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
/*! @brief 当前系统版本是否小于等于v系统
*/
#define SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(v)     ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedDescending)
/*! @brief 判断是否iOS8之前的系统版本
*/
#define IOS8before [[[UIDevice currentDevice] systemVersion] floatValue] < 8
/*! @brief 判断是否为iPhone
*/
#define IS_IPHONE (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
/*! @brief 判断是否为iPad
*/
#define IS_IPAD (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
/*! @brief 判断是否为ipod
*/
#define IS_IPOD ([[[UIDevice currentDevice] model] isEqualToString:@"iPod touch"])
/*! @brief 判断 iOS 8 或更高的系统版本
*/
#define IOS_VERSION_8_OR_LATER (([[[UIDevice currentDevice] systemVersion] floatValue] >=8.0)? (YES):(NO))

#pragma mark ---------------> 屏幕
/*! @brief 屏幕为类似iPhone4的机型
*/
#define iPhone4 ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(640, 960), [[UIScreen mainScreen] currentMode].size) : NO)
/*! @brief 屏幕为类似iPhone5的机型
*/
#define iPhone5 ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(640, 1136), [[UIScreen mainScreen] currentMode].size) : NO)
/*! @brief 屏幕为类似iPhone6的机型
*/
#define iPhone6 ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(750, 1334), [[UIScreen mainScreen] currentMode].size) : NO)
/*! @brief 屏幕为类似iPhone6P的机型
*/
#define iPhone6P ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(1242, 2208), [[UIScreen mainScreen] currentMode].size) : NO)
/*! @brief 屏幕为类似iPadAir的机型
*/
#define iPad_Air ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(768, 1024), [[UIScreen mainScreen] currentMode].size) : NO)
/*! @brief 屏幕为类似iPhoneX的机型
*/
#define kDevice_Is_iPhoneX ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(1125, 2436), [[UIScreen mainScreen] currentMode].size) : NO)
/*! @brief 屏幕为类似iPhoneXR的机型
*/
#define kDevice_Is_iPhoneXR ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(828, 1792), [[UIScreen mainScreen] currentMode].size) : NO)
/*! @brief 屏幕为类似iPhoneXS MAX的机型
*/
#define kDevice_Is_iPhoneXS_MAX ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(1242, 2688), [[UIScreen mainScreen] currentMode].size) : NO)

/*! @brief 当前屏幕宽度
*/
#define kSCREEN_WIDTH [UIScreen mainScreen].bounds.size.width
/*! @brief 当前屏幕高度
*/
#define kSCREEN_HEIGHT [UIScreen mainScreen].bounds.size.height
/*! @brief 当前屏幕Size
*/
#define kSCREEN_SIZE [UIScreen mainScreen].bounds.size
/*! @brief 当前屏幕比例
*/
#define kSCREEN_SCALE ([UIScreen mainScreen].scale)
/*! @brief 获取KeyWindow
*/
#define kKEYWINDOW [UIApplication sharedApplication].keyWindow

/*! @brief 电池栏菊花转动
*/
#define kShowNetworkActivityIndicator() [UIApplication sharedApplication].networkActivityIndicatorVisible = YES
/*! @brief 电池栏菊花停止转动
*/
#define kHideNetworkActivityIndicator() [UIApplication sharedApplication].networkActivityIndicatorVisible = NO
/*! @brief 电池栏菊花设置是否转动
*/
#define NetworkActivityIndicatorVisible(x) [UIApplication sharedApplication].networkActivityIndicatorVisible = x

/*! @brief 获取view的宽度
*/
#define kGetViewWidth(view)  view.frame.size.width
/*! @brief 获取view的高度
*/
#define kGetViewHeight(view) view.frame.size.height
/*! @brief 获取view的x坐标
*/
#define kGetViewX(view)      view.frame.origin.x
/*! @brief 获取view的y坐标
*/
#define kGetViewY(view)      view.frame.origin.y

/*! @brief 获取垂直居中的x（parent的高度/2-child的高度/2）
*/
#define CENTER_VERTICALLY(parent,child) floor((parent.frame.size.height - child.frame.size.height) / 2)
/*! @brief 获取水平居中的y（parent的宽度/2-child的宽度/2）
*/
#define CENTER_HORIZONTALLY(parent,child) floor((parent.frame.size.width - child.frame.size.width) / 2)
/*! @brief 创建的view居中于parentView
* @see [[UIView alloc] initWithFrame:(CGRect){CENTER_IN_PARENT(parentView,500,500),CGSizeMake(500,500)}];
*/
#define CENTER_IN_PARENT(parent,childWidth,childHeight) CGPointMake(floor((parent.frame.size.width - childWidth) / 2),floor((parent.frame.size.height - childHeight) / 2))
/*! @brief 创建的view,x坐标居中于parentView
*/
#define CENTER_IN_PARENT_X(parent,childWidth) floor((parent.frame.size.width - childWidth) / 2)
/*! @brief 创建的view,y坐标居中于parentView
*/
#define CENTER_IN_PARENT_Y(parent,childHeight) floor((parent.frame.size.height - childHeight) / 2)
/*! @brief view的底部坐标y
*/
#define BOTTOM(view) (view.frame.origin.y + view.frame.size.height)
/*! @brief view的右边坐标x
*/
#define RIGHT(view) (view.frame.origin.x + view.frame.size.width)

/*! @brief 状态栏的底部坐标y
*/
#define kScreenStatusBottom  ([UIApplication sharedApplication].statusBarFrame.origin.y + [UIApplication sharedApplication].statusBarFrame.size.height)

/*! @brief nav高度
*/
#define HEIGHT_NAV 44.0
/*! @brief status高度 (iPhoneX除外)
*/
#define HEIGHT_STATUS 20.0
/*! @brief tabbar高度
*/
#define HEIGHT_TABBAR 44.0
/*! @brief 普通导航栏高度 (nav高度+status高度)
*/
#define HEIGHT_NAVBAR HEIGHT_NAV + HEIGHT_STATUS
/*! @brief status高度 (iPhoneX专用)
*/
#define HEIGHT_IPHONEXSTATUSBAR 44
/*! @brief iPhoneX导航栏高度 (nav高度+status高度)
*/
#define HEIGHT_IPHONEXNAVBAR HEIGHT_IPHONEXSTATUSBAR + HEIGHT_NAV

/*! @brief 大标题高度
*/
#define HEIGHT_LARGETITLE 52
/*! @brief 普通机型带大标题高度
*/
#define HEIGHT_NAVBARXLARGETITLE HEIGHT_NAVBAR + HEIGHT_LARGETITLE
/*! @brief iPhoneX带大标题高度
*/
#define HEIGHT_IPHONEXSTATUSBARXNAVXLARGETITLE HEIGHT_IPHONEXSTATUSBAR + HEIGHT_NAV + HEIGHT_LARGETITLE

/*! @brief Picker一般高度
*/
#define HEIGHT_PICKER 216
/*! @brief PickerToolBar一般高度
*/
#define HEIGHT_PICKERTOOLBAR 44
/*! @brief Button一般高度
*/
#define HEIGHT_BUTTON 44

/*! @brief 当前屏幕的宽与320的比例
*/
#define SCREEN_POINT (float)SCREEN_WIDTH/320.f
/*! @brief 当前屏幕的高度与480的比例
*/
#define SCREEN_H_POINT (float)SCREEN_HEIGHT/480.f

/*! @brief PS字号转换成iOS字号
*/
#define kPSFontToiOSFont(pixel) (pixel*3/4)

/*! @brief 设置View的tag属性
*/
#define kVIEWWITHTAG(_OBJECT, _TAG) [_OBJECT viewWithTag : _TAG]

/*! @brief R屏
*/
#define isRetina ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(640, 960), [[UIScreen mainScreen] currentMode].size) : NO)

/*! @brief SaveArea适配
*/
#define adjustsScrollViewInsets(scrollView)\
do {\
_Pragma("clang diagnostic push")\
_Pragma("clang diagnostic ignored \"-Warc-performSelector-leaks\"")\
if ([scrollView respondsToSelector:NSSelectorFromString(@"setContentInsetAdjustmentBehavior:")]) {\
NSMethodSignature *signature = [UIScrollView instanceMethodSignatureForSelector:@selector(setContentInsetAdjustmentBehavior:)];\
NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];\
NSInteger argument = 2;\
invocation.target = scrollView;\
invocation.selector = @selector(setContentInsetAdjustmentBehavior:);\
[invocation setArgument:&argument atIndex:2];\
[invocation retainArguments];\
[invocation invoke];\
}\
_Pragma("clang diagnostic pop")\
} while (0)

/*! @brief AppDelegateWindow
*/
#define kAppDelegateWindow [[[UIApplication sharedApplication] delegate] window]

#pragma mark ---------------> 通知中心
/*! @brief [NSNotificationCenter defaultCenter]
*/
#define kNotificationCenter [NSNotificationCenter defaultCenter]

#pragma mark ---------------> 颜色
/*! @brief 随机颜色
*/
#define kRandomColor [UIColor colorWithRed:arc4random_uniform(256)/255.0 green:arc4random_uniform(256)/255.0 blue:arc4random_uniform(256)/255.0 alpha:1.0]
/*! @brief 随机颜色 (带Alpha值)
*/
#define kRandomColorWithAlpha(s) [UIColor colorWithRed:arc4random_uniform(256)/255.0 green:arc4random_uniform(256)/255.0 blue:arc4random_uniform(256)/255.0 alpha:s]

/*! @brief 设置RGB颜色
*/
#define kRGBColor(r, g, b) [UIColor colorWithRed:(r)/255.0 green:(g)/255.0 blue:(b)/255.0 alpha:1.0]
/*! @brief 设置RGB颜色 (带Alpha值)
*/
#define kRGBAColor(r, g, b, a) [UIColor colorWithRed:(r)/255.0 green:(g)/255.0 blue:(b)/255.0 alpha:a]

/*! @brief 设置RGB颜色小数形式
*/
#define kRGBColorDecimals(r, g, b) [UIColor colorWithRed:(r) green:(g) blue:(b) alpha:1.0]
/*! @brief 设置RGB颜色小数形式(带Alpha值)
*/
#define kRGBAColorDecimals(r, g, b, a) [UIColor colorWithRed:(r) green:(g) blue:(b) alpha:a]

/*! @brief clear背景颜色
*/
#define kClearColor [UIColor clearColor]

/*! @brief 16进制RGB的颜色转换
*/
#define kColorFromHex(rgbValue) [UIColor \
colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 \
green:((float)((rgbValue & 0xFF00) >> 8))/255.0 \
blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

#pragma mark ---------------> judge the simulator or hardware device        判断是真机还是模拟器

/*! @brief 如果是真机
*/
#if TARGET_OS_IPHONE
//iPhone Device
#endif

/*! @brief 如果是模拟器
*/
#if TARGET_IPHONE_SIMULATOR
//iPhone Simulator
#endif

#pragma mark ---------------> 弱引用/强引用
/*! @brief 弱引用
*/
#define kWeakSelf(type)  __weak typeof(type) weak##type = type;
/*! @brief 强引用
*/
#define kStrongSelf(type)  __strong typeof(type) type = weak##type;

#pragma mark ---------------> 设置 view 圆角和边框
/*! @brief 设置 view 圆角和边框
*/
#define kViewBorderRadius(View, Radius, Width, Color)\
\
[View.layer setCornerRadius:(Radius)];\
[View.layer setMasksToBounds:YES];\
[View.layer setBorderWidth:(Width)];\
[View.layer setBorderColor:[Color CGColor]]

#pragma mark ---------------> 使用 ARC 和 MRC
/*! @brief 判断ARC或者MRC
*/
#if __has_feature(objc_arc)
// ARC
#else
// MRC
#endif

#pragma mark ---------------> 沙盒目录文件
/*! @brief 获取temp
*/
#define kPathTemp NSTemporaryDirectory()
/*! @brief 获取沙盒 Document
*/
#define kPathDocument [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject]
/*! @brief 获取沙盒 Cache
*/
#define kPathCache [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject]

#pragma mark ---------------> NAV返回方法
/*! @brief nav返回上一层
*/
#define kReturnsToTheUpperLayer [self.navigationController popViewControllerAnimated:YES];

#pragma mark ---------------> 获取当前语言
/*! @brief 获取当前语言
*/
#define kCurrentLanguage ([[NSLocale preferredLanguages] objectAtIndex:0])

#pragma mark ---------------> ----------------------ABOUT IMAGE 图片 ----------------------------
/*! @brief 读取本地图片 (ContentsOfFile形式读取,带格式)
*/
#define kLOADIMAGE(file,ext) [UIImage imageWithContentsOfFile:[[NSBundle mainBundle]pathForResource:file ofType:ext]]
/*! @brief 定义UIImage对象 (ContentsOfFile形式读取,不带格式)
*/
#define kIMAGE(A) [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:A ofType:nil]]
/*! @brief 定义UIImage对象 (Name形式读取)
* @attention 优先使用前两种宏定义(kLOADIMAGE(file,ext),kIMAGE(A)),性能高于后面.
*/
#define kImageNamed(_pointer) [UIImage imageNamed:_pointer]

#pragma mark ---------------> 打印
/*! @brief 强化NSLog
*/
#define PNSLog(format, ...) do {                                                                          \
fprintf(stderr, "<%s : %d> %s\n",                                           \
[[[NSString stringWithUTF8String:__FILE__] lastPathComponent] UTF8String],  \
__LINE__, __func__);                                                        \
(NSLog)((format), ##__VA_ARGS__);                                           \
fprintf(stderr, "我这里是打印,不要慌,我路过的😂😂😂😂😂😂😂😂😂😂😂😂\n");                                               \
} while (0)

#pragma mark ---------------> NSUserDefaults 实例化
/*! @brief NSUserDefaults 实例化
*/
#define USER_DEFAULT [NSUserDefaults standardUserDefaults]

#pragma mark ---------------> 存储对象
/*! @brief 储存数据NSUserDefaults
*/
#define kUserDefaultSetObjectForKey(__VALUE__,__KEY__) \
{\
[USER_DEFAULT setObject:__VALUE__ forKey:__KEY__];\
[USER_DEFAULT synchronize];\
}
/*! @brief 获得存储的对象NSUserDefaults
*/
#define kUserDefaultObjectForKey(__KEY__)  [USER_DEFAULT objectForKey:__KEY__]
/*! @brief 删除对象NSUserDefaults
*/
#define kUserDefaultRemoveObjectForKey(__KEY__) \
{\
[USER_DEFAULT removeObjectForKey:__KEY__];\
[USER_DEFAULT synchronize];\
}
/*! @brief 修改data.plist文件
*/
#define PLIST_TICKET_INFO_EDIT [NSHomeDirectory() stringByAppendingString:@"/Documents/data.plist"]

#pragma mark ---------------> TABLEVIEW
/*! @brief 初始化某TableViewCell
*/
#define kTableViewCellAlloc(__CLASS__,__INDETIFIER__) [[__CLASS__ alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:(__INDETIFIER__)]
/*! @brief 初始化某TableViewCell的Dequeue
*/
#define kTableViewCellDequeueInit(__INDETIFIER__) [tableView dequeueReusableCellWithIdentifier:(__INDETIFIER__)];
/*! @brief 当某TableViewCell为空时初始化cell
*/
#define kTableViewCellDequeue(__CELL__,__CELLCLASS__,__INDETIFIER__) \
{\
if (__CELL__ == nil) {\
__CELL__ = [[__CELLCLASS__ alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:__INDETIFIER__];\
}\
}
/*! @brief 当某TableViewCell为空时初始化cell (自定义Style)
*/
#define kTableViewCellDequeueWithStyle(__CELL__,__CELLCLASS__,__STYLE__,__INDETIFIER__) \
{\
if (__CELL__ == nil) {\
__CELL__ = [[__CELLCLASS__ alloc]initWithStyle:__STYLE__ reuseIdentifier:__INDETIFIER__];\
}\
}
/*! @brief 初始化TableViewCell
*/
#define kTableCellFullInit(__CELLNAME__,__CELLCLASSNAME__,__STYLE__,__INDETIFIER__) \
__CELLCLASSNAME__ *__CELLNAME__ = nil; \
if (__CELLNAME__ == nil) \
{ \
__CELLNAME__ = [[__CELLCLASSNAME__ alloc]initWithStyle:__STYLE__ reuseIdentifier:__INDETIFIER__]; \
} \
else \
{ \
while ([__CELLNAME__.contentView.subviews lastObject] != nil) { \
[(UIView *)[__CELLNAME__.contentView.subviews lastObject] removeFromSuperview]; \
} \
}

#pragma mark ---------------> Show Alert, brackets is the parameters.       宏定义一个弹窗方法,括号里面是方法的参数
/*! @brief 定义一个简单的取消弹出框
*/
#define ShowAlert(s) [[[UIAlertView alloc] initWithTitle:@"OPPS!" message:s delegate:self cancelButtonTitle:@"cancel" otherButtonTitles: @"OK"]show];
#endif

#pragma mark ---------------> GCD
/*! @brief GCDGlobal
*/
#define GCDWithGlobal(block) dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{block})
/*! @brief GCDMain
*/
#define GCDWithMain(block) dispatch_async(dispatch_get_main_queue(),block)
/*! @brief GCD (一次性执行)
*/
#define kDISPATCH_ONCE_BLOCK(onceBlock) static dispatch_once_t onceToken; dispatch_once(&onceToken, onceBlock);
/*! @brief GCD (在Main线程上运行)
*/
#define kDISPATCH_MAIN_THREAD(mainQueueBlock) dispatch_async(dispatch_get_main_queue(), mainQueueBlock);
/*! @brief GCD (开启异步线程)
*/
#define kDISPATCH_GLOBAL_QUEUE_DEFAULT(globalQueueBlock) dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), globalQueueBlock);

#pragma mark ---------------> 单例化 一个类
/*! @brief 创建单例
*/
#define SYNTHESIZE_SINGLETON_FOR_CLASS(classname) \
\
static classname *shared##classname = nil; \
\
+ (classname *)shared##classname \
{ \
@synchronized(self) \
{ \
if (shared##classname == nil) \
{ \
shared##classname = [[self alloc] init]; \
} \
} \
\
return shared##classname; \
} \
\
+ (id)allocWithZone:(NSZone *)zone \
{ \
@synchronized(self) \
{ \
if (shared##classname == nil) \
{ \
shared##classname = [super allocWithZone:zone]; \
return shared##classname; \
} \
} \
\
return nil; \
} \
\
- (id)copyWithZone:(NSZone *)zone \
{ \
return self; \
}

#pragma mark ---------------> 快速查询一段代码的执行时间
/*! @brief 快速查询一段代码的执行时间 (TICK)
* @see 用法TICK(do your work here)TOCK
*/
#define TICK NSDate *startTime = [NSDate date];
/*! @brief 快速查询一段代码的执行时间 (TOCK)
* @see 用法TICK(do your work here)TOCK
*/
#define TOCK NSLog(@"Time:%f", -[startTime timeIntervalSinceNow]);

#pragma mark ---------------> 设置默认字体&字体大小
/*! @brief 设置默认字体&字体大小
*/
#define kDEFAULT_FONT(n,s)     [UIFont fontWithName:n size:s]

/*! @brief 屏幕宽比例 (6SP为对比)
*/
#define kScreenWidthRatio  (UIScreen.mainScreen.bounds.size.width / 375.0)
/*! @brief 屏幕高比例 (6SP为对比)
*/
#define kScreenHeightRatio (UIScreen.mainScreen.bounds.size.height / 667.0)
/*! @brief 实际x宽 (6SP为对比)
*/
#define kAdaptedWidth(x)  ceilf((x) * kScreenWidthRatio)
/*! @brief 实际x高 (6SP为对比)
*/
#define kAdaptedHeight(x) ceilf((x) * kScreenHeightRatio)
/*! @brief 实际系统字体字号R的大小 (6SP为对比)
*/
#define kAdaptedFontSize(R) [UIFont systemFontOfSize:kAdaptedWidth(R)]
/*! @brief 实际自定义字体字号R的大小 (6SP为对比)
*/
#define kAdaptedOtherFontSize(n,R) kDEFAULT_FONT(n,kAdaptedWidth(R))

#pragma mark ---------------> 创建返回按钮
/*! @brief 创建返回按钮 (可以自定义图片)
*/
#define kCreatReturnButton(imageName,acttion)  UIButton *leftNavBtn = [UIButton buttonWithType:UIButtonTypeCustom];leftNavBtn.frame = CGRectMake(0, 0, 44, 44);[leftNavBtn setImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];[leftNavBtn addTarget:self action:@selector(acttion) forControlEvents:UIControlEventTouchUpInside];[self.navigationItem setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithCustomView:leftNavBtn]];

#pragma mark ---------------> 由角度转换弧度 由弧度转换角度
/*! @brief 角度转弧度
*/
#define PDegreesToRadian(x) (M_PI * (x) / 180.0)
/*! @brief 弧度转角度
*/
#define PRadianToDegrees(radian) (radian*180.0)/(M_PI)

#pragma mark ---------------> 判断是否为空
/*! @brief 字符串是否为空
*/
#define kStringIsEmpty(str) ([str isKindOfClass:[NSNull class]] || str == nil || [str length] < 1 ? YES : NO )
/*! @brief 数组是否为空
*/
#define kArrayIsEmpty(array) (array == nil || [array isKindOfClass:[NSNull class]] || array.count == 0)
/*! @brief 字典是否为空
*/
#define kDictIsEmpty(dic) (dic == nil || [dic isKindOfClass:[NSNull class]] || dic.allKeys == 0)
/*! @brief 是否是空对象
*/
#define kObjectIsEmpty(_object) (_object == nil \
|| [_object isKindOfClass:[NSNull class]] \
|| ([_object respondsToSelector:@selector(length)] && [(NSData *)_object length] == 0) \
|| ([_object respondsToSelector:@selector(count)] && [(NSArray *)_object count] == 0))

```
'M7+处理器数据获取'</br>
```objc
```
'加入到日历提醒'</br>
```objc
```
'验证码生成'</br>
```objc
```
'简单的Loading动画'</br>
```objc
PooLoadingView *loading = [[PooLoadingView alloc] initWithFrame:CGRectZero];
[self.view addSubview:loading];
[loading mas_makeConstraints:^(MASConstraintMaker *make) {
make.width.height.offset(100);
make.centerX.centerY.equalTo(self.view);
}];
[loading startAnimation];
dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC*DelaySecond*3), dispatch_get_main_queue(), ^{
[loading stopAnimation];
});
```
'数字键盘'</br>
```objc
PooNumberKeyBoard *userNameKeyboard = [PooNumberKeyBoard pooNumberKeyBoardWithType:PKeyboardTypeNormal backSpace:^(PooNumberKeyBoard *keyboardView) {
} returnSTH:^(PooNumberKeyBoard *keyboardView, NSString *returnSTH) {
}];
```
'打电话模块'</br>
```objc
[PooPhoneBlock callPhoneNumber:@"13800138000" call:^(NSTimeInterval duration) {

} cancel:^{

}];
```
'SearchBar'</br>
```objc
PooSearchBar *searchBar = [PooSearchBar new];
searchBar.barStyle     = UIBarStyleDefault;
searchBar.translucent  = YES;
searchBar.keyboardType = UIKeyboardTypeDefault;
searchBar.searchPlaceholder = @"点击此处查找地市名字";
searchBar.searchPlaceholderColor = kRandomColor;
searchBar.searchPlaceholderFont = [UIFont systemFontOfSize:24];
searchBar.searchTextColor = kRandomColor;
searchBar.searchTextFieldBackgroundColor = kRandomColor;
searchBar.searchBarOutViewColor = kRandomColor;
searchBar.searchBarTextFieldCornerRadius = 15;
searchBar.cursorColor = kRandomColor;
[self.view addSubview:searchBar];
[searchBar mas_makeConstraints:^(MASConstraintMaker *make) {
make.left.right.top.equalTo(self.view);
make.height.offset(44);
}];

```
'分段选择器'</br>
```objc
PooSegView *seg = [[PooSegView alloc] initWithTitles:@[@"1",@"2"] titleNormalColor:[UIColor lightGrayColor] titleSelectedColor:[UIColor redColor] titleFont:APPFONT(16) setLine:YES lineColor:[UIColor blackColor] lineWidth:1 selectedBackgroundColor:[UIColor yellowColor] normalBackgroundColor:[UIColor blueColor] showType:PooSegShowTypeUnderLine clickBlock:^(PooSegView *segViewView, NSInteger buttonIndex) {

}];
[self.view addSubview:seg];
[seg mas_makeConstraints:^(MASConstraintMaker *make) {
make.left.right.top.equalTo(self.view);
make.height.offset(44);
}];
```
'系统信息'</br>
```objc
[PooSystemInfo isJailBroken];
[PooSystemInfo getDeviceVersion];
```
'标签Label'</br>
```objc
NSArray *titleS = @[@"7"];

PooTagsLabelConfig *config = [[PooTagsLabelConfig alloc] init];
config.itemHeight = 50;
config.itemWidth = 50;
config.itemHerMargin = 10;
config.itemVerMargin = 10;
config.hasBorder = YES;
config.topBottomSpace = 5.0;
config.itemContentEdgs = 20;
config.isCanSelected = YES;
config.isCanCancelSelected = YES;
config.isMulti = YES;
config.selectedDefaultTags = titleS;
config.borderColor = kRandomColor;
config.borderWidth = 2;
config.showStatus = PooTagsLabelShowWithImageStatusNoTitle;

NSArray *title = @[@"7",@"1",@"2",@"3",@"4",@"5",@"6",@"11",@"12",@"13",@"14",@"15",@"16",@"177",@"123123123",@"1231231231314124"];

PooTagsLabel *tag = [[PooTagsLabel alloc] initWithTagsArray:title config:config wihtSection:0];
tag.backgroundColor = kRandomColor;
[self.view addSubview:tag];
[tag mas_makeConstraints:^(MASConstraintMaker *make) {
make.left.right.equalTo(self.view);
make.top.equalTo(self.view).offset(kScreenStatusBottom);
make.bottom.equalTo(self.view).offset(-kScreenStatusBottom);
}];
tag.tagHeightBlock = ^(PooTagsLabel *aTagsView, CGFloat viewHeight) {
PNSLog(@"%f",viewHeight);
};

```
'带有Placeholder的TextView'</br>
```objc
PooTextView *textView = [PooTextView new];
textView.backgroundColor = kRandomColor;
textView.placeholder = @"我是TextView";
textView.delegate = self;
textView.returnKeyType = UIReturnKeyDone;
textView.font = APPFONT(20);
textView.textColor = kRandomColor;
[self.view addSubview:textView];
[textView mas_makeConstraints:^(MASConstraintMaker *make) {
make.top.equalTo(searchBar.mas_bottom).offset(10);
make.left.right.equalTo(self.view);
make.height.offset(44);
}];
```
'UDID生成'</br>
```objc
```
'语音翻译'</br>
```objc
```
'评分View'</br>
```objc
PStarRateView *rV = [[PStarRateView alloc] initWithRateBlock:^(PStarRateView *rateView, CGFloat newScorePercent) {
}];
rV.backgroundColor = kRandomColor;
rV.scorePercent = 0.5;
rV.hasAnimation = NO;
rV.allowIncompleteStar = NO;
[self.view addSubview:rV];
[rV mas_makeConstraints:^(MASConstraintMaker *make) {
make.centerX.centerY.equalTo(self.view);
make.height.offset(100);
make.left.right.equalTo(self.view);
}];
```
'TextField类似TextView那样最左有图片'</br>
```objc
```
'浮动按钮'</br>
```objc
```
'后台界面模糊效果'</br>
```objc
```
'按钮扩展'</br>
```objc
```
'颜色扩展'</br>
```objc
```
'毛玻璃图片效果'</br>
```objc
UIImage *placeholderImage = kImageNamed(@"DemoImage");

UIImageView *blurGlassImage = [UIImageView new];
blurGlassImage.image = [placeholderImage imgWithBlur];
[self.view addSubview:blurGlassImage];
[blurGlassImage mas_makeConstraints:^(MASConstraintMaker *make) {
make.left.equalTo(self.view);
make.top.equalTo(self.view).offset(HEIGHT_NAVBAR);
make.width.height.offset(100);
}];
```
'图片大小切换'</br>
```objc
```
'跳动数字Label'</br>
```objc
```
'导航栏按钮扩展'</br>
```objc
```
'界面的XYWH边界获取'</br>
```objc
```
'StatusBar的信息提醒'</br>
```objc
```
'一些其他工具集合'</br>
```objc
```
'类似Google的Loading'</br>
```objc
[WMHub show];
```
'Layer的AutoLayout'</br>
```objc
```
'限制输入字数'</br>
```objc
[testField setPlaceholder:@"11111" color:[UIColor redColor] font:[UIFont systemFontOfSize:15]];

[testField limitCondition:^BOOL(NSString *inputStr){
return ![testField.text isEqualToString:@"xxxxx"];
} action:^{
NSLog(@"limit action");
}];

[testField limitNums:3 action:^{
NSLog(@"num limit action");
}];

```
'国家地区号码'</br>
```objc
CountryCodeModel *model = [CountryCodes countryCodes][30];
PNSLog(@"%@-----%@",model.countryName,model.countryCode);

```
'获取本iPhone的IP地址'</br>
```objc
NSString *ipString = [PGetIpAddresses getIPAddress:YES];
```
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
'TOWebViewController':https://github.com/TimOliver/TOWebViewController</br>
'UITextField+Shake':https://github.com/andreamazz/UITextField-Shake</br>
'UINavigation-SXFixSpace':https://github.com/spicyShrimp/UINavigation-SXFixSpace</br>
'UITableView+FDTemplateLayoutCell':https://github.com/forkingdog/UITableView-FDTemplateLayoutCell</br>
'UIViewController+Swizzled':https://github.com/RuiAAPeres/UIViewController-Swizzled</br>
'YCXMenu':https://github.com/Aster0id/YCXMenuDemo_ObjC</br>
'ZipArchive':https://github.com/ZipArchive/ZipArchive</br>

## Requirements

使用工具时，一定要在Build Settings->other links flags加入-ObjC和-all_load,以防避免一些奇奇怪怪的问题发生.

## Attention

本工具使用了HealthKit之类的框架,审核时可能要集成,如果没需要,可以移除这些框架,使用压缩解压第三方库时,要添加libz.tbd

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
