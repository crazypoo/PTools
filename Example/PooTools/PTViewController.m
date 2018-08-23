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
#import "ALActionSheetView.h"
#import "PooTagsLabel.h"
#import "PooSegView.h"
#import "PooNumberKeyBoard.h"
#import "YMShowImageView.h"
#import "PTAppDelegate.h"

#import <Masonry/Masonry.h>
#import <IQKeyboardManager/IQKeyboardManager.h>

#define FontName @"HelveticaNeue-Light"
#define FontNameBold @"HelveticaNeue-Medium"

#define APPFONT(R) kDEFAULT_FONT(FontName,kAdaptedWidth(R))


@interface PTViewController ()<PooNumberKeyBoardDelegate>
@property (nonatomic, strong)PBiologyID *touchID;
@property (nonatomic, strong)UITextField *textField;
@end

@implementation PTViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    self.view.backgroundColor = [UIColor whiteColor];
    
//    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
//    btn.frame = self.view.bounds;
//    [btn addTarget:self action:@selector(aaaaa) forControlEvents:UIControlEventTouchUpInside];
//    [self.view addSubview:btn];
    
//    PooNumberKeyBoard *userNameKeyboard = [PooNumberKeyBoard pooNumberKeyBoardWithDog:YES];
//    userNameKeyboard.delegate = self;
//
//    self.textField = [UITextField new];
//    self.textField.placeholder = @"11111";
//    self.textField.inputView = userNameKeyboard;
//    [self.view addSubview:self.textField];
//    [self.textField mas_makeConstraints:^(MASConstraintMaker *make) {
//        make.left.right.equalTo(self.view);
//        make.top.offset(64);
//        make.height.offset(30);
//    }];
    
    kAdaptedOtherFontSize(@"", 16);
    
//    PooSearchBar *searchBar = [PooSearchBar new];
//    searchBar.barStyle     = UIBarStyleDefault;
//    searchBar.translucent  = YES;
////    searchBar.delegate     = self;
//    searchBar.keyboardType = UIKeyboardTypeDefault;
//    searchBar.searchPlaceholder = @"点击此处查找地市名字";
//    searchBar.searchPlaceholderColor = kRandomColor;
//    searchBar.searchPlaceholderFont = [UIFont systemFontOfSize:24];
//    searchBar.searchTextColor = kRandomColor;
//    //    searchBar.searchBarImage = kImageNamed(@"Search");
//    searchBar.searchTextFieldBackgroundColor = kRandomColor;
//    searchBar.searchBarOutViewColor = kRandomColor;
//    searchBar.searchBarTextFieldCornerRadius = 15;
//    searchBar.cursorColor = kRandomColor;
//    [self.view addSubview:searchBar];
//    [searchBar mas_makeConstraints:^(MASConstraintMaker *make) {
//        make.left.right.top.equalTo(self.view);
//        make.height.offset(44);
//    }];
    
//    PooSegView *seg = [[PooSegView alloc] initWithTitles:@[@"1",@"2"] titleNormalColor:[UIColor lightGrayColor] titleSelectedColor:[UIColor redColor] titleFont:APPFONT(16) setLine:YES lineColor:[UIColor blackColor] lineWidth:1 selectedBackgroundColor:[UIColor yellowColor] normalBackgroundColor:[UIColor blueColor] showType:PooSegShowTypeUnderLine clickBlock:^(PooSegView *segViewView, NSInteger buttonIndex) {
//
//    }];
//    [self.view addSubview:seg];
//    [seg mas_makeConstraints:^(MASConstraintMaker *make) {
//        make.left.right.top.equalTo(self.view);
//        make.height.offset(44);
//    }];

    
    
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
    config.borderColor = kRandomColor;
    config.borderWidth = 2;
//
//    NSArray *normalImage = @[@"image_day_normal_7",@"image_day_normal_1",@"image_day_normal_2",@"image_day_normal_3",@"image_day_normal_4",@"image_day_normal_5",@"image_day_normal_6"];
//    NSArray *selectImage = @[@"image_day_select_7",@"image_day_select_1",@"image_day_select_2",@"image_day_select_3",@"image_day_select_4",@"image_day_select_5",@"image_day_select_6"];
    NSArray *title = @[@"7",@"1",@"2",@"3",@"4",@"5",@"6"];

    PooTagsLabel *tag = [[PooTagsLabel alloc] initWithFrame:CGRectMake(0, 100, kSCREEN_WIDTH, 0) tagsArray:title config:config wihtSection:0];
    tag.backgroundColor = kRandomColor;
    [self.view addSubview:tag];
    [tag mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.view);
        make.top.equalTo(self.view).offset(100);
    }];
}

