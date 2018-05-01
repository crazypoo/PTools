//
//  PooAlerView.m
//  PooAlerView
//
//  Created by crazypoo on 14-4-2.
//  Copyright (c) 2014年 crazypoo. All rights reserved.
//

#import "PooAlertView.h"
#import "UIView+ModifyFrame.h"

@interface PooAlertView()<PooAlertViewDelegate>
{
    UIView *parentView;
    UIView *containerView;
}
@end

static const int DefaultOffset = 60;
static const float AnimationTime = 0.3f;
@implementation PooAlertView

@synthesize dialogView,buttonTitleColorNormal,buttonTitleColorSelected;
@synthesize delegate;
@synthesize buttonTitles;
@synthesize closeButton;

CGFloat static defaultButtonHeight = 44;
CGFloat static defaultButtonSpacerHeight = 1;
CGFloat static cornerRadius = 7;

CGFloat pButtonHeight = 0;
CGFloat pButtonSpacerHeight = 0;

- (id)initWithParentView: (UIView *)_parentView
{
    self = [super initWithFrame:_parentView.frame];
    if (self) {
        parentView = _parentView;
        delegate = self;
        buttonTitles = [NSMutableArray arrayWithObject:@"取消"];
        buttonTitleColorNormal = [NSMutableArray arrayWithObject:[UIColor colorWithRed:0.0f green:0.5f blue:1.0f alpha:1.0f]];
        buttonTitleColorSelected = [NSMutableArray arrayWithObject:[UIColor colorWithRed:0.2f green:0.2f blue:0.2f alpha:0.5f]];
        self.containerViewHeight = 150;
    }
    return self;
}

- (void)show
{
    dialogView = [self createContainerView];
    
    dialogView.layer.opacity = 0.5f;
    dialogView.layer.transform = CATransform3DMakeScale(1.3f, 1.3f, 1.0);
    
    self.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0];
    
    [self addSubview:dialogView];
    [parentView addSubview:self];
    
    [UIView animateWithDuration:0.2f delay:0.0 options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         self.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.4f];
                         dialogView.layer.opacity = 1.0f;
                         dialogView.layer.transform = CATransform3DMakeScale(1, 1, 1);
                     }
                     completion:NULL
     ];
}

- (void)setDelegate: (id)_delegate
{
    delegate = _delegate;
}

- (void)pooAlertViewButtonTouchUpInside:(UIButton *)sender
{
    [delegate pooAlertViewButtonTouchUpInside:self clickedButtonAtIndex:sender.tag];
}

- (void)pooAlertViewButtonTouchUpInside:(PooAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSLog(@"Button Clicked! %ld, %ld", (long)buttonIndex, (long)[alertView tag]);
    [self close];
}

- (void)close
{
    dialogView.layer.transform = CATransform3DMakeScale(1, 1, 1);
    dialogView.layer.opacity = 1.0f;
    
    [UIView animateWithDuration:0.2f delay:0.0 options:UIViewAnimationOptionTransitionNone
                     animations:^{
                         self.backgroundColor = [UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:0.0f];
                         dialogView.layer.transform = CATransform3DMakeScale(0.6f, 0.6f, 1.0);
                         dialogView.layer.opacity = 0.0f;
                     }
                     completion:^(BOOL finished) {
                         for (UIView *v in [self subviews]) {
                             [v removeFromSuperview];
                         }
                         [self removeFromSuperview];
                     }
     ];
}

- (void)setSubView: (UIView *)subView
{
    containerView = subView;
}

