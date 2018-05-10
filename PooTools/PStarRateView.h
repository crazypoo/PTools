//
//  PStarRateView.h
//  PTools
//
//  Created by MYX on 2017/4/19.
//  Copyright © 2017年 crazypoo. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PStarRateView;

typedef void (^PStarRateViewRateBlock)(PStarRateView *rateView, CGFloat newScorePercent);

@interface PStarRateView : UIView

@property (nonatomic, assign) CGFloat scorePercent;//得分值，范围为0--1，默认为1
@property (nonatomic, assign) BOOL hasAnimation;//是否允许动画，默认为NO
@property (nonatomic, assign) BOOL allowIncompleteStar;//评分时是否允许不是整星，默认为NO

- (instancetype)initWithFrame:(CGRect)frame rateBlock:(PStarRateViewRateBlock)block;
- (instancetype)initWithFrame:(CGRect)frame numberOfStars:(NSInteger)numberOfStars imageForeground:(UIImage *)fStr imageBackGround:(UIImage *)bStr withTap:(BOOL)yesORno rateBlock:(PStarRateViewRateBlock)block;

@end
