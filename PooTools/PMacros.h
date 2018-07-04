//
//  PHong.h
//  PTools
//
//  Created by crazypoo on 14/9/14.
//  Copyright (c) 2014年 crazypoo. All rights reserved.
//

#ifndef PTools_PMacros_h
#define PTools_PMacros_h

#pragma mark ---------------> 判断当前的iPhone设备/系统版本
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#define SYSTEM_VERSION_EQUAL_TO(v)                  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedSame)
#define SYSTEM_VERSION_GREATER_THAN(v)              ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedDescending)
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(v)     ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedDescending)
//判断是否iOS8之前的系统版本
#define IOS8before [[[UIDevice currentDevice] systemVersion] floatValue] < 8
//判断是否为iPhone
#define IS_IPHONE (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
//判断是否为iPad
#define IS_IPAD (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
//判断是否为ipod
#define IS_IPOD ([[[UIDevice currentDevice] model] isEqualToString:@"iPod touch"])
//判断 iOS 8 或更高的系统版本
#define IOS_VERSION_8_OR_LATER (([[[UIDevice currentDevice] systemVersion] floatValue] >=8.0)? (YES):(NO))
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark ---------------> 屏幕
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//设备屏幕大小
#define iPhone4 ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(640, 960), [[UIScreen mainScreen] currentMode].size) : NO)
#define iPhone5 ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(640, 1136), [[UIScreen mainScreen] currentMode].size) : NO)
#define iPhone6 ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(750, 1334), [[UIScreen mainScreen] currentMode].size) : NO)
#define iPhone6P ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(1242, 2208), [[UIScreen mainScreen] currentMode].size) : NO)
#define iPad_Air ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(768, 1024), [[UIScreen mainScreen] currentMode].size) : NO)
#define kDevice_Is_iPhoneX ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(1125, 2436), [[UIScreen mainScreen] currentMode].size) : NO)

//屏幕W&H
#define kSCREEN_WIDTH [UIScreen mainScreen].bounds.size.width
#define kSCREEN_HEIGHT [UIScreen mainScreen].bounds.size.height
#define kSCREEN_SIZE [UIScreen mainScreen].bounds.size
#define kSCREEN_SCALE ([UIScreen mainScreen].scale)
#define kKEYWINDOW [UIApplication sharedApplication].keyWindow

//STATUSBAR
// 加载
#define kShowNetworkActivityIndicator() [UIApplication sharedApplication].networkActivityIndicatorVisible = YES
// 收起加载
#define kHideNetworkActivityIndicator() [UIApplication sharedApplication].networkActivityIndicatorVisible = NO
// 设置加载
#define NetworkActivityIndicatorVisible(x) [UIApplication sharedApplication].networkActivityIndicatorVisible = x

//获取view的frame
#define kGetViewWidth(view)  view.frame.size.width
#define kGetViewHeight(view) view.frame.size.height
#define kGetViewX(view)      view.frame.origin.x
#define kGetViewY(view)      view.frame.origin.y
//获取垂直居中的x（父的高度/2-子的高度/2）
#define CENTER_VERTICALLY(parent,child) floor((parent.frame.size.height - child.frame.size.height) / 2)
//获取水平居中的y（父的宽度/2-子的宽度/2）
#define CENTER_HORIZONTALLY(parent,child) floor((parent.frame.size.width - child.frame.size.width) / 2)
// example: [[UIView alloc] initWithFrame:(CGRect){CENTER_IN_PARENT(parentView,500,500),CGSizeMake(500,500)}];
#define CENTER_IN_PARENT(parent,childWidth,childHeight) CGPointMake(floor((parent.frame.size.width - childWidth) / 2),floor((parent.frame.size.height - childHeight) / 2))
#define CENTER_IN_PARENT_X(parent,childWidth) floor((parent.frame.size.width - childWidth) / 2)
#define CENTER_IN_PARENT_Y(parent,childHeight) floor((parent.frame.size.height - childHeight) / 2)
//view的bottom的y
#define BOTTOM(view) (view.frame.origin.y + view.frame.size.height)
//view的right的x
#define RIGHT(view) (view.frame.origin.x + view.frame.size.width)

#define kScreenStatusBottom  ([UIApplication sharedApplication].statusBarFrame.origin.y + [UIApplication sharedApplication].statusBarFrame.size.height)

//普通NAV
#define HEIGHT_NAV 44.0//nav高度
#define HEIGHT_STATUS 20.0//status高度
#define HEIGHT_TABBAR 44.0//tabbar高度
#define HEIGHT_NAVBAR 64//普通导航栏高度
#define HEIGHT_IPHONEXSTATUSBAR 44//iPhonex的status高度
#define HEIGHT_IPHONEXNAVBAR HEIGHT_IPHONEXSTATUSBAR+HEIGHT_NAV//iPhoneX导航栏高度

////普通Nav加LargeTitle
#define HEIGHT_LARGETITLE 52//大标题高度
#define HEIGHT_NAVBARXLARGETITLE HEIGHT_NAVBAR+HEIGHT_LARGETITLE//普通机型带大标题高度
#define HEIGHT_IPHONEXSTATUSBARXNAVXLARGETITLE HEIGHT_IPHONEXSTATUSBAR+HEIGHT_NAV+HEIGHT_LARGETITLE//iPhoneX带大标题高度

