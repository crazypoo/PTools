//
//  UIView+ModifyFrame.h
//
//  Created by Gavin on 19/2/14.
//

/*
 
 Before:
 CGRect frame = myView.frame;
 frame.origin.x = newX;
 myView.frame = frame;
 
 After:
 myView.x = newX;
 
 */

#import <UIKit/UIKit.h>

@interface UIView (Ext)

@property CGFloat x;
@property CGFloat y;
@property CGFloat width;
@property CGFloat height;

@property CGPoint origin;
@property CGSize size;


- (CGFloat) top;
- (void) setTop:(CGFloat) newTop;

- (CGFloat) bottom;
- (void) setBottom:(CGFloat) newBottom ;

- (CGFloat)left;
- (void)setLeft:(CGFloat)left;

- (CGFloat)right;
- (void)setRight:(CGFloat)right;


- (CGFloat)centerX;
- (void)setCenterX:(CGFloat)centerX;

- (CGFloat)centerY;
- (void)setCenterY:(CGFloat)centerY;

@end
