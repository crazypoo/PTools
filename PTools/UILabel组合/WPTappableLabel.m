//
//  WPTappableLabel.m
//  WPAttributedMarkupDemo
//
//  Created by Nigel Grange on 20/10/2014.
//  Copyright (c) 2014 Nigel Grange. All rights reserved.
//

#import "WPTappableLabel.h"

@implementation WPTappableLabel

-(void)setOnTap:(void (^)(CGPoint))onTap
{
    _onTap = onTap;
    UITapGestureRecognizer* tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapped:)];
    [self addGestureRecognizer:tapGesture];
    self.userInteractionEnabled = YES;
}

-(void)tapped:(UITapGestureRecognizer*)gesture
{
    if (gesture.state == UIGestureRecognizerStateRecognized) {
        CGPoint pt = [gesture locationInView:self];
        if (self.onTap) {
            self.onTap(pt);
        }
    }
}

@end

// 版权属于原作者
// http://code4app.com (cn) http://code4app.net (en)
// 发布代码于最专业的源码分享网站: Code4App.com 