#define SCREEN_POINT (float)SCREEN_WIDTH/320.f
#define SCREEN_H_POINT (float)SCREEN_HEIGHT/480.f

//ps字号----->ios字号
#define kPSFontToiOSFont(pixel) (pixel*3/4)

//设置View的tag属性
#define kVIEWWITHTAG(_OBJECT, _TAG) [_OBJECT viewWithTag : _TAG]

//R屏
#define isRetina ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(640, 960), [[UIScreen mainScreen] currentMode].size) : NO)
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark ---------------> 通知中心
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#define kNotificationCenter [NSNotificationCenter defaultCenter]
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark ---------------> 颜色
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//随机颜色
#define kRandomColor [UIColor colorWithRed:arc4random_uniform(256)/255.0 green:arc4random_uniform(256)/255.0 blue:arc4random_uniform(256)/255.0 alpha:1.0]
#define kRandomColorWithAlpha(s) [UIColor colorWithRed:arc4random_uniform(256)/255.0 green:arc4random_uniform(256)/255.0 blue:arc4random_uniform(256)/255.0 alpha:s]

//设置RGB颜色/设置RGBA颜色
#define kRGBColor(r, g, b) [UIColor colorWithRed:(r)/255.0 green:(g)/255.0 blue:(b)/255.0 alpha:1.0]
#define kRGBAColor(r, g, b, a) [UIColor colorWithRed:(r)/255.0 green:(g)/255.0 blue:(b)/255.0 alpha:a]


#define kRGBColorDecimals(r, g, b) [UIColor colorWithRed:(r) green:(g) blue:(b) alpha:1.0]
#define kRGBAColorDecimals(r, g, b, a) [UIColor colorWithRed:(r) green:(g) blue:(b) alpha:a]

// clear背景颜色
#define kClearColor [UIColor clearColor]

//16进制RGB的颜色转换
#define kColorFromHex(rgbValue) [UIColor \
colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 \
green:((float)((rgbValue & 0xFF00) >> 8))/255.0 \
blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark ---------------> judge the simulator or hardware device        判断是真机还是模拟器
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#if TARGET_OS_IPHONE
//iPhone Device
#endif

#if TARGET_IPHONE_SIMULATOR
//iPhone Simulator
#endif
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark ---------------> 弱引用/强引用
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#define kWeakSelf(type)  __weak typeof(type) weak##type = type;
#define kStrongSelf(type)  __strong typeof(type) type = weak##type;
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark ---------------> 设置 view 圆角和边框
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#define kViewBorderRadius(View, Radius, Width, Color)\
\
[View.layer setCornerRadius:(Radius)];\
[View.layer setMasksToBounds:YES];\
[View.layer setBorderWidth:(Width)];\
[View.layer setBorderColor:[Color CGColor]]
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark ---------------> 使用 ARC 和 MRC
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#if __has_feature(objc_arc)
// ARC
#else
// MRC
#endif
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark ---------------> 沙盒目录文件
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//获取temp
#define kPathTemp NSTemporaryDirectory()
//获取沙盒 Document
#define kPathDocument [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject]
//获取沙盒 Cache
#define kPathCache [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject]
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark ---------------> NAV返回方法
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#define kReturnsToTheUpperLayer [self.navigationController popViewControllerAnimated:YES];
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark ---------------> 获取当前语言
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#define kCurrentLanguage ([[NSLocale preferredLanguages] objectAtIndex:0])
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark ---------------> ----------------------ABOUT IMAGE 图片 ----------------------------
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//LOAD LOCAL IMAGE FILE     读取本地图片
#define kLOADIMAGE(file,ext) [UIImage imageWithContentsOfFile:[[NSBundle mainBundle]pathForResource:file ofType:ext]]
//DEFINE IMAGE      定义UIImage对象//    imgView.image = IMAGE(@"Default.png");
#define kIMAGE(A) [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:A ofType:nil]]
//DEFINE IMAGE      定义UIImage对象
#define kImageNamed(_pointer) [UIImage imageNamed:_pointer]
//BETTER USER THE FIRST TWO WAY, IT PERFORM WELL. 优先使用前两种宏定义,性能高于后面.
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark ---------------> 打印
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#define PNSLog(format, ...) do {                                                                          \
fprintf(stderr, "<%s : %d> %s\n",                                           \
[[[NSString stringWithUTF8String:__FILE__] lastPathComponent] UTF8String],  \
__LINE__, __func__);                                                        \
(NSLog)((format), ##__VA_ARGS__);                                           \
fprintf(stderr, "我这里是打印,不要慌,我路过的😂😂😂😂😂😂😂😂😂😂😂😂\n");                                               \
} while (0)
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


#pragma mark ---------------> 存储对象
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#define kUserDefaultSetObjectForKey(__VALUE__,__KEY__) \
{\
[[NSUserDefaults standardUserDefaults] setObject:__VALUE__ forKey:__KEY__];\
[[NSUserDefaults standardUserDefaults] synchronize];\
}

