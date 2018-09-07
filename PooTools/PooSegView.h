//
//  PooSegView.h
//  ddddddd
//
//  Created by 邓杰豪 on 15/8/11.
//  Copyright (c) 2015年 邓杰豪. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger,PooSegShowType){
    PooSegShowTypeNormal = 0,
    PooSegShowTypeUnderLine
};

@class PooSegView;

typedef void (^PooSegViewClickBlock)(PooSegView *segViewView, NSInteger buttonIndex);

@interface PooSegView : UIView

/*! @brief 分段选择器初始化
 * @param titleArr 标题数组
 * @param nColor 普通标题颜色
 * @param sColor 选中标题颜色
 * @param tFont 标题字体
 * @param yesORno 是否有线
 * @param lColor 线的颜色
 * @param lWidth 线的粗细
 * @param sbc 选中背景颜色
 * @param nbc 未选中背景颜色
 * @param viewType 展示样式
 * @param block 点击回调
 */
-(id)initWithTitles:(NSArray *)titleArr
   titleNormalColor:(UIColor *)nColor
 titleSelectedColor:(UIColor *)sColor
          titleFont:(UIFont *)tFont
            setLine:(BOOL)yesORno
          lineColor:(UIColor *)lColor
          lineWidth:(float)lWidth
selectedBackgroundColor:(UIColor *)sbc
normalBackgroundColor:(UIColor *)nbc
           showType:(PooSegShowType)viewType
         clickBlock:(PooSegViewClickBlock)block;
@end
