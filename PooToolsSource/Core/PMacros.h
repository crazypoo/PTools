//
//  PHong.h
//  PTools
//
//  Created by crazypoo on 14/9/14.
//  Copyright (c) 2014年 crazypoo. All rights reserved.
//

#ifndef PTools_PMacros_h
#define PTools_PMacros_h

#define kDevLikeFont @"HelveticaNeue-Light"
#define kDevLikeFont_Bold @"HelveticaNeue-Medium"

#define kDevAlpha 0.45
#define kDevMaskBackgroundColor kRGBAColorDecimals(0, 0, 0, kDevAlpha)
#define kDevButtonHighlightedColor kRGBAColor(242, 242, 242, 1)

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
#define HEIGHT_NAV 44.f
/*! @brief 横屏nav高度
 */
#define HEIGHT_NAV_LandSpaceLeftOrRight 32.f
/*! @brief status高度 (iPhoneX除外)
 */
#define HEIGHT_STATUS ([PTUtils oc_isiPhoneSeries] ? 44.f : 20.f)
/*! @brief 普通导航栏高度 (nav高度+status高度)
 */
#define HEIGHT_NAVBAR HEIGHT_NAV + HEIGHT_STATUS
/*! @brief tabbara安全区域高度
 */
#define HEIGHT_TABBAR_SAFEAREA ([PTUtils oc_isiPhoneSeries] ? 34.f : 0.f)
/*! @brief tabbar高度
 */
#define HEIGHT_TABBAR 49.0f
/*! @brief tabbar总高度
 */
#define HEIGHT_TABBAR_TOTAL (HEIGHT_TABBAR + HEIGHT_TABBAR_SAFEAREA)
/*! @brief NAV+TAB总高度
 */
#define HEIGHT_NAVPLUSTABBAR_TOTAL (HEIGHT_TABBAR_TOTAL + HEIGHT_NAVBAR)
/*! @brief 大标题高度
 */
#define HEIGHT_LARGETITLE 52.f
/*! @brief iPhone带大标题高度
 */
#define HEIGHT_IPHONESTATUSBARXNAVXLARGETITLE HEIGHT_STATUS + HEIGHT_NAV + HEIGHT_LARGETITLE

/*! @brief Picker一般高度
 */
#define HEIGHT_PICKER 216.f
/*! @brief PickerToolBar一般高度
 */
#define HEIGHT_PICKERTOOLBAR 44.f
/*! @brief Button一般高度
 */
#define HEIGHT_BUTTON 44.f

/*! @brief PS字号转换成iOS字号
 */
#define kPSFontToiOSFont(pixel) (pixel*3/4)

/*! @brief 设置View的tag属性
 */
#define kVIEWWITHTAG(_OBJECT, _TAG) [_OBJECT viewWithTag : _TAG]

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

#pragma mark ---------------> 弱引用/强引用
/*! @brief 弱引用
 */
#define kWeakSelf(type)  __weak typeof(type) weak##type = type;
/*! @brief 强引用
 */
#define kStrongSelf(type)  __strong typeof(type) type = weak##type;

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

#pragma mark ---------------> 打印
/*! @brief 强化NSLog
 */
#define PNSLog(format, ...) do {fprintf(stderr, "%s:%d\t%s\n", [[[NSString stringWithUTF8String: __FILE__] lastPathComponent] UTF8String], __LINE__, [[NSString stringWithFormat: format, ## __VA_ARGS__] UTF8String]);fprintf(stderr, "我这里是打印,不要慌,我路过的😂😂😂😂😂😂😂😂😂😂😂😂\n");}while (0)

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
#endif

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

#pragma mark ---------------> 由角度转换弧度 由弧度转换角度
/*! @brief 角度转弧度
 */
#define PDegreesToRadian(x) (M_PI * (x) / 180.0)
/*! @brief 弧度转角度
 */
#define PRadianToDegrees(radian) (radian*180.0)/(M_PI)
