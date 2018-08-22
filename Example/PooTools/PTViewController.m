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
#import "UIButton+Block.h"

#import <Masonry/Masonry.h>
#import <IQKeyboardManager/IQKeyboardManager.h>

#define FontName @"HelveticaNeue-Light"
#define FontNameBold @"HelveticaNeue-Medium"

#define APPFONT(R) kDEFAULT_FONT(FontName,kAdaptedWidth(R))


@interface PTViewController ()<PooNumberKeyBoardDelegate>
@property (nonatomic, strong)PBiologyID *touchID;
@property (nonatomic, strong)UITextField *textField;
@property (nonatomic, strong)PooTagsLabel *tagLabel;
@end

@implementation PTViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    self.view.backgroundColor = [UIColor whiteColor];
    
//    for (int i = 0; i < 2; i++) {
//        UIButton *pBtn = [UIButton buttonWithType:UIButtonTypeCustom];
//        pBtn.frame = CGRectMake(100*i+10*i, 100, 100, 40);
//        pBtn.backgroundColor = kRandomColor;
//        [pBtn setTitleColor:kRandomColor forState:UIControlStateNormal];
//        [pBtn setTitle:[NSString stringWithFormat:@"%d",i] forState:UIControlStateNormal];
//        pBtn.tag = i;
//        [self.view addSubview:pBtn];
//        [pBtn addActionHandler:^(UIButton *sender) {
//            PNSLog(@"%ld",(long)sender.tag);
//        }];
//
//    }
    
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame = self.view.bounds;
    [btn addTarget:self action:@selector(aaaaa) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
    
    
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

    
    
//    NSArray *titleS = @[@"3"];
////
//    PooTagsLabelConfig *config = [[PooTagsLabelConfig alloc] init];
//    config.itemHeight = 100;
//    config.itemHerMargin = 10;
//    config.itemVerMargin = 10;
//    config.hasBorder = YES;
//    config.topBottomSpace = 5;
//    config.itemContentEdgs = 20;
//    config.isCanSelected = YES;
//    config.isCanCancelSelected = YES;
//    config.isMulti = YES;
//    config.selectedDefaultTags = titleS;
////    config.borderColor = kRandomColor;
//    config.borderWidth = 1;
//    config.fontSize = 24;
//    config.cornerRadius = 5;
////
////    NSArray *normalImage = @[@"image_day_normal_7",@"image_day_normal_1",@"image_day_normal_2",@"image_day_normal_3",@"image_day_normal_4",@"image_day_normal_5",@"image_day_normal_6"];
////    NSArray *selectImage = @[@"image_day_select_7",@"image_day_select_1",@"image_day_select_2",@"image_day_select_3",@"image_day_select_4",@"image_day_select_5",@"image_day_select_6"];
////    NSArray *title = @[@"7",@"1",@"2",@"3",@"4",@"5",@"6"];
////
//    self.tagLabel = [[PooTagsLabel alloc] initWithFrame:CGRectMake(0, 100, kSCREEN_WIDTH, 0) tagsArray:@[@"1",@"2",@"3",@"4",@"5",@"6",@"7"] config:config wihtSection:0];
//    self.tagLabel.backgroundColor = kRandomColor;
////    [self.view addSubview:self.tagLabel];
//    PNSLog(@"%f",[self.tagLabel heightTagsArray:@[@"1",@"2",@"3",@"4",@"5",@"6",@"7"] config:config]);

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
//    imageModel2.imageUrl = @"http://p3.music.126.net/VDn1p3j4g2z4p16Gux969w==/2544269907756816.jpg";
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
//    ALActionSheetView *actionSheet = [[ALActionSheetView alloc] initWithTitle:@"sjdhfjkshdfjkhsdjkfhsdjfhjksdhfjkshdfjkhsdjkfhjsdhfjsdfjshdjfkhskjdfhjksdhfjshdkjhjssjdhfjkshdfjkhsdjkfhsdjfhjksdhfjkshdfjkhsdjkfhjsdhfjsdfjshdjfkhskjdfhjksdhfjshdkjhjssjdhfjkshdfjkhsdjkfhsdjfhjksdhfjkshdfjkhsdjkfhjsdhfjsdfjshdjfkhskjdfhjksdhfjshdkjhjssjdhfjkshdfjkhsdjkfhsdjfhjksdhfjkshdfjkhsdjkfhjsdhfjsdfjshdjfkhskjdfhjksdhfjshdkjhjssjdhfjkshdfjkhsdjkfhsdjfhjksdhfjkshdfjkhsdjkfhjsdhfjsdfjshdjfkhskjdfhjksdhfjshdkjhjssjdhfjkshdfjkhsdjkfhsdjfhjksdhfjkshdfjkhsdjkfhjsdhfjsdfjshdjfkhskjdfhjksdhfjshdkjhjssjdhfjkshdfjkhsdjkfhsdjfhjksdhfjkshdfjkhsdjkfhjsdhfjsdfjshdjfkhskjdfhjksdhfjshdkjhjssjdhfjkshdfjkhsdjkfhsdjfhjksdhfjkshdfjkhsdjkfhjsdhfjsdfjshdjfkhskjdfhjksdhfjshdkjhjssjdhfjkshdfjkhsdjkfhsdjfhjksdhfjkshdfjkhsdjkfhjsdhfjsdfjshdjfkhskjdfhjksdhfjshdkjhjssjdhfjkshdfjkhsdjkfhsdjfhjksdhfjkshdfjkhsdjkfhjsdhfjsdfjshdjfkhskjdfhjksdhfjshdkjhjs" cancelButtonTitle:@"adasdasdasdad" destructiveButtonTitle:@"1231231231" otherButtonTitles:@[@"1231",@"1231",@"1231",@"1231",@"1231",@"1231",@"1231",@"1231"] buttonFontName:FontName handler:^(ALActionSheetView *actionSheetView, NSInteger buttonIndex) {
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
    
    PNSLog(@">>>>>>>%f",[YXCustomAlertView titleAndBottomViewNormalH]);
    
    YXCustomAlertView *alert = [[YXCustomAlertView alloc] initAlertViewWithSuperView:self.view alertTitle:@"111123123111123123111123123111123123111123123111123123111123123111123123111123123111123123111123123111123123111123123111123123" withButtonAndTitleFont:[UIFont systemFontOfSize:20] titleColor:kRandomColor bottomButtonTitleColor:kRandomColor verLineColor:kRandomColor moreButtonTitleArray:@[@"111",@"222"] viewTag:1 setCustomView:^(YXCustomAlertView *alertView) {
        
        PooNumberKeyBoard *userNameKeyboard = [PooNumberKeyBoard pooNumberKeyBoardWithDog:YES backSpace:^(PooNumberKeyBoard *alertView) {
            if (self.textField.text.length != 0)
            {
                self.textField.text = [self.textField.text substringToIndex:self.textField.text.length -1];
            }
        } returnSTH:^(PooNumberKeyBoard *alertView, NSString *returnSTH) {
            self.textField.text = [self.textField.text stringByAppendingString:returnSTH];
        }];
        
        self.textField = [UITextField new];
        self.textField.placeholder = @"11111";
        self.textField.inputView = userNameKeyboard;
        [alertView.customView addSubview:self.textField];
        [self.textField mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.equalTo(alertView.customView);
            make.top.offset(64);
            make.height.offset(30);
        }];


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
    alert.customView.backgroundColor = kRandomColor;
    [alert mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.offset(250);
        make.left.equalTo(self.view).offset(10);
        make.right.equalTo(self.view).offset(-10);
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
