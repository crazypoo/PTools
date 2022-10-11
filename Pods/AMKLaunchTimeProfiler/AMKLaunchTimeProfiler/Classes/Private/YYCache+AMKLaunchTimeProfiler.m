//
//  YYCache+AMKLaunchTimeProfiler.m
//  AMKLaunchTimeProfiler
//
//  Created by mengxinxin on 2022/5/9.
//

#import "YYCache+AMKLaunchTimeProfiler.h"
#import "AMKLaunchTimeProfilerConstants.h"

@implementation YYCache (AMKLaunchTimeProfiler)

#pragma mark - Init Methods

#pragma mark - Getters & Setters

+ (YYCache *)amkltp_sharedInstance {
    static YYCache *sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [YYCache cacheWithName:@"AMKLaunchTimeProfiler"];
        //sharedInstance.diskCache.countLimit = sharedInstance.memoryCache.countLimit = 10000; // 最大缓存数据个数
        //sharedInstance.diskCache.costLimit = sharedInstance.memoryCache.costLimit = 10*1024; // 最大缓存开销
    });
    return sharedInstance;
}

#pragma mark - Data & Networking

#pragma mark - Public Methods

#pragma mark - Private Methods

#pragma mark - Notifications

#pragma mark - KVO

#pragma mark - Protocol

#pragma mark - Overrides

#pragma mark - Helper Methods

@end
