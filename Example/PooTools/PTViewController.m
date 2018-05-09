//
//  PTViewController.m
//  PooTools
//
//  Created by crazypoo on 05/01/2018.
//  Copyright (c) 2018 crazypoo. All rights reserved.
//

#import "PTViewController.h"
#import "Utils.h"
#import "YXCustomAlertView.h"
#import "PMacros.h"


@interface PTViewController ()<YXCustomAlertViewDelegate>

@end

@implementation PTViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame = self.view.bounds;
    [btn addTarget:self action:@selector(aaaaa) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
}

-(void)aaaaa
{
    YXCustomAlertView *alert = [[YXCustomAlertView alloc] initAlertViewWithFrame:CGRectMake(10, 0, kSCREEN_WIDTH-20, 450) andSuperView:self.view withButtonAndTitleFont:[UIFont systemFontOfSize:20] titleColor:kRandomColor bottomButtonTitleColor:kRandomColor verLineColor:kRandomColor moreButtonTitleArray:@[@"111",@"222",@"123123",@"31231412431241"]];
    alert.center = CGPointMake(kSCREEN_WIDTH/2, kSCREEN_HEIGHT/2);
    alert.delegate = self;
    alert.titleStr = @"111123123123123";
}

#pragma mark - YXCustomAlertViewDelegate
-(void)customAlertView:(YXCustomAlertView *)customAlertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    PNSLog(@"%ld",(long)buttonIndex);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
