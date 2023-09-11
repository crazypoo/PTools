//
//  fix_UIKeyboardTaskQueue.m
//  PooTools_Example
//
//  Created by 邓杰豪 on 12/9/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

#ifdef __arm64__

#import <UIKit/UIKit.h>
#include <objc/runtime.h>

@interface fix_UIKeyboardTaskQueue : NSObject
@end

@implementation fix_UIKeyboardTaskQueue
+ (void)load {
    extern BOOL fix_UIKeyboardTaskQueue_tryLockWhenReadyForMainThread(id self, SEL selector);
    if (@available(iOS 16.0, *)) {
        NSString *systemVersion = [[UIDevice currentDevice] systemVersion];
        NSArray *verInfos = [systemVersion componentsSeparatedByString:@"."];
        NSUInteger count = [verInfos count];
        if (count >= 2) {
            if ([verInfos[0] isEqualToString:@"16"]) {
                class_replaceMethod(objc_getClass("UIKeyboardTaskQueue"), sel_getUid("tryLockWhenReadyForMainThread"), (IMP)fix_UIKeyboardTaskQueue_tryLockWhenReadyForMainThread, "B16@0:8");
            }
        }
    }
}
@end
#endif
