//
//  UIView+ViewRectCorner.h
//  PooTools_Example
//
//  Created by 邓杰豪 on 2018/9/25.
//  Copyright © 2018年 crazypoo. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (ViewRectCorner)


/*! @brief 圆角半径 (默认5)
*/
@property(nonatomic,assign)CGFloat viewUI_rectCornerRadii;

/*! @brief 圆角方位
 */
@property(nonatomic,assign)UIRectCorner viewUI_rectCorner;


@end
