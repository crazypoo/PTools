//
//  YYCache+AMKLaunchTimeProfiler.h
//  AMKLaunchTimeProfiler
//
//  Created by mengxinxin on 2022/5/9.
//

#import <YYCache/YYCache.h>

@interface YYCache (AMKLaunchTimeProfiler)

/// 单例
+ (YYCache *_Nonnull)amkltp_sharedInstance;

@end
