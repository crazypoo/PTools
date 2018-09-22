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
