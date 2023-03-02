//
//  MethodSwizzle.m
//  PooTools_Example
//
//  Created by 邓杰豪 on 3/3/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

void MethodSwizzle(Class aClass, SEL orig_sel, SEL alt_sel) {
    Method orig_method = nil, alt_method = nil;
    orig_method = class_getInstanceMethod(aClass, orig_sel);
    alt_method = class_getInstanceMethod(aClass, alt_sel);
    if ((orig_method != nil) && (alt_method != nil)) {
        IMP originIMP = method_getImplementation(orig_method);
        IMP altIMP = method_setImplementation(alt_method, originIMP);
        method_setImplementation(orig_method, altIMP);
    }
}
