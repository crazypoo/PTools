//
//  PLabel.h
//  adasdasdadadasdasdadadadad
//
//  Created by MYX on 2017/4/18.
//  Copyright © 2017年 邓杰豪. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum
{
    VerticalAlignmentTop = 0,
    VerticalAlignmentMiddle,
    VerticalAlignmentBottom,
} VerticalAlignment;

typedef enum
{
    StrikeThroughAlignmentTop = 0,
    StrikeThroughAlignmentMiddle,
    StrikeThroughAlignmentBottom,
} StrikeThroughAlignment;

@interface PLabel : UILabel

/*! @brief 设置展示样式 (综合设置)
 */
- (void)setVerticalAlignment:(VerticalAlignment)verticalAlignment
      strikeThroughAlignment:(StrikeThroughAlignment)strikeThroughAlignment
     setStrikeThroughEnabled:(BOOL)strikeThroughEnabled;
/*! @brief 文字展示样式
 */
@property (nonatomic) VerticalAlignment verticalAlignment;
/*! @brief 画线穿过样式
 */
@property (nonatomic) StrikeThroughAlignment strikeThroughAlignment;
/*! @brief 是否展示画线
 */
@property (assign, nonatomic) BOOL strikeThroughEnabled;
/*! @brief 画线颜色
 */
@property (strong, nonatomic) UIColor *strikeThroughColor;
@end
