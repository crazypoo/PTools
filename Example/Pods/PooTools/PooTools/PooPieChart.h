//
//  PooPieChart.h
//  CloudGateCustom
//
//  Created by 邓杰豪 on 26/4/2018.
//  Copyright © 2018年 邓杰豪. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PMacros.h"
#import "UIView+ModifyFrame.h"

@interface PooPieChart : UIView
/*! @brief 初始化PieView
 * @param frame 大小位置
 * @param lName 界面的字体
 * @param cFont 中间label的字体
 */
-(instancetype)initWithFrame:(CGRect)frame
                lineFontName:(UIFont *)lName
             centerLabelFont:(UIFont *)cFont;
/*! @brief PieView的数据
 */
@property (strong, nonatomic) NSArray *dataArray;
/*! @brief PieView的标题
 */
@property (copy, nonatomic) NSString *title;
/*! @brief PieView的绘制
 */
- (void)draw;
/*! @brief PieView的某一块点击回调
 */
@property (nonatomic, copy) void(^touchBlock)(PooPieChart *button,NSInteger index);
@end

@interface RadiusRange : NSObject
@property (nonatomic, assign) CGFloat start;
@property (nonatomic, assign)  CGFloat end;
@end

@interface PooPieCenterView : UIView
/*! @brief 初始化PieView的centerView的父视图
 * @param frame 大小位置
 * @param cFont label的字体
 */
- (instancetype)initWithFrame:(CGRect)frame
              centerLabelFont:(UIFont *)cFont;

/*! @brief CenterView的文字视图
 */
@property (strong, nonatomic) UILabel *nameLabel;
/*! @brief CenterView的子主要视图
 */
@property (strong, nonatomic) UIView *centerView;
@end

@interface PooPieViewModel : NSObject
/*! @brief 名字
 */
@property (copy, nonatomic) NSString *name;
/*! @brief 数值
 */
@property (copy, nonatomic) NSString *value;
/*! @brief 颜色
 */
@property (nonatomic ,strong) UIColor *color;
@end