/**
 *  get the saved objects       获得存储的对象
 */
#define kUserDefaultObjectForKey(__KEY__)  [[NSUserDefaults standardUserDefaults] objectForKey:__KEY__]

/**
 *  delete objects      删除对象
 */
#define kUserDefaultRemoveObjectForKey(__KEY__) \
{\
[[NSUserDefaults standardUserDefaults] removeObjectForKey:__KEY__];\
[[NSUserDefaults standardUserDefaults] synchronize];\
}

#define PLIST_TICKET_INFO_EDIT [NSHomeDirectory() stringByAppendingString:@"/Documents/data.plist"] //edit the plist
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark ---------------> TABLEVIEW
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#define kTableViewCellAlloc(__CLASS__,__INDETIFIER__) [[__CLASS__ alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:(__INDETIFIER__)]

#define kTableViewCellDequeueInit(__INDETIFIER__) [tableView dequeueReusableCellWithIdentifier:(__INDETIFIER__)];

#define kTableViewCellDequeue(__CELL__,__CELLCLASS__,__INDETIFIER__) \
{\
if (__CELL__ == nil) {\
__CELL__ = [[__CELLCLASS__ alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:__INDETIFIER__];\
}\
}
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark ---------------> Show Alert, brackets is the parameters.       宏定义一个弹窗方法,括号里面是方法的参数
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#define ShowAlert(s) [[[UIAlertView alloc] initWithTitle:@"OPPS!" message:s delegate:self cancelButtonTitle:@"cancel" otherButtonTitles: @"OK"]show];
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#endif

#pragma mark ---------------> GCD
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#define GCDWithGlobal(block) dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{block})
#define GCDWithMain(block) dispatch_async(dispatch_get_main_queue(),block)
//GCD - 一次性执行
#define kDISPATCH_ONCE_BLOCK(onceBlock) static dispatch_once_t onceToken; dispatch_once(&onceToken, onceBlock);
//GCD - 在Main线程上运行
#define kDISPATCH_MAIN_THREAD(mainQueueBlock) dispatch_async(dispatch_get_main_queue(), mainQueueBlock);
//GCD - 开启异步线程
#define kDISPATCH_GLOBAL_QUEUE_DEFAULT(globalQueueBlock) dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), globalQueueBlock);
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark ---------------> NSUserDefaults 实例化
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#define USER_DEFAULT [NSUserDefaults standardUserDefaults]
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark ---------------> 单例化 一个类
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
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
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark ---------------> 快速查询一段代码的执行时间
/** 用法
 TICK
 do your work here
 TOCK
 */
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#define TICK NSDate *startTime = [NSDate date];
#define TOCK NSLog(@"Time:%f", -[startTime timeIntervalSinceNow]);
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark ---------------> 设置默认字体&字体大小
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#define kDEFAULT_FONT(n,s)     [UIFont fontWithName:n size:s]

//不同屏幕尺寸字体适配
#define kScreenWidthRatio  (UIScreen.mainScreen.bounds.size.width / 375.0)
#define kScreenHeightRatio (UIScreen.mainScreen.bounds.size.height / 667.0)
#define kAdaptedWidth(x)  ceilf((x) * kScreenWidthRatio)
#define kAdaptedHeight(x) ceilf((x) * kScreenHeightRatio)
#define kAdaptedFontSize(R) [UIFont systemFontOfSize:kAdaptedWidth(R)]
#define kAdaptedOtherFontSize(n,R) kDEFAULT_FONT(n,kAdaptedWidth(R))

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark ---------------> 创建返回按钮
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#define kCreatReturnButton(imageName,acttion)  UIButton *leftNavBtn = [UIButton buttonWithType:UIButtonTypeCustom];leftNavBtn.frame = CGRectMake(0, 0, 40, 40);[leftNavBtn setImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];[leftNavBtn addTarget:self action:@selector(acttion) forControlEvents:UIControlEventTouchUpInside];[self.navigationItem setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithCustomView:leftNavBtn]];
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark ---------------> 由角度转换弧度 由弧度转换角度
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#define PDegreesToRadian(x) (M_PI * (x) / 180.0)
#define PRadianToDegrees(radian) (radian*180.0)/(M_PI)
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark ---------------> 判断是否为空
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//字符串是否为空
#define kStringIsEmpty(str) ([str isKindOfClass:[NSNull class]] || str == nil || [str length] < 1 ? YES : NO )
//数组是否为空
#define kArrayIsEmpty(array) (array == nil || [array isKindOfClass:[NSNull class]] || array.count == 0)
//字典是否为空
#define kDictIsEmpty(dic) (dic == nil || [dic isKindOfClass:[NSNull class]] || dic.allKeys == 0)
//是否是空对象
#define kObjectIsEmpty(_object) (_object == nil \
|| [_object isKindOfClass:[NSNull class]] \
|| ([_object respondsToSelector:@selector(length)] && [(NSData *)_object length] == 0) \
|| ([_object respondsToSelector:@selector(count)] && [(NSArray *)_object count] == 0))
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

//SaveArea适配
#define  adjustsScrollViewInsets(scrollView)\
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
