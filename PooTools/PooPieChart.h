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
-(instancetype)initWithFrame:(CGRect)frame lineFontName:(UIFont *)lName centerLabelFont:(UIFont *)cFont;
//数据数组
@property (strong, nonatomic) NSArray *dataArray;
//标题
@property (copy, nonatomic) NSString *title;
//绘制方法
- (void)draw;
@property (nonatomic, copy) void(^touchBlock)(PooPieChart *button,NSInteger index);
@end

@interface RadiusRange : NSObject
@property (nonatomic, assign) CGFloat start;
@property (nonatomic, assign)  CGFloat end;
@end

@interface PooPieCenterView : UIView
- (instancetype)initWithFrame:(CGRect)frame centerLabelFont:(UIFont *)cFont;
@property (strong, nonatomic) UILabel *nameLabel;
@property (strong, nonatomic) UIView *centerView;
@end

@interface PooPieViewModel : NSObject
//名称
@property (copy, nonatomic) NSString *name;
//数值
@property (copy, nonatomic) NSString *value;
//颜色
@property (nonatomic ,strong) UIColor *color;
@end
