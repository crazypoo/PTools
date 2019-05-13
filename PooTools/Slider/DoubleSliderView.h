//
//  DoubleSliderView.h
//  DoubleSliderView-OC
//
//  Created by 杜奎 on 2019/1/13.
//  Copyright © 2019 DU. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void (^SliderReturnUserVaule)(CGFloat minVaule, CGFloat maxVaule);;

@interface DoubleSliderView : UIView

/*! @brief 当前最小的值
 */
@property (nonatomic, assign) CGFloat curMinValue;
/*! @brief 当前最大的值
 */
@property (nonatomic, assign) CGFloat curMaxValue;
/*! @brief 是否需要动画
 */
@property (nonatomic, assign) BOOL needAnimation;
/*! @brief 间隔大小
 */
@property (nonatomic, assign) CGFloat minInterval;
/*! @brief 滑块位置改变后的回调 isLeft 是否是左边 finish手势是否结束
 */
@property (nonatomic, copy)   void (^sliderBtnLocationChangeBlock)(BOOL isLeft, BOOL finish);
/*! @brief 最小值Tint颜色
 */
@property (nonatomic, strong) UIColor *minTintColor;
/*! @brief 中间值Tint颜色
 */
@property (nonatomic, strong) UIColor *midTintColor;
/*! @brief 最大值Tint颜色
 */
@property (nonatomic, strong) UIColor *maxTintColor;
/*! @brief 最小值Slider颜色
 */
@property (nonatomic, strong) UIColor *minSliderColor;
/*! @brief 最大值Slider颜色
 */
@property (nonatomic, strong) UIColor *maxSliderColor;

/*! @brief 改变数值
 */
- (void)changeLocationFromValue;

/*! @brief 设置Slider值
 * @param minV 设置最小值
 * @param maxV 设置最大值
 * @param block 选项值回调
 */
- (void)setViewValueMin:(CGFloat)minV
                    max:(CGFloat)maxV
                 handle:(SliderReturnUserVaule)block;
/*! @brief 重置
 */
- (void)resetView;
@end

