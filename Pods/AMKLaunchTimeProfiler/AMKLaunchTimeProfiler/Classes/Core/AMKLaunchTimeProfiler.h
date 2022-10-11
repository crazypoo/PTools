//
//  AMKLaunchTimeProfiler.h
//  AMKLaunchTimeProfiler
//
//  Created by mengxinxin on 2022/3/22.
//

#import <Foundation/Foundation.h>
#import <AMKLaunchTimeProfiler/AMKLaunchTimeProfilerConstants.h>
#import <AMKLaunchTimeProfiler/AMKLaunchTimeProfilerLogsViewController.h>

/// APP启动耗时分析
///
/// Xcode13上统计启动时长的变量 DYLD_PRINT_STATISTICS 失效了，故需要自行计算
/// 核心实现参考：https://juejin.cn/post/7070679654566199333/
@interface AMKLaunchTimeProfiler : NSObject <NSCoding, NSCopying>

#pragma mark - 全局设置

/// 当前的  启动耗时分析的 调试开关，默认NO
@property(nonatomic, assign, readwrite, class) BOOL debugEnable;

/// 当前的  启动耗时分析的 日志是否被停止记录，默认NO，当执行 [AMKLaunchTimeProfiler clearAllLogs] 时会修改为 YES
@property(nonatomic, assign, readonly, class) BOOL logDisabled;

/// 当前的  启动耗时分析的 日志最多保存多少组，默认30
@property(nonatomic, assign, readwrite, class) NSUInteger maxCountOfProfilers;

/// 邮件发送的收件人
@property(nonatomic, strong, readwrite, nullable, class) NSArray<NSString *> *mailRecipients;

#pragma mark - 当前实例

/// 单例
@property(nonatomic, strong, readonly, nonnull, class) AMKLaunchTimeProfiler *sharedInstance;

/// 当前的 启动耗时分析的 Id
@property(nonatomic, strong, readonly, nonnull) NSString *identifier;

/// 当前的  启动耗时分析的 版本号
@property(nonatomic, strong, readonly, nonnull) NSString *version;

#pragma mark - APP信息

/// 当前工程的 bundleName
@property(nonatomic, strong, readonly, nonnull) NSString *bundleName;

/// 当前工程的 BundleId
@property(nonatomic, strong, readonly, nonnull) NSString *bundleId;

/// 当前工程的 ShortVersion
@property(nonatomic, strong, readonly, nonnull) NSString *bundleShortVersion;

/// 当前工程的 BundleVersion
@property(nonatomic, strong, readonly, nonnull) NSString *bundleVersion;

/// 当前工程的 ClientVersion
@property(nonatomic, strong, readonly, nonnull) NSString *clientVersion;

/// 当前的 DeviceVersion
@property(nonatomic, strong, readonly, nonnull) NSString *deviceVersion;

/// 当前的 DeviceName
@property(nonatomic, strong, readonly, nonnull) NSString *deviceName;

#pragma mark - 启动耗时信息

/// 创建进程的时间点
@property(nonatomic, assign, readonly) NSTimeInterval processStartTime;

/// 执行 main() 函数的时间点
@property(nonatomic, assign, readonly) NSTimeInterval mainTime;

/// 执行 [AppDelegate -application: didFinishLaunchingWithOptions:] 方法的时间点
@property(nonatomic, assign, readonly) NSTimeInterval didFinishLaunchingTime;

/// 执行 [AppDelegate.window.rootViewController -viewDidAppear:] 方法的时间点
@property(nonatomic, assign, readonly) NSTimeInterval firstScreenTime;

/// 阶段一 耗时：pre-main，指的是从用户唤起 App 到 main 函数执行之前的过程，即 mainTime - processStartTime 的差值
///
/// - 装载APP的可执行文件
/// - 递归加载所有依赖的动态库
/// - 调用map_images进行可执行文件内容的解析和处理
/// - 在load_images中调用call_load_methods,调用所有的Class和Category的 + load方法
/// - 进行各种objc结构初始化（注册Objec类、初始化类对象等等）
/// - 调用C++ 静态初始化器和 _attribute_((constructor))修饰函数
@property(nonatomic, assign, readonly) NSTimeInterval preMainTimeConsuming;

/// 阶段二 耗时：main，指的是从 Application 初始化到 applicationDidFinishLaunchingWithOptions 执行完，即 didFinishLaunchingTime - mainTime 的差值
///
/// - main()
/// - UIApplicationMain()
/// - AppDelegate的application: didFinishLaunchingWithOptions:方法
@property(nonatomic, assign, readonly) NSTimeInterval mainTimeConsuming;

/// 阶段三 耗时：首页渲染，指的是 初始化帧渲染到 viewDidAppear 执行完，即 firstScreenTime - didFinishLaunchingTime 的耗时
///
/// - 相关业务组件初始化
/// - 基础信息数据同步，首页数据请求
/// - 广告，弹层，一些第三方业务，等
@property(nonatomic, assign, readonly) NSTimeInterval firstScreenTimeConsuming;

/// 总耗时，即 firstScreenTime - processStartTime 的差值
@property(nonatomic, assign, readonly) NSTimeInterval totalTimeConsuming;

/// 清空所有logs
+ (void)clearAllLogs;

/// 清空本次启动的所有logs
- (void)clearAllLogs;

/// 自定义log，推荐使用 AMKLaunchTimeProfilerLog(FORMAT, ...)
- (void)logWithFunction:(const char *_Nullable)function line:(NSInteger)line string:(NSString *_Nullable)format, ...;

/// APP启动耗时分析描述
- (NSString *_Nullable)description;

/// APP启动耗时分析描述 - 会高亮显示 timeDelta>=50ms 的日志
- (NSMutableAttributedString *_Nullable)attributedDescription;

@end


#pragma mark - 启动耗时统计信息

@interface AMKLaunchTimeProfiler (Statistics)
@property(nonatomic, assign, readonly, class) NSInteger profilerCount;
@property(nonatomic, assign, readonly, class) NSTimeInterval preMainTimeConsuming;
@property(nonatomic, assign, readonly, class) NSTimeInterval mainTimeConsuming;
@property(nonatomic, assign, readonly, class) NSTimeInterval firstScreenTimeConsuming;
@property(nonatomic, assign, readonly, class) NSTimeInterval totalTimeConsuming;
@end
