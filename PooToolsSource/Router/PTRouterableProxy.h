//
//  PTRouterableProxy.h
//  PooTools
//
//  Created by 邓杰豪 on 2/11/25.
//  Copyright © 2025 crazypoo. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_OPTIONS(NSUInteger, PTRouterPriority) {
    PTRouterPriorityLow = 1000,
    PTRouterPriorityDefault = 1001,
    PTRouterPriorityHeight = 1002
};

NS_ASSUME_NONNULL_BEGIN

@protocol PTRouterableProxy <NSObject>

// 使用类方法替代静态属性
+ (NSArray<NSString *> *)patternString;

@optional
+ (NSUInteger)priority;

@end

NS_ASSUME_NONNULL_END
