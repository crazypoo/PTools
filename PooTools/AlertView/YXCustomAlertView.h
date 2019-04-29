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

typedef void (^YXCustomAlertViewSetCustomViewBlock)(YXCustomAlertView * _Nonnull alertView);
typedef void (^YXCustomAlertViewClickBlock)(YXCustomAlertView * _Nonnull alertView, NSInteger buttonIndex);
typedef void (^YXCustomAlertViewDidDismissBlock)(YXCustomAlertView * _Nonnull alertView);

@interface YXCustomAlertView : UIView

/*! @brief AlertView透明背景View
 */
@property (nonatomic, strong, nullable) UIView *middleView;

/*! @brief AlertView内容View
 */
@property (nonatomic, strong, nullable) UIView *customView;

/*! @brief AlertView默认Title加底部按钮高度
 */
+(CGFloat)titleAndBottomViewNormalH;

/*! @brief 初始化View,带回调
 */
- (instancetype _Nonnull ) initAlertViewWithSuperView:(UIView * _Nonnull)superView
                                           alertTitle:(NSString * _Nullable)title
                               withButtonAndTitleFont:(UIFont * _Nullable)btFont
                                           titleColor:(UIColor * _Nullable)tColor
                               bottomButtonTitleColor:(UIColor * _Nullable)bbtColor
                                         verLineColor:(UIColor * _Nullable)vlColor
                                 moreButtonTitleArray:(NSArray * _Nonnull) mbtArray
                                              viewTag:(NSInteger)tag
                                        setCustomView:(YXCustomAlertViewSetCustomViewBlock _Nonnull )setViewBlock
                                          clickAction:(YXCustomAlertViewClickBlock _Nonnull )clickBlock
                                      didDismissBlock:(YXCustomAlertViewDidDismissBlock _Nonnull )didDismissBlock;

/*! @brief AlertView消失
 */
- (void) dissMiss;
@end
