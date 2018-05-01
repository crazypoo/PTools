//
//  PooLoadingView.h
//  PooLoadingView
//
//  Created by crazypoo on 14-3-21.
//  Copyright (c) 2014年 鄧傑豪. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PooLoadingView : UIView

//默認線的寬度1.0f
@property (nonatomic, assign) CGFloat lineWidth;

//默認顔色[UIColor lightGrayColor]
@property (nonatomic, strong) UIColor *lineColor;

@property (nonatomic, readonly) BOOL isAnimating;

- (id)initWithFrame:(CGRect)frame;

- (void)startAnimation;
- (void)stopAnimation;

@end
