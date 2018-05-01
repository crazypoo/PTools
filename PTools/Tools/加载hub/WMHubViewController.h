//
//  WMHubViewController.h
//  Dagongzai
//
//  Created by crazypoo on 14/11/5.
//  Copyright (c) 2014年 Pactera. All rights reserved.
//


#import <UIKit/UIKit.h>

#import "WMHubView.h"

@interface WMHubViewController : UIViewController

@property (nonatomic, strong) NSArray *hudColors;
@property (nonatomic, strong) UIColor *hudBackgroundColor;
@property (nonatomic, assign) CGFloat hudLineWidth;

- (void)hide:(void (^)(void))completion;

@end
