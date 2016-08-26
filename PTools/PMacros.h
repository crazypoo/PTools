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

//屏幕W&H
#define screenWidth [UIScreen mainScreen].bounds.size.width
#define screenHeight [UIScreen mainScreen].bounds.size.height
#define screenSize [UIScreen mainScreen].bounds.size
#define screenScale ([UIScreen mainScreen].scale)
#define KEYWINDOW [UIApplication sharedApplication].keyWindow


#define HEIGHT_NAV 44.0
#define HEIGHT_STATUS 20.0
#define HEIGHT_TABBAR 44.0

#define SCREEN_POINT (float)SCREEN_WIDTH/320.f
#define SCREEN_H_POINT (float)SCREEN_HEIGHT/480.f

//R屏
#define isRetina ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(640, 960), [[UIScreen mainScreen] currentMode].size) : NO)
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark ---------------> 通知中心
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#define PNotificationCenter [NSNotificationCenter defaultCenter]
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark ---------------> 颜色
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//随机颜色
#define RandomColor [UIColor colorWithRed:arc4random_uniform(256)/255.0 green:arc4random_uniform(256)/255.0 blue:arc4random_uniform(256)/255.0 alpha:1.0]
#define RandomColorWithAlpha(s) [UIColor colorWithRed:arc4random_uniform(256)/255.0 green:arc4random_uniform(256)/255.0 blue:arc4random_uniform(256)/255.0 alpha:s]

//设置RGB颜色/设置RGBA颜色
#define PRGBColor(r, g, b) [UIColor colorWithRed:(r)/255.0 green:(g)/255.0 blue:(b)/255.0 alpha:1.0]
#define PRGBAColor(r, g, b, a) [UIColor colorWithRed:(r)/255.0 green:(g)/255.0 blue:(b)/255.0 alpha:a]
// clear背景颜色
#define ClearColor [UIColor clearColor]

//16进制RGB的颜色转换
#define PColorFromHex(rgbValue) [UIColor \
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
#define PWeakSelf(type)  __weak typeof(type) weak##type = type;
#define PStrongSelf(type)  __strong typeof(type) type = weak##type;
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark ---------------> 设置 view 圆角和边框
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#define ViewBorderRadius(View, Radius, Width, Color)\
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
#define ReturnsToTheUpperLayer [self.navigationController popViewControllerAnimated:YES];
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark ---------------> 获取当前语言
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#define kCurrentLanguage ([[NSLocale preferredLanguages] objectAtIndex:0])
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark ---------------> ----------------------ABOUT IMAGE 图片 ----------------------------
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//LOAD LOCAL IMAGE FILE     读取本地图片
#define LOADIMAGE(file,ext) [UIImage imageWithContentsOfFile:[[NSBundle mainBundle]pathForResource:file ofType:ext]]
//DEFINE IMAGE      定义UIImage对象//    imgView.image = IMAGE(@"Default.png");
#define IMAGE(A) [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:A ofType:nil]]
//DEFINE IMAGE      定义UIImage对象
#define ImageNamed(_pointer) [UIImage imageNamed:[UIUtil imageName:_pointer]]
//BETTER USER THE FIRST TWO WAY, IT PERFORM WELL. 优先使用前两种宏定义,性能高于后面.
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark ---------------> 打印
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#define NSLog(format, ...) do {                                                                          \
fprintf(stderr, "<%s : %d> %s\n",                                           \
[[[NSString stringWithUTF8String:__FILE__] lastPathComponent] UTF8String],  \
__LINE__, __func__);                                                        \
(NSLog)((format), ##__VA_ARGS__);                                           \
fprintf(stderr, "我这里是打印,不要慌,我路过的😂😂😂😂😂😂😂😂😂😂😂😂\n");                                               \
} while (0)
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


#pragma mark ---------------> 存储对象
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#define UserDefaultSetObjectForKey(__VALUE__,__KEY__) \
{\
[[NSUserDefaults standardUserDefaults] setObject:__VALUE__ forKey:__KEY__];\
[[NSUserDefaults standardUserDefaults] synchronize];\
}

/**
 *  get the saved objects       获得存储的对象
 */
#define UserDefaultObjectForKey(__KEY__)  [[NSUserDefaults standardUserDefaults] objectForKey:__KEY__]

/**
 *  delete objects      删除对象
 */
#define UserDefaultRemoveObjectForKey(__KEY__) \
{\
[[NSUserDefaults standardUserDefaults] removeObjectForKey:__KEY__];\
[[NSUserDefaults standardUserDefaults] synchronize];\
}

#define PLIST_TICKET_INFO_EDIT [NSHomeDirectory() stringByAppendingString:@"/Documents/data.plist"] //edit the plist
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark ---------------> TABLEVIEW
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#define TableViewCellDequeueInit(__INDETIFIER__) [tableView dequeueReusableCellWithIdentifier:(__INDETIFIER__)];

#define TableViewCellDequeue(__CELL__,__CELLCLASS__,__INDETIFIER__) \
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
#define GCDWithGlobal(block) dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), block)
#define GCDWithMain(block) dispatch_async(dispatch_get_main_queue(),block)
//GCD - 一次性执行
#define kDISPATCH_ONCE_BLOCK(onceBlock) static dispatch_once_t onceToken; dispatch_once(&onceToken, onceBlock);
//GCD - 在Main线程上运行
#define kDISPATCH_MAIN_THREAD(mainQueueBlock) dispatch_async(dispatch_get_main_queue(), mainQueueBlock);
//GCD - 开启异步线程
#define kDISPATCH_GLOBAL_QUEUE_DEFAULT(globalQueueBlock) dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), globalQueueBlocl);
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
#define DEFAULT_FONT(n,s)     [UIFont fontWithName:n size:s]
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark ---------------> 创建返回按钮
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#define CreatReturnButton(imageName,acttion)  UIButton *leftNavBtn = [UIButton buttonWithType:UIButtonTypeCustom];leftNavBtn.frame = CGRectMake(0, 0, 40, 40);[leftNavBtn setImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];[leftNavBtn addTarget:self action:@selector(acttion) forControlEvents:UIControlEventTouchUpInside];[self.navigationItem setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithCustomView:leftNavBtn]];
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
