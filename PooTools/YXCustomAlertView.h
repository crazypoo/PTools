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

@protocol YXCustomAlertViewDelegate <NSObject>

- (void) customAlertView:(YXCustomAlertView *) customAlertView clickedButtonAtIndex:(NSInteger)buttonIndex;
@optional
-(void)customAlertViewWasDismiss;
@end


@interface YXCustomAlertView : UIView

@property (nonatomic, copy) NSString *titleStr;

@property (nonatomic, strong) UIView *middleView;

@property(nonatomic, weak) id<YXCustomAlertViewDelegate> delegate;

@property (nonatomic, strong) UIView *customView;
/**
 * 弹窗在视图中的中心点
 **/
@property (nonatomic, assign) CGFloat centerY;

- (instancetype) initAlertViewWithFrame:(CGRect)frame andSuperView:(UIView *)superView withButtonAndTitleFont:(UIFont *)btFont titleColor:(UIColor * _Nonnull)tColor bottomButtonTitleColor:(UIColor * _Nullable)bbtColor verLineColor:(UIColor * _Nullable )vlColor moreButtonTitleArray:(NSArray * _Nonnull) mbtArray;

- (void) dissMiss;

@end
