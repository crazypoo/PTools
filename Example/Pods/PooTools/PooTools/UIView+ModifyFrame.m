//
//  UIView+ModifyFrame.m
//
//  Created by Gavin He on 13-9-5.
//  Copyright (c) 2013年 Gavin He. All rights reserved.
//

#import "UIView+ModifyFrame.h"

@implementation UIView (ModifyFrame)

-(CGFloat) x {
    return self.frame.origin.x;
}

-(void) setX:(CGFloat) newX {
    CGRect frame = self.frame;
    frame.origin.x = newX;
    self.frame = frame;
}

-(CGFloat) y {
    return self.frame.origin.y;
}

-(void) setY:(CGFloat) newY {
    CGRect frame = self.frame;
    frame.origin.y = newY;
    self.frame = frame;
}

-(CGFloat) width {
    return self.frame.size.width;
}

-(void) setWidth:(CGFloat) newWidth {
    CGRect frame = self.frame;
    frame.size.width = newWidth;
    self.frame = frame;
}

-(CGFloat) height {
    return self.frame.size.height;
}

-(void) setHeight:(CGFloat) newHeight {
    CGRect frame = self.frame;
    frame.size.height = newHeight;
    self.frame = frame;
}

// gavin add
-(CGPoint) origin{
    return self.frame.origin;
}

-(void) setOrigin:(CGPoint) newOrigin{
    CGRect frame = self.frame;
    frame.origin.x = newOrigin.x;
    frame.origin.y = newOrigin.y;
    self.frame = frame;
}

-(CGSize) size{
    return self.frame.size;
}

-(void) setSize:(CGSize) newSize{
    CGRect frame = self.frame;
    frame.size.width = newSize.width;
    frame.size.height = newSize.height;
    self.frame = frame;
}

-(CGFloat) top{
    return self.frame.origin.y;
}

-(void) setTop:(CGFloat) newTop {
    CGRect frame = self.frame;
    frame.origin.y = newTop;
    self.frame = frame;
}


-(CGFloat) bottom{
    return self.frame.origin.y+self.frame.size.height;
}

-(void) setBottom:(CGFloat) newBottom {
    CGRect frame = self.frame;
    frame.origin.y = newBottom - frame.size.height;
    self.frame = frame;
}

- (CGFloat)left
{
    return self.frame.origin.x;
}

- (void)setLeft:(CGFloat)left
{
    CGRect frame = self.frame;
    frame.origin.x = left;
    self.frame = frame;
}

- (CGFloat)right
{
    return self.frame.origin.x + self.frame.size.width;
}

- (void)setRight:(CGFloat)right
{
    CGRect frame = self.frame;
    frame.origin.x = right - frame.size.width;
    self.frame = frame;
}


- (CGFloat)centerX {
    return self.center.x;
}

- (void)setCenterX:(CGFloat)centerX {
    self.center = CGPointMake(centerX, self.center.y);
}

- (CGFloat)centerY {
    return self.center.y;
}

- (void)setCenterY:(CGFloat)centerY {
    self.center = CGPointMake(self.center.x, centerY);
}


@end
