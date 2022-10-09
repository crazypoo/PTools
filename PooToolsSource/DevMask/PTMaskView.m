//
//  DOMaskView.m
//  Diou
//
//  Created by ken lam on 2021/6/22.
//  Copyright © 2021 DO. All rights reserved.
//

#import "PTMaskView.h"
#import <PooTools/Utils.h>
#import <Masonry/Masonry.h>

@implementation PTMaskView

-(instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {        
        NSBundle *path = [[NSBundle alloc] initWithPath:[[NSBundle bundleForClass:[self class]] pathForResource:@"PooTools" ofType:@"bundle"]];
        UIImage *image = [[UIImage alloc] initWithContentsOfFile:[path pathForResource:@"icon_clear" ofType:@"png"]];
        
        UIImageView *images = [[UIImageView alloc] init];
        [self addSubview:images];
        [images mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.top.bottom.equalTo(self);
        }];
                        
        images.image = [Utils getWaterMarkImage:image andTitle:@"测试模式-所有数据均为测试" andMarkFont:[UIFont systemFontOfSize:100] andMarkColor:[UIColor colorWithRed:1 green:1 blue:1 alpha:0.2]];
    }
    return self;
}

-(void)layoutSubviews
{
    [super layoutSubviews];
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    if (self.masked) return [super hitTest:point withEvent:event];
    for (UIView *view in self.subviews) {
        UIView *responder = [view hitTest:[view convertPoint:point fromView:self] withEvent:event];
        if (responder) return responder;
    }
    return nil;
}

@end
