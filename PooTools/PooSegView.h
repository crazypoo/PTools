//
//  PooSegView.h
//  ddddddd
//
//  Created by 邓杰豪 on 15/8/11.
//  Copyright (c) 2015年 邓杰豪. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PooSegView;

typedef void (^PooSegViewClickBlock)(PooSegView *segViewView, NSInteger buttonIndex);

@interface PooSegView : UIView
-(id)initWithFrame:(CGRect)frame titles:(NSArray *)titleArr titleNormalColor:(UIColor *)nColor titleSelectedColor:(UIColor *)sColor titleFont:(UIFont *)tFont setLine:(BOOL)yesORno lineColor:(UIColor *)lColor lineWidth:(float)lWidth clickBlock:(PooSegViewClickBlock)block;
@end
