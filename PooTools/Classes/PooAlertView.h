//
//  PooAlerView.h
//  PooAlerView
//
//  Created by crazypoo on 14-4-2.
//  Copyright (c) 2014年 crazypoo. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol PooAlertViewDelegate;

@interface PooAlertView : UIView

@property (nonatomic, retain) UIView *dialogView;
@property (nonatomic, assign) id<PooAlertViewDelegate> delegate;
@property (nonatomic, retain) UIButton *closeButton;
@property (nonatomic, assign) CGFloat containerViewHeight;
//添加标题数组，颜色也必定要添加
@property (nonatomic, retain) NSMutableArray *buttonTitles;
@property (nonatomic, strong) NSMutableArray *buttonTitleColorNormal;
@property (nonatomic, strong) NSMutableArray *buttonTitleColorSelected;

- (id)initWithParentView: (UIView *)_parentView;
- (void)show;
- (void)close;
- (void)setButtonTitles: (NSMutableArray *)buttonTitles;
- (void)pooAlertViewButtonTouchUpInside:(UIButton *)sender;
- (void)pooAlertViewMoveOffset;
- (void)pooAlertViewResetOffset;
- (void)pooAlertViewShake;

@end

@protocol PooAlertViewDelegate <NSObject>

-(void)pooAlertViewButtonTouchUpInside:(PooAlertView*)alertView clickedButtonAtIndex:(NSInteger)index;

@end
