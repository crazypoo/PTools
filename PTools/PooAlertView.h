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

@property (nonatomic, retain) UIView *parentView;
@property (nonatomic, retain) UIView *dialogView;
@property (nonatomic, retain) UIView *containerView;
@property (nonatomic, retain) UIView *buttonView;
@property (nonatomic, assign) id<PooAlertViewDelegate> delegate;
@property (nonatomic, retain) NSMutableArray *buttonTitles;
@property (nonatomic, retain) UIButton *closeButton;

- (id)initWithParentView: (UIView *)_parentView;
- (void)show;
- (void)close;
- (void)setButtonTitles: (NSMutableArray *)buttonTitles;
- (void)pooAlertViewButtonTouchUpInside:(id)sender;
- (void)pooAlertViewMoveOffset;
- (void)pooAlertViewResetOffset;
- (void)pooAlertViewShake;

@end

@protocol PooAlertViewDelegate <NSObject>

-(void)pooAlertViewButtonTouchUpInside:(PooAlertView*)alertView clickedButtonAtIndex:(int)index;

@end