-(void)aaaaa
{
//    PooShowImageModel *imageModel = [[PooShowImageModel alloc] init];
//    imageModel.imageUrl = @"http://p3.music.126.net/VDn1p3j4g2z4p16Gux969w==/2544269907756816.jpg";
//    imageModel.imageFullView = @"1";
//    imageModel.imageInfo = @"11111111241241241241928390128309128";
//    imageModel.imageTitle = @"22222212312312312312312312312";
//
//    PooShowImageModel *imageModel1 = [[PooShowImageModel alloc] init];
//    imageModel1.imageUrl = @"http://p3.music.126.net/VDn1p3j4g2z4p16Gux969w==/2544269907756816.jpg";
//    imageModel1.imageFullView = @"0";
//    imageModel1.imageInfo = @"444444";
//    imageModel1.imageTitle = @"333333";
//
//    PooShowImageModel *imageModel2 = [[PooShowImageModel alloc] init];
//    imageModel2.imageUrl = @"http://ww4.sinaimg.cn/bmiddle/677febf5gw1erma1g5xd0j20k0esa7wj.jpg";
//    imageModel2.imageFullView = @"0";
//    imageModel2.imageInfo = @"6666666";
//    imageModel2.imageTitle = @"5555555";
//
//    NSArray *arr = @[imageModel,imageModel1,imageModel2];
//
//    YMShowImageView *ymImageV = [[YMShowImageView alloc] initWithByClick:YMShowImageViewClickTagAppend appendArray:arr titleColor:[UIColor whiteColor] fontName:FontName currentPageIndicatorTintColor:[UIColor whiteColor] pageIndicatorTintColor:[UIColor grayColor] showImageBackgroundColor:[UIColor blackColor] showWindow:[PTAppDelegate appDelegate].window loadingImageName:@"DemoImage" deleteAble:YES saveAble:YES moreActionImageName:@"DemoImage"];
//    [ymImageV showWithFinish:^{
//        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
//    }];
//    [ymImageV mas_makeConstraints:^(MASConstraintMaker *make) {
//        make.left.right.top.bottom.equalTo([PTAppDelegate appDelegate].window);
//    }];
//    ALActionSheetView *actionSheet = [[ALActionSheetView alloc] initWithTitle:@"sjdhfjkshdfjkhsdjkfhsdjfhjksdhfjkshdfjkhsdjkfhjsdhfjsdfjshdjfkhskjdfhjksdhfjshdkjhjssjdhfjkshdfjkhsdjkfhsdjfhjksdhfjkshdfjkhsdjkfhjsdhfjsdfjshdjfkhskjdfhjksdhfjshdkjhjssjdhfjkshdfjkhsdjkfhsdjfhjksdhfjkshdfjkhsdjkfhjsdhfjsdfjshdjfkhskjdfhjksdhfjshdkjhjssjdhfjkshdfjkhsdjkfhsdjfhjksdhfjkshdfjkhsdjkfhjsdhfjsdfjshdjfkhskjdfhjksdhfjshdkjhjssjdhfjkshdfjkhsdjkfhsdjfhjksdhfjkshdfjkhsdjkfhjsdhfjsdfjshdjfkhskjdfhjksdhfjshdkjhjssjdhfjkshdfjkhsdjkfhsdjfhjksdhfjkshdfjkhsdjkfhjsdhfjsdfjshdjfkhskjdfhjksdhfjshdkjhjssjdhfjkshdfjkhsdjkfhsdjfhjksdhfjkshdfjkhsdjkfhjsdhfjsdfjshdjfkhskjdfhjksdhfjshdkjhjssjdhfjkshdfjkhsdjkfhsdjfhjksdhfjkshdfjkhsdjkfhjsdhfjsdfjshdjfkhskjdfhjksdhfjshdkjhjssjdhfjkshdfjkhsdjkfhsdjfhjksdhfjkshdfjkhsdjkfhjsdhfjsdfjshdjfkhskjdfhjksdhfjshdkjhjssjdhfjkshdfjkhsdjkfhsdjfhjksdhfjkshdfjkhsdjkfhjsdhfjsdfjshdjfkhskjdfhjksdhfjshdkjhjAAAAAAA" cancelButtonTitle:@"adasdasdasdad" destructiveButtonTitle:@"1231231231" otherButtonTitles:@[@"1231",@"1231",@"1231",@"1231",@"1231",@"1231",@"1231",@"1231",@"1231",@"1231",@"1231",@"1231",@"1231",@"1231",@"1231",@"1231",@"1231",@"1231",@"1231"] buttonFontName:FontName handler:^(ALActionSheetView *actionSheetView, NSInteger buttonIndex) {
//
//    }];
//    [actionSheet show];
    
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
    
//    YXCustomAlertView *alert = [[YXCustomAlertView alloc] initAlertViewWithSuperView:self.view alertTitle:@"111123123" withButtonAndTitleFont:[UIFont systemFontOfSize:20] titleColor:kRandomColor bottomButtonTitleColor:kRandomColor verLineColor:kRandomColor moreButtonTitleArray:@[@"111",@"222"] viewTag:1 setCustomView:^(YXCustomAlertView *alertView) {
//
//        UILabel *aaa = [UILabel new];
//        aaa.backgroundColor = kRandomColor;
//        aaa.text = @"1123123123123";
//        [alertView.customView addSubview:aaa];
//        [aaa mas_makeConstraints:^(MASConstraintMaker *make) {
//            make.left.right.top.bottom.equalTo(alertView.customView);
//        }];
//
//    } clickAction:^(YXCustomAlertView *alertView, NSInteger buttonIndex) {
//        switch (buttonIndex) {
//                case 0:
//            {
//                [alertView dissMiss];
//                alertView = nil;
//            }
//                break;
//             case 1:
//            {
//                [alertView dissMiss];
//                alertView = nil;
//            }
//                break;
//            default:
//                break;
//        }
//
//    } didDismissBlock:^(YXCustomAlertView *alertView) {
//
//    }];
//    [alert showView];
//    [alert mas_makeConstraints:^(MASConstraintMaker *make) {
////        make.left.top.equalTo(self.view).offset(10);
////        make.right.bottom.equalTo(self.view).offset(-10);
//        make.width.height.offset(250);
//        make.centerX.centerY.equalTo(self.view);
//    }];
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

#pragma mark ------> PooNumberKeyBoardDelegate
-(void)numberKeyboard:(PooNumberKeyBoard *)keyboard input:(NSString *)number
{
    self.textField.text = [self.textField.text stringByAppendingString:number];
}

-(void)numberKeyboardBackspace:(PooNumberKeyBoard *)keyboard
{
    if (self.textField.text.length != 0)
    {
        self.textField.text = [self.textField.text substringToIndex:self.textField.text.length -1];
    }
}

@end
