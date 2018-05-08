//
//  PooDatePicker.h
//  LandloardTool
//
//  Created by mouth on 2018/5/8.
//  Copyright © 2018年 邓杰豪. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PooDatePicker : UIView
- (instancetype)initWithTitle:(NSString *)title toolBarBackgroundColor:(UIColor *)tbbc labelFont:(UIFont *)font toolBarTitleColor:(UIColor *)tbtc pickerFont:(UIFont *)pf;
@property (nonatomic, copy) void (^block)(NSString *);
@end
