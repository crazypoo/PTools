//
//  PooLoadingView.h
//  PooLoadingView
//
//  Created by crazypoo on 14-3-21.
//  Copyright (c) 2014年 鄧傑豪. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PooLoadingView : UIView

/*! @brief Loading的线宽度 (默認1.0f)
 */
@property (nonatomic, assign) CGFloat lineWidth;

/*! @brief Loading的线颜色 (默認[UIColor lightGrayColor])
 */
@property (nonatomic, strong) UIColor *lineColor;

/*! @brief 是否开启动画
 */
@property (nonatomic, readonly) BOOL isAnimating;

- (id)initWithFrame:(CGRect)frame;

/*! @brief 展示
 */
- (void)startAnimation;

/*! @brief 关闭
 */
- (void)stopAnimation;

@end
