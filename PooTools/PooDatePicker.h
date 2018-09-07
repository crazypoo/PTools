//
//  PooDatePicker.h
//  LandloardTool
//
//  Created by mouth on 2018/5/8.
//  Copyright © 2018年 邓杰豪. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PooDatePicker : UIView

/*! @brief 日期Picker初始化
 * @param title 标题
 * @param tbbc tabbar的背景颜色
 * @param font 字体
 * @param tbtc tabbar上的字体颜色
 * @param pf picker的字体
 */
- (instancetype)initWithTitle:(NSString *)title
       toolBarBackgroundColor:(UIColor *)tbbc
                    labelFont:(UIFont *)font
            toolBarTitleColor:(UIColor *)tbtc
                   pickerFont:(UIFont *)pf;

/*! @brief 选取回调
 */
@property (nonatomic, copy) void (^block)(NSString *);
@end
