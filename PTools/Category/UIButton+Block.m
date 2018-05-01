//
//  UIButton+Block.m
//  OMCN
//
//  Created by 邓杰豪 on 16/6/8.
//  Copyright © 2016年 doudou. All rights reserved.
//

#import "UIButton+Block.h"
#import <objc/runtime.h>

static const void *UIButtonBlockKey = &UIButtonBlockKey;

@implementation UIButton (Block)
-(void)addActionHandler:(TouchedBlock)touchHandler{
    objc_setAssociatedObject(self, UIButtonBlockKey, touchHandler, OBJC_ASSOCIATION_COPY_NONATOMIC);
    [self addTarget:self action:@selector(actionTouched:) forControlEvents:UIControlEventTouchUpInside];
}
-(void)actionTouched:(UIButton *)btn{
    TouchedBlock block = objc_getAssociatedObject(self, UIButtonBlockKey);
    if (block) {
        block(btn.tag);
    }
}

+(instancetype)bs_creat
{
   return [UIButton buttonWithType:UIButtonTypeCustom];
}

-(void)bs_setTitle:(NSString *)titleStr
{
    [self setTitle:titleStr forState:UIControlStateNormal];
}

-(void)bs_setTitleColor:(UIColor *)color
{
    [self setTitleColor:color forState:UIControlStateNormal];
}

-(void)bs_setNormalImage:(UIImage *)image
{
    [self setImage:image forState:UIControlStateNormal];
}

-(void)bs_setSelectedImage:(UIImage *)image
{
    [self setImage:image forState:UIControlStateSelected];
}

-(void)bs_setTextAlignment:(NSTextAlignment)textAlignment
{
    self.titleLabel.textAlignment = textAlignment;
}

-(void)bs_setFont:(UIFont *)font
{
    self.titleLabel.font = font;
}
@end
