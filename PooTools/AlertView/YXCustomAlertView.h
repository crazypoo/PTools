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

typedef NS_ENUM(NSUInteger, AlertAnimationType) {
    AlertAnimationTypeTop = 0,
    AlertAnimationTypeBottom,
    AlertAnimationTypeLeft,
    AlertAnimationTypeRight
};

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
 * @param w 界面宽度
 * @param title 标题i字符串
 * @param tf 标题字体(u有默认)
 * @param btns 按钮数组
 */
+(CGFloat)titleAndBottomViewNormalHeighEXAlertW:(CGFloat)w
                                      withTitle:(NSString *_Nonnull)title
                                  withTitleFont:(UIFont * _Nullable)tf
                                  withButtonArr:(NSArray *_Nonnull)btns;

/*! @brief 初始化View,带回调
 * @param superView 加载在哪里
 * @param title 标题
 * @param btFont 选择按钮字体
 * @param tColor 标题颜色
 * @param bbtColor 选择按钮字体颜色
 * @param vlColor 线颜色
 * @param mbtArray 选择按钮数组
 * @param aBGColor Alertview背景颜色
 * @param heightlightedColorColor 点击后背景颜色
 * @param tag tag
 * @param setViewBlock 设置自定义view
 * @param clickBlock 设置自定义view的点击回调
 * @param didDismissBlock 弹出框小时回调
 */
- (instancetype _Nonnull ) initAlertViewWithSuperView:(UIView * _Nonnull)superView
                                           alertTitle:(NSString * _Nullable)title
                               withButtonAndTitleFont:(UIFont * _Nullable)btFont
                                           titleColor:(UIColor * _Nullable)tColor
                               bottomButtonTitleColor:(NSArray <UIColor *>* _Nullable)bbtColor
                                         verLineColor:(UIColor * _Nullable)vlColor
                             alertViewBackgroundColor:(UIColor * _Nullable)aBGColor
                                   heightlightedColor:(UIColor * _Nullable)heightlightedColorColor
                                 moreButtonTitleArray:(NSArray * _Nonnull)mbtArray
                                              viewTag:(NSInteger)tag
                                        viewAnimation:(AlertAnimationType)animationType
                                      touchBackGround:(BOOL)canTouch
                                        setCustomView:(YXCustomAlertViewSetCustomViewBlock _Nonnull )setViewBlock
                                          clickAction:(YXCustomAlertViewClickBlock _Nonnull )clickBlock
                                      didDismissBlock:(YXCustomAlertViewDidDismissBlock _Nonnull )didDismissBlock;

/*! @brief AlertView消失
 */
- (void) dissMiss;
@end