- (UIView *)createContainerView
{
    if ([buttonTitles count] > 0) {
        pButtonHeight = defaultButtonHeight;
        pButtonSpacerHeight = defaultButtonSpacerHeight;
    } else {
        pButtonHeight = 0;
        pButtonSpacerHeight = 0;
    }
    
    if (containerView == NULL) {
        containerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 300, self.containerViewHeight)];
    }
    
    CGFloat dialogWidth = containerView.frame.size.width;
    CGFloat dialogHeight = containerView.frame.size.height + pButtonHeight + pButtonSpacerHeight;
    
    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;
    
    UIDeviceOrientation deviceOrientation = [[UIDevice currentDevice] orientation];
    if (UIDeviceOrientationIsLandscape(deviceOrientation)) {
        CGFloat tmp = screenWidth;
        screenWidth = screenHeight;
        screenHeight = tmp;
    }
    
    [self setFrame:CGRectMake(0, 0, screenWidth, screenHeight)];
    
    UIView *dialogContainer = [[UIView alloc] initWithFrame:CGRectMake((screenWidth - dialogWidth) / 2, (screenHeight - dialogHeight) / 2, dialogWidth, dialogHeight)];
    
    
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = dialogContainer.bounds;
    gradient.colors = [NSArray arrayWithObjects:
                       (id)[[UIColor colorWithRed:218.0/255.0 green:218.0/255.0 blue:218.0/255.0 alpha:1.0f] CGColor],
                       (id)[[UIColor colorWithRed:233.0/255.0 green:233.0/255.0 blue:233.0/255.0 alpha:1.0f] CGColor],
                       (id)[[UIColor colorWithRed:218.0/255.0 green:218.0/255.0 blue:218.0/255.0 alpha:1.0f] CGColor],
                       nil];
    gradient.cornerRadius = cornerRadius;
    [dialogContainer.layer insertSublayer:gradient atIndex:0];
    
    dialogContainer.layer.cornerRadius = cornerRadius;
    dialogContainer.layer.borderColor = [[UIColor colorWithRed:198.0/255.0 green:198.0/255.0 blue:198.0/255.0 alpha:1.0f] CGColor];
    dialogContainer.layer.borderWidth = 1;
    dialogContainer.layer.shadowRadius = cornerRadius + 5;
    dialogContainer.layer.shadowOpacity = 0.1f;
    dialogContainer.layer.shadowOffset = CGSizeMake(0 - (cornerRadius+5)/2, 0 - (cornerRadius+5)/2);
    
    UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(0, dialogContainer.bounds.size.height - pButtonHeight - pButtonSpacerHeight, dialogContainer.bounds.size.width, pButtonSpacerHeight)];
    lineView.backgroundColor = [UIColor colorWithRed:198.0/255.0 green:198.0/255.0 blue:198.0/255.0 alpha:1.0f];
    [dialogContainer addSubview:lineView];
    
    [dialogContainer addSubview:containerView];
    
    [self addButtonsToView:dialogContainer];
    
    return dialogContainer;
}

- (void)addButtonsToView: (UIView *)container
{
    CGFloat buttonWidth = container.bounds.size.width / [buttonTitles count];
    
    for (int i=0; i<[buttonTitles count]; i++) {
        
        closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        
        [closeButton setFrame:CGRectMake(i * buttonWidth, container.bounds.size.height - pButtonHeight, buttonWidth, pButtonHeight)];
        [closeButton setTag:i];
        [closeButton addTarget:self action:@selector(pooAlertViewButtonTouchUpInside:) forControlEvents:UIControlEventTouchUpInside];
        [closeButton setTitle:[buttonTitles objectAtIndex:i] forState:UIControlStateNormal];
        [closeButton setTitleColor:buttonTitleColorNormal[i] forState:UIControlStateNormal];
        [closeButton setTitleColor:buttonTitleColorSelected[i] forState:UIControlStateHighlighted];
        [closeButton.titleLabel setFont:[UIFont boldSystemFontOfSize:16.0f]];
        [closeButton.layer setCornerRadius:cornerRadius];
        
        [container addSubview:closeButton];
    }
    
}


- (void)pooAlertViewMoveOffset{
    [UIView animateWithDuration:AnimationTime animations:^{
        dialogView.y = dialogView.y - DefaultOffset;
    }];
    
}
- (void)pooAlertViewResetOffset{
    [UIView animateWithDuration:AnimationTime animations:^{
        dialogView.y = dialogView.y + DefaultOffset;
    }];
}

- (void)pooAlertViewShake{
    CAKeyframeAnimation *anim = [CAKeyframeAnimation animationWithKeyPath:@"transform.translation.x"];
    anim.repeatCount = 1;
    anim.values = @[@-20, @20, @-20];
    [self.dialogView.layer addAnimation:anim forKey:nil];
}

@end
