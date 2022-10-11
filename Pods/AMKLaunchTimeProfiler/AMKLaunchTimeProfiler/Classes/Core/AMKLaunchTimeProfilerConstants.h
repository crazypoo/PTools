//
//  AMKLaunchTimeProfilerConstants.h
//  AMKLaunchTimeProfiler
//
//  Created by mengxinxin on 2022/3/22.
//

#import <UIKit/UIKit.h>
@class AMKLaunchTimeProfiler;

#pragma mark - 相关变量定义

/// 组件包名
UIKIT_EXTERN NSString * _Nonnull const AMKLaunchTimeProfilerBundleId;

/// 组件 ErrorDomain
UIKIT_EXTERN NSString * _Nonnull const AMKLaunchTimeProfilerErrorDomain;

/// 组件版本号
UIKIT_EXTERN NSString * _Nonnull const AMKLaunchTimeProfilerVersion;

/// 弹窗标题
UIKIT_EXTERN NSString * _Nonnull const AMKLaunchTimeProfilerAlertControllerTitle;

/// 缓存Key
UIKIT_EXTERN NSString * _Nonnull const AMKLaunchTimeProfilersCacheKey;

/// 主题色
#define AMKLaunchTimeProfilerTintColor [UIColor colorWithRed:70/255.0 green:74/255.0 blue:250/255.0 alpha:1.0]

#pragma mark - 相关通知定义

/// 冷启动耗时分析通知
typedef NSString *_Nonnull AMKLaunchTimeProfilerNotificationName NS_EXTENSIBLE_STRING_ENUM;

/// 冷启动耗时分析通知：APP完成加载
FOUNDATION_EXPORT AMKLaunchTimeProfilerNotificationName const AMKLaunchTimeProfilerApplicationDidFinishLaunchingNotification;

/// 冷启动耗时分析通知：首屏完成显示
FOUNDATION_EXPORT AMKLaunchTimeProfilerNotificationName const AMKLaunchTimeProfilerFirstScreenDidDisplayNotification;

#pragma mark - 相关函数定义

/// 打印日志
#define AMKLaunchTimeProfilerLog(FORMAT, ...) \
[AMKLaunchTimeProfiler.sharedInstance logWithFunction:__FUNCTION__ line:__LINE__ string:FORMAT, ##__VA_ARGS__]

/// 打印日志 - @"开始..."
#define AMKLaunchTimeProfilerLogBegin(FORMAT, ...) \
[AMKLaunchTimeProfiler.sharedInstance logWithFunction:__FUNCTION__ line:__LINE__ string:@"开始..." FORMAT, ##__VA_ARGS__]

/// 打印日志 - @"结束"
#define AMKLaunchTimeProfilerLogEnd(FORMAT, ...) \
[AMKLaunchTimeProfiler.sharedInstance logWithFunction:__FUNCTION__ line:__LINE__ string:@"结束" FORMAT, ##__VA_ARGS__]

/// 打印日志 - 内部日志
#define AMKLaunchTimeProfilerInternalLog(FORMAT, ...) \
[AMKLaunchTimeProfiler.sharedInstance logWithFunction:0 line:0 string:FORMAT, ##__VA_ARGS__]

/// 打印日志 - 相同位置 只打一次
#define AMKLaunchTimeProfilerOnceLog(FORMAT, ...) \
{ static dispatch_once_t onceToken; dispatch_once(&onceToken, ^{[AMKLaunchTimeProfiler.sharedInstance logWithFunction:__FUNCTION__ line:__LINE__ string:FORMAT, ##__VA_ARGS__];}); }

/// 打印日志 - 相同位置 只打一次 - @"开始..."
#define AMKLaunchTimeProfilerOnceLogBegin(FORMAT, ...) \
{ static dispatch_once_t onceToken; dispatch_once(&onceToken, ^{[AMKLaunchTimeProfiler.sharedInstance logWithFunction:__FUNCTION__ line:__LINE__ string:@"开始..." FORMAT, ##__VA_ARGS__];}); }

/// 打印日志 - 相同位置 只打一次 - @"结束"
#define AMKLaunchTimeProfilerOnceLogEnd(FORMAT, ...) \
{ static dispatch_once_t onceToken; dispatch_once(&onceToken, ^{[AMKLaunchTimeProfiler.sharedInstance logWithFunction:__FUNCTION__ line:__LINE__ string:@"结束" FORMAT, ##__VA_ARGS__];}); }

#pragma mark - 其他

#define AMKSharedLaunchTimeProfiler AMKLaunchTimeProfiler.sharedInstance
