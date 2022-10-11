//
//  AMKLaunchTimeProfilerConstants.m
//  AMKLaunchTimeProfiler
//
//  Created by mengxinxin on 2022/3/22.
//

#import "AMKLaunchTimeProfilerConstants.h"
#import "AMKLaunchTimeProfiler.h"
#import "AMKLaunchTimeProfiler+Private.h"

#pragma mark - 相关变量定义

Class AMKLaunchTimeProfilerApplicationDelegateClass;

NSString * _Nonnull const AMKLaunchTimeProfilerBundleId = @"io.github.andym129.amk-launch-time-profiler";
NSString * _Nonnull const AMKLaunchTimeProfilerErrorDomain = @"io.github.andym129.amk-launch-time-profiler.error";
NSString * _Nonnull const AMKLaunchTimeProfilerVersion = @"1.0.0";
NSString * _Nonnull const AMKLaunchTimeProfilerAlertControllerTitle = @"AMKLaunchTimeProfiler\n——  APP冷启动耗时分析  ——";
NSString * _Nonnull const AMKLaunchTimeProfilersCacheKey = @"profilers";

#pragma mark - 相关通知定义

AMKLaunchTimeProfilerNotificationName const AMKLaunchTimeProfilerApplicationDidFinishLaunchingNotification = @"AMKLaunchTimeProfilerApplicationDidFinishLaunchingNotification";
AMKLaunchTimeProfilerNotificationName const AMKLaunchTimeProfilerFirstScreenDidDisplayNotification = @"AMKLaunchTimeProfilerFirstScreenDidDisplayNotification";

#pragma mark - 相关函数定义
