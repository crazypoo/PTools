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

/*! @brief 得分值，范围为0--1，默认为1
 */
@property (nonatomic, assign) CGFloat scorePercent;
/*! @brief 是否允许动画，默认为NO
 */
@property (nonatomic, assign) BOOL hasAnimation;
/*! @brief 评分时是否允许不是整星，默认为NO
 */
@property (nonatomic, assign) BOOL allowIncompleteStar;

/*! @brief 初始化 (默认5个选择框,已选是红色,未选是蓝色)
 */
- (instancetype)initWithRateBlock:(PStarRateViewRateBlock)block;

/*! @brief 初始化 (自定义)
 * @param numberOfStars 评分最大分数
 * @param fStr 已选评分图片
 * @param bStr 未选评分图片
 * @param yesORno 是否可以点击
 * @return block 点评分数回调
 */
- (instancetype)initWithNumberOfStars:(NSInteger)numberOfStars
                      imageForeground:(UIImage *)fStr
                      imageBackGround:(UIImage *)bStr
                              withTap:(BOOL)yesORno
                            rateBlock:(PStarRateViewRateBlock)block;

@end
