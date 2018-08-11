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
#import "PooDatePicker.h"

#import "PooTagsLabel.h"

#import <Masonry/Masonry.h>

#define FontName @"HelveticaNeue-Light"
#define FontNameBold @"HelveticaNeue-Medium"

#define APPFONT(R) kDEFAULT_FONT(FontName,kAdaptedWidth(R))


@interface PTViewController ()
@property (nonatomic, strong)PBiologyID *touchID;
@end

@implementation PTViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame = self.view.bounds;
    [btn addTarget:self action:@selector(aaaaa) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
    
    kAdaptedOtherFontSize(@"", 16);
    
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
    
    NSArray *titleS = @[@"7"];

    PooTagsLabelConfig *config = [[PooTagsLabelConfig alloc] init];
    config.itemHeight = 50;
    config.itemHerMargin = 10;
    config.itemVerMargin = 10;
    config.hasBorder = YES;
    config.topBottomSpace = 5.0;
    config.itemContentEdgs = 20;
    config.isCanSelected = YES;
    config.isCanCancelSelected = YES;
    config.isMulti = YES;
    config.selectedDefaultTags = titleS;
    config.borderColor = [UIColor clearColor];
    config.borderWidth = 0;
    
    NSArray *normalImage = @[@"image_day_normal_7",@"image_day_normal_1",@"image_day_normal_2",@"image_day_normal_3",@"image_day_normal_4",@"image_day_normal_5",@"image_day_normal_6"];
    NSArray *selectImage = @[@"image_day_select_7",@"image_day_select_1",@"image_day_select_2",@"image_day_select_3",@"image_day_select_4",@"image_day_select_5",@"image_day_select_6"];
    NSArray *title = @[@"7",@"1",@"2",@"3",@"4",@"5",@"6"];

    PooTagsLabel *tag = [[PooTagsLabel alloc] initWithFrame:CGRectMake(0, 100, kSCREEN_WIDTH, 0) tagsNormalArray:normalImage tagsSelectArray:selectImage tagsTitleArray:title config:config wihtSection:0];
    [self.view addSubview:tag];
}

-(void)aaaaa
{
//    self.touchID = [PBiologyID defaultBiologyID];
//    self.touchID.biologyIDBlock = ^(BiologyIDType biologyIDType) {
//        PNSLog(@"%ld",(long)biologyIDType);
//    };
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
    
    YXCustomAlertView *alert = [[YXCustomAlertView alloc] initAlertViewWithSuperView:self.view alertTitle:@"111123123" withButtonAndTitleFont:[UIFont systemFontOfSize:20] titleColor:kRandomColor bottomButtonTitleColor:kRandomColor verLineColor:kRandomColor moreButtonTitleArray:@[@"111",@"222"] viewTag:1 setCustomView:^(YXCustomAlertView *alertView) {

    } clickAction:^(YXCustomAlertView *alertView, NSInteger buttonIndex) {
        switch (buttonIndex) {
                case 0:
            {
                [alertView dissMiss];
                alertView = nil;
            }
                break;
             case 1:
            {
                [alertView dissMiss];
                alertView = nil;
            }
                break;
            default:
                break;
        }

    } didDismissBlock:^(YXCustomAlertView *alertView) {

    }];
    [alert showView];
    [alert mas_makeConstraints:^(MASConstraintMaker *make) {
//        make.left.top.equalTo(self.view).offset(10);
//        make.right.bottom.equalTo(self.view).offset(-10);
        make.width.height.offset(250);
        make.centerX.centerY.equalTo(self.view);
    }];
//    [Utils alertVCWithTitle:@"123123" message:@"2123" cancelTitle:@"2" okTitle:@"1" otherButtonArrow:nil shouIn:self alertStyle:UIAlertControllerStyleActionSheet
//                   okAction:^{
//
//                   } cancelAction:^{
//
//                   } otherButtonAction:^(NSInteger aaaaaaaaaa) {
//                       PNSLog(@"%ld",(long)aaaaaaaaaa);
//                   }];
//    PooDatePicker *view = [[PooDatePicker alloc] initWithTitle:@"1111" toolBarBackgroundColor:kRandomColor labelFont:APPFONT(16) toolBarTitleColor:kRandomColor pickerFont:APPFONT(16)];
//    [self.view addSubview:view];
//    [view mas_makeConstraints:^(MASConstraintMaker *make) {
//        make.left.right.top.bottom.equalTo(self.view);
//    }];
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
