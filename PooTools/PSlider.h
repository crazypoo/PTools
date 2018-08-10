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

@property (nonatomic,assign) BOOL isShowTitle;
@property (nonatomic,assign) PSliderStyle titleStyle;
@property (nonatomic,strong) UIColor *titleColor;
@property (nonatomic,strong) UIFont *titleFont;

@end
