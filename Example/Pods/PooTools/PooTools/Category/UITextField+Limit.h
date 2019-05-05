//
//  UITextField+Limit.h
//  PooTools_Example
//
//  Created by 邓杰豪 on 2018/10/20.
//  Copyright © 2018年 crazypoo. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef BOOL(^BNConditionBlock)(NSString* inputStr);
@interface UITextField (Limit)

- (void)limitNums:(NSInteger)num action:(void(^)(void))action;

- (void)limitCondition:(BNConditionBlock)condition action:(void (^)(void))action;

- (void)setPlaceholder:(NSString *)placeholder color:(UIColor*)color font:(UIFont*)font;

@end
