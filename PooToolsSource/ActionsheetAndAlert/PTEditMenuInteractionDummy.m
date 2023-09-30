//
//  PTEditMenuInteractionDummy.m
//  PooTools_Example
//
//  Created by 邓杰豪 on 30/9/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

#import "PTEditMenuInteractionDummy.h"

@interface PTEditMenuInteractionDummy ()
@property(nonatomic, copy) NSSet<NSString *> *actions;
@property(nonatomic, strong) void (^callback)(SEL);
@end

@implementation PTEditMenuInteractionDummy
+ (instancetype)dummyWithActionCallback:(void (^)(SEL))callback {
    NSParameterAssert(callback);
    return [[PTEditMenuInteractionDummy alloc] initWithCallback:callback];
}

- (instancetype)initWithCallback:(void (^)(SEL))callback {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        _actions = [NSSet set];
        _callback = callback;
    }
    return self;
}

- (void)updateActions:(NSSet<NSString *> *)actions {
    if (!actions) return;
    self.actions = actions;
}

- (BOOL)isSelectorSupported:(SEL)selector {
    BOOL supported = NO;
    for (NSString *actionStr in self.actions) {
        SEL supportedAction = NSSelectorFromString(actionStr);
        if (supportedAction == selector) {
            supported = YES;
            break;
        }
    }
    return supported;
}

+ (void)fake {
}

#pragma mark override
- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    return [self isSelectorSupported:action];
}

- (void)forwardInvocation:(NSInvocation *)anInvocation {
    if ([self isSelectorSupported:anInvocation.selector]) {
        self.callback(anInvocation.selector);
    }
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
    return [PTEditMenuInteractionDummy methodSignatureForSelector:@selector(fake)];
}

@end

