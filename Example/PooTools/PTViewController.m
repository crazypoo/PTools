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
#import "PBiologyID.h"
#import "PooSearchBar.h"


@interface PTViewController ()
@property (nonatomic, strong)PBiologyID *touchID;
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
    
//    PooSearchBar *searchBar = [[PooSearchBar alloc] initWithFrame:CGRectMake(0, 0, kSCREEN_WIDTH-200, 44)];
//    searchBar.barStyle     = UIBarStyleDefault;
//    searchBar.translucent  = YES;
////    searchBar.delegate     = self;
//    searchBar.keyboardType = UIKeyboardTypeDefault;
//    searchBar.searchPlaceholder = @"点击此处查找地市名字";
//    searchBar.searchPlaceholderColor = [UIColor lightGrayColor];
//    searchBar.searchPlaceholderFont = [UIFont systemFontOfSize:24];
//    searchBar.searchTextColor = kRandomColor;
//    //    searchBar.searchBarImage = kImageNamed(@"Search");
//    searchBar.searchTextFieldBackgroundColor = [UIColor whiteColor];
//    searchBar.searchBarOutViewColor = [UIColor whiteColor];
//    searchBar.searchBarTextFieldCornerRadius = 15;
//    [self.view addSubview:searchBar];

}

-(void)aaaaa
{
    self.touchID = [PBiologyID defaultBiologyID];
    self.touchID.biologyIDBlock = ^(BiologyIDType biologyIDType) {
        PNSLog(@"%ld",(long)biologyIDType);
    };
//    [self.touchID biologyAction];
//    kWeakSelf(self);
//    self.touchID = [PTouchID defaultTouchID];
//    [self.touchID keyboardAndTouchID];
//    self.touchID.touchIDBlock = ^(TouchIDStatus touchIDStatus) {
//        PNSLog(@"%d",touchIDStatus);
//        switch (touchIDStatus) {
//            case TouchIDStatusKeyboardTouchID:
//                [weakself.touchID keyboardAndTouchID];
//                break;
//
//            default:
//                break;
//        }
//    };
//    YXCustomAlertView *alert = [[YXCustomAlertView alloc] initAlertViewWithFrame:CGRectMake(10, 0, kSCREEN_WIDTH-20, 450) andSuperView:self.view centerY:kSCREEN_HEIGHT/2 alertTitle:@"1111231231231231231231231231" withButtonAndTitleFont:[UIFont systemFontOfSize:20] titleColor:kRandomColor bottomButtonTitleColor:kRandomColor verLineColor:kRandomColor moreButtonTitleArray:@[@"111",@"222",@"123123",@"31231412431241"] setCustomView:^(YXCustomAlertView *alert){
//        alert.customView.backgroundColor = kRandomColor;
//    } clickAction:^(YXCustomAlertView *alert, NSInteger buttonIndex) {
//        PNSLog(@"%ld>>>>>>%ld",(long)alert.tag,buttonIndex);
//        if (buttonIndex == 0) {
//            [alert dissMiss];
//        }
//    } didDismissBlock:^{
//        PNSLog(@"112312312314124124");
//
//    }];
//    alert.tag = 1;
//    [alert showView];
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
