//
//  UIImage+UIColorEX.h
//  PooTools_Example
//
//  Created by 邓杰豪 on 2018/12/15.
//  Copyright © 2018年 crazypoo. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIImage (UIColorEX)

/*! @brief 获取图片的主色调
 */
-(UIColor *)imageMostColor;

@end

NS_ASSUME_NONNULL_END
