//
//  PooSegView.h
//  ddddddd
//
//  Created by 邓杰豪 on 15/8/11.
//  Copyright (c) 2015年 邓杰豪. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PooSegView;
@protocol PooSegViewDelegate <NSObject>
- (void)didSelectedSegmentWith:(PooSegView *)seg AtIndex:(NSInteger)index;
@end

@interface PooSegView : UIView
-(id)initWithFrame:(CGRect)frame titles:(NSArray *)titleArr titleNormalColor:(UIColor *)nColor titleSelectedColor:(UIColor *)sColor titleFont:(UIFont *)tFont setLine:(BOOL)yesORno lineColor:(UIColor *)lColor lineWidth:(float)lWidth;
@property (nonatomic, weak) id<PooSegViewDelegate> delegate;
@end
