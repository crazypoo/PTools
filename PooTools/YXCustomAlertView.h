//
//  YXCustomAlertView.h
//  YXCustomAlertView
//
//  Created by Houhua Yan on 16/7/12.
//  Copyright © 2016年 YanHouhua. All rights reserved.

//自定义的半透明弹窗

#import <UIKit/UIKit.h>

#define TitleViewH 35
#define BottomButtonH 42

@class YXCustomAlertView;

typedef void (^YXCustomAlertViewSetCustomViewBlock)(YXCustomAlertView *alertView);
typedef void (^YXCustomAlertViewClickBlock)(YXCustomAlertView *alertView, NSInteger buttonIndex);
typedef void (^YXCustomAlertViewDidDismissBlock)(YXCustomAlertView *alertView);

@interface YXCustomAlertView : UIView

@property (nonatomic, strong) UIView *middleView;

@property (nonatomic, strong) UIView *customView;

- (instancetype) initAlertViewWithFrame:(CGRect)frame andSuperView:(UIView *)superView alertTitle:(NSString *)title withButtonAndTitleFont:(UIFont *)btFont titleColor:(UIColor * _Nonnull)tColor bottomButtonTitleColor:(UIColor * _Nullable)bbtColor verLineColor:(UIColor * _Nullable )vlColor moreButtonTitleArray:(NSArray * _Nonnull) mbtArray viewTag:(NSInteger)tag setCustomView:(YXCustomAlertViewSetCustomViewBlock)setViewBlock clickAction:(YXCustomAlertViewClickBlock)clickBlock didDismissBlock:(YXCustomAlertViewDidDismissBlock)didDismissBlock;

- (void) dissMiss;
- (void) showView;
@end
