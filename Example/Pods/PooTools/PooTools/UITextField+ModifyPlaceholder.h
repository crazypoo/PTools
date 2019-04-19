//
//  UITextField+ModifyPlaceholder.h
//  PooTools_Example
//
//  Created by 邓杰豪 on 2018/9/25.
//  Copyright © 2018年 crazypoo. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UITextField (ModifyPlaceholder)

/*! @brief 自定义PlaceHolder的颜色,位置,文字大小,文字设置
 * @attention 使用此方法时,必须要先实现系统的xxxxx.placeholder = @"xxxx",才能根据kvo去实现此方法
 */
@property (nonatomic, strong)UILabel *UI_PlaceholderLabel;

@end
