//
//  UITextField+ModifyPlaceholder.m
//  PooTools_Example
//
//  Created by 邓杰豪 on 2018/9/25.
//  Copyright © 2018年 crazypoo. All rights reserved.
//

#import "UITextField+ModifyPlaceholder.h"
#import <objc/runtime.h>

static NSString * const ksystemPlaceholderLabel = @"_placeholderLabel";

@implementation UITextField (ModifyPlaceholder)

-(void)setUI_PlaceholderLabel:(UILabel *)UI_PlaceholderLabel
{
    [self willChangeValueForKey:ksystemPlaceholderLabel];
    objc_setAssociatedObject(self, &ksystemPlaceholderLabel,
                             UI_PlaceholderLabel,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self didChangeValueForKey:ksystemPlaceholderLabel];
}

- (UILabel *)UI_PlaceholderLabel
{
    UILabel *label = (UILabel *)[self valueForKeyPath:ksystemPlaceholderLabel];
    return label;
}


@end
