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

/*! @brief AlertView透明背景View
 */
@property (nonatomic, strong) UIView *middleView;

/*! @brief AlertView内容View
 */
@property (nonatomic, strong) UIView *customView;

/*! @brief AlertView默认Title加底部按钮高度
 */
+(CGFloat)titleAndBottomViewNormalH;

/*! @brief 初始化View,带回调
 */
- (instancetype) initAlertViewWithSuperView:(UIView *)superView
                                 alertTitle:(NSString *)title
                     withButtonAndTitleFont:(UIFont *)btFont
                                 titleColor:(UIColor * _Nonnull)tColor
                     bottomButtonTitleColor:(UIColor * _Nullable)bbtColor
                               verLineColor:(UIColor * _Nullable )vlColor
                       moreButtonTitleArray:(NSArray * _Nonnull) mbtArray
                                    viewTag:(NSInteger)tag
                              setCustomView:(YXCustomAlertViewSetCustomViewBlock)setViewBlock
                                clickAction:(YXCustomAlertViewClickBlock)clickBlock
                            didDismissBlock:(YXCustomAlertViewDidDismissBlock)didDismissBlock;

/*! @brief AlertView消失
 */
- (void) dissMiss;
@end
