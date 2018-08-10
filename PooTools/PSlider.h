//
//  PSlider.h
//  CloudGateWorker
//
//  Created by 邓杰豪 on 2018/8/10.
//  Copyright © 2018年 邓杰豪. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger,PSliderStyle){
    PSliderStyleTop = 0,
    PSliderStyleBottom
};

@interface PSlider : UISlider

/*! @brief 是否展示TitleLabel
 */
@property (nonatomic,assign) BOOL isShowTitle;

/*! @brief TitleLabel展示风格
 */
@property (nonatomic,assign) PSliderStyle titleStyle;

/*! @brief TitleLabel展示颜色
 */
@property (nonatomic,strong) UIColor *titleColor;

/*! @brief TitleLabel展示字体
 */
@property (nonatomic,strong) UIFont *titleFont;

@end
