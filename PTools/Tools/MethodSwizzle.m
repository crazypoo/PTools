//
//  MethodSwizzle.m
//  XMNiao_Shop
//
//  Created by Notednog on 2016/10/14.
//  Copyright © 2016年 xnmiao.com. All rights reserved.
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
