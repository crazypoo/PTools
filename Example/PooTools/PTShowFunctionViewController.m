//
//  PTShowFunctionViewController.m
//  PooTools_Example
//
//  Created by 邓杰豪 on 2018/10/24.
//  Copyright © 2018年 crazypoo. All rights reserved.
//

#define iPhone6SPViewPointW 414
#define PSViewPointToiOSViewPoint(x) (x/3)
#define ViewSpace PSViewPointToiOSViewPoint(77)*ViewScale
//Cell的上下Space
#define CellSpace PSViewPointToiOSViewPoint(63)*ViewScale
#define AppOrange kColorFromHex(0xff7112)
#define ViewScale (kSCREEN_WIDTH/iPhone6SPViewPointW)

CGFloat const tagItemH = PSViewPointToiOSViewPoint(102);
CGFloat const tagItemSpace = 5;



#import "PTShowFunctionViewController.h"

#import "PMacros.h"
#import <Masonry/Masonry.h>
#import "Utils.h"
#import "PTAppDelegate.h"

#import <GCDWebServer/GCDWebUploader.h>
#import "PGetIpAddresses.h"

#import "PADView.h"
#import "IGBannerView.h"

#import "PStarRateView.h"

#import "PooSegView.h"

#import "PooTagsLabel.h"

#import "PooNumberKeyBoard.h"
#import "PooSearchBar.h"
#import "PooTextView.h"

#import "UIView+ViewRectCorner.h"

#import "PLabel.h"
#import "UICountingLabel.h"

#import "ALActionSheetView.h"
#import "YXCustomAlertView.h"

#import "PooDatePicker.h"
#import "PTNormalPicker.h"

#import "CountryCodes.h"

#import "WMHub.h"
#import "PGifHud.h"
#import "PooLoadingView.h"

#import "UIImage+BlurGlass.h"

#import "UIButton+Block.h"
#define FontName @"HelveticaNeue-Light"
#define FontNameBold @"HelveticaNeue-Medium"

#define APPFONT(R) kDEFAULT_FONT(FontName,kAdaptedWidth(R))

#define DelaySecond 1

@interface PTShowFunctionViewController ()<GCDWebUploaderDelegate,PooTimePickerDelegate,UIPickerViewDelegate,UIPickerViewDataSource,UITextViewDelegate>
@property (nonatomic,assign)ShowFunction showType;

@property (nonatomic, strong) GCDWebUploader *webServer;

@property (nonatomic, strong) UITextField *textField;

@property (nonatomic, strong) UIButton *cornerBtn;

@property (nonatomic, strong) PooSegView *seg;

@property (nonatomic, strong) NSArray *titleS;
@end

@implementation PTShowFunctionViewController

-(NSArray *)roomSetArray
{
    return @[@"空调",@"床",@"热水器",@"洗衣机",@"沙发",@"电视机",@"冰箱",@"天然气",@"宽带",@"衣柜"];
}

-(NSArray *)taglabelNormalArr
{
    return @[@"image_aircondition_gray",@"image_bed_gray",@"image_heater_gray",@"image_washer_gray",@"image_sofa_gray",@"image_televition_gray",@"image_fridge_gray",@"image_gas_gray",@"image_web_gray",@"image_closet_gray"];
}

-(NSArray *)taglabelSelected
{
    return @[@"image_aircondition",@"image_bed",@"image_heater",@"image_washer",@"image_sofa",@"image_televition",@"image_fridge",@"image_gas",@"image_web",@"image_closet"];
}

-(instancetype)initWithShowFunctionType:(ShowFunction)type
{
    self = [super init];
    if (self) {
        self.showType = type;
    }
    return self;
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    [self.webServer stop];
    self.webServer = nil;
}

-(PooTagsLabelConfig *)tagConfig
{
    CGFloat smallScreen = (kSCREEN_WIDTH < iPhone6SPViewPointW) ? ((kSCREEN_WIDTH-ViewSpace*2-tagItemSpace*5.5)/4) : ((kSCREEN_WIDTH-ViewSpace*2-tagItemSpace*5)/(IS_IPAD ? 4.5 : 4));
    
    PooTagsLabelConfig *config = [[PooTagsLabelConfig alloc] init];
    config.itemHeight = tagItemH * ViewScale;
    config.itemWidth = smallScreen;
    config.itemHerMargin = tagItemSpace;
    config.itemVerMargin = tagItemSpace;
    config.hasBorder = NO;
    config.topBottomSpace = tagItemSpace;
    config.itemContentEdgs = tagItemSpace;
    config.isCanSelected = YES;
    config.isCanCancelSelected = NO;
    config.isMulti = YES;
    config.selectedDefaultTags = self.titleS;
    config.selectedTitleColor = AppOrange;
    config.showStatus = PooTagsLabelShowWithImageStatusNoTitle;
    config.borderColor = [UIColor grayColor];
    config.borderColorSelected = AppOrange;

    return config;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    switch (self.showType) {
        case ShowFunctionFile:
        {
            NSString *pathDocuments = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
            NSString *createImagePath = [NSString stringWithFormat:@"%@/Photo", pathDocuments];
            // 创建webServer,设置根目录
            self.webServer = [[GCDWebUploader alloc] initWithUploadDirectory:createImagePath];
            // 设置代理
            self.webServer.delegate = self;
            self.webServer.allowHiddenItems = YES;
            // 开启
            NSString *urlString;
            if ([_webServer start])
            {
                NSString *ipString = [PGetIpAddresses getIPAddress:YES];
                NSLog(@"ip地址为：%@", ipString);
                NSUInteger port = self.webServer.port;
                NSLog(@"开启监听的端口为：%zd", port);
                urlString = [NSString stringWithFormat:@"请在上传设备浏览器上输入%@\n端口为:%lu\n例子:IP地址:端口地址",self.webServer.serverURL,(unsigned long)port];
            }
            else
            {
                NSLocalizedString(@"GCDWebServer not running!", nil);
                urlString = @"GCDWebServer not running!";
            }
            
            UILabel *infoLabel = [UILabel new];
            infoLabel.textColor = [UIColor blackColor];
            infoLabel.textAlignment = NSTextAlignmentCenter;
            infoLabel.numberOfLines = 0;
            infoLabel.lineBreakMode = NSLineBreakByCharWrapping;
            infoLabel.text = urlString;
            [self.view addSubview:infoLabel];
            [infoLabel mas_makeConstraints:^(MASConstraintMaker *make) {
                make.left.right.top.bottom.equalTo(self.view);
            }];

        }
            break;
            case ShowFunctionCollectionAD:
        {
            CGAdBannerModel *aaaaa = [[CGAdBannerModel alloc] init];
            aaaaa.bannerTitle = @"111111";
            aaaaa.bannerImage = @"http://p3.music.126.net/VDn1p3j4g2z4p16Gux969w==/2544269907756816.jpg";
            
            PADView *adaaaa = [[PADView alloc] initWithAdArray:@[aaaaa,aaaaa] singleADW:kSCREEN_WIDTH singleADH:150 paddingY:5 paddingX:5 placeholderImage:@"DemoImage" pageTime:1 adTitleFont:kDEFAULT_FONT(FontName, 19) pageIndicatorTintColor:[UIColor lightGrayColor] currentPageIndicatorTintColor:[UIColor redColor] pageEnable:NO];
            [self.view addSubview:adaaaa];
            [adaaaa mas_makeConstraints:^(MASConstraintMaker *make) {
                make.top.equalTo(self.view).offset(HEIGHT_NAVBAR*2);
                make.height.offset(160);
                make.left.right.equalTo(self.view);
            }];
            
            IGBannerView *banner = [[IGBannerView alloc] initWithFrame:CGRectMake(0, HEIGHT_NAVBAR*2+160+10, kSCREEN_WIDTH, 100) bannerItems:@[[IGBannerItem itemWithTitle:@"广告1" imageUrl:@"" tag:0],[IGBannerItem itemWithTitle:@"广告2" imageUrl:@"http://p3.music.126.net/VDn1p3j4g2z4p16Gux969w==/2544269907756816.jpg" tag:1]] bannerPlaceholderImage:kImageNamed(@"DemoImage")];
            banner.pageControlBackgroundColor = [UIColor clearColor];
            banner.titleBackgroundColor = [UIColor clearColor];
            banner.titleColor = [UIColor clearColor];
//            banner.delegate                   = self;
            banner.autoScrolling              = YES;
            banner.titleFont = kDEFAULT_FONT(FontName,14);
            [self.view addSubview:banner];
            banner.bannerTapBlock = ^(IGBannerView *bannerView, IGBannerItem *bannerItem) {
                PNSLog(@">>>>>>>>>>%@",bannerItem);
            };
        }
            break;
            case ShowFunctionStarRate:
        {
            PStarRateView *rV = [[PStarRateView alloc] initWithRateBlock:^(PStarRateView *rateView, CGFloat newScorePercent) {
            }];
            rV.backgroundColor = kRandomColor;
            rV.scorePercent = 0.5;
            rV.hasAnimation = NO;
            rV.allowIncompleteStar = NO;
            [self.view addSubview:rV];
            [rV mas_makeConstraints:^(MASConstraintMaker *make) {
                make.centerX.centerY.equalTo(self.view);
                make.height.offset(100);
                make.left.right.equalTo(self.view);
            }];
        }
            break;
        case ShowFunctionSegmented:
        {
            
            self.seg = [[PooSegView alloc] initWithTitles:@[@"1",@"22223",@"22223",@"22223"] titleNormalColor:[UIColor lightGrayColor] titleSelectedColor:[UIColor redColor] titleFont:APPFONT(16) setLine:NO lineColor:[UIColor blackColor] lineWidth:1 selectedBackgroundColor:[UIColor yellowColor] normalBackgroundColor:[UIColor blueColor] showType:PooSegShowTypeUnderLine firstSelectIndex:1 clickBlock:^(PooSegView *segViewView, NSInteger buttonIndex) {
                PNSLog(@"%ld",(long)buttonIndex);
                switch (buttonIndex) {
                        case 0:
                    {
                        [segViewView setSegBadgeAtIndex:0 where:PooSegBadgeShowTypeBottomRight];
                    }
                        break;
                        case 1:
                    {
                        [segViewView setSegBadgeAtIndex:3 where:PooSegBadgeShowTypeBottomMiddle];
                    }
                        break;
                        case 2:
                    {
                        [segViewView removeAllSegBadgeAtIndex];
                    }
                        break;
                        case 3:
                    {
                        [segViewView removeSegBadgeAtIndex:0];
                    }
                        break;
                    default:
                        break;
                }
            }];
            [self.view addSubview:self.seg];
            [self.seg mas_makeConstraints:^(MASConstraintMaker *make) {
                make.centerY.equalTo(self.view);
                make.height.offset(44);
                make.left.right.equalTo(self.view);
            }];
            
            UIButton *pBtn = [UIButton buttonWithType:UIButtonTypeCustom];
            pBtn.backgroundColor = kRandomColor;
            [pBtn addTarget:self action:@selector(segAction:) forControlEvents:UIControlEventTouchUpInside];
            [self.view addSubview:pBtn];
            [pBtn mas_makeConstraints:^(MASConstraintMaker *make) {
                make.left.right.height.equalTo(self.seg);
                make.top.equalTo(self.seg.mas_bottom).offset(44);
            }];
        }
            break;
            case ShowFunctionTagLabel:
        {
            
            self.titleS = @[@"空调",@"床",@"热水器",@"洗衣机"];

//            NSArray *titleS = @[@"空调",@"床",@"热水器",@"洗衣机"];
//
//            CGFloat smallScreen = (kSCREEN_WIDTH < iPhone6SPViewPointW) ? ((kSCREEN_WIDTH-ViewSpace*2-tagItemSpace*5.5)/4) : ((kSCREEN_WIDTH-ViewSpace*2-tagItemSpace*5)/(IS_IPAD ? 4.5 : 4));
//
//            PooTagsLabelConfig *config = [[PooTagsLabelConfig alloc] init];
//            config.itemHeight = tagItemH * ViewScale;
//            config.itemWidth = smallScreen;
//            config.itemHerMargin = tagItemSpace;
//            config.itemVerMargin = tagItemSpace;
//            config.hasBorder = NO;
//            config.topBottomSpace = tagItemSpace;
//            config.itemContentEdgs = tagItemSpace;
//            config.isCanSelected = YES;
//            config.isCanCancelSelected = NO;
//            config.isMulti = YES;
//            config.selectedDefaultTags = titleS;
//            config.selectedTitleColor = AppOrange;
//            config.showStatus = PooTagsLabelShowWithImageStatusNoTitle;
//            config.borderColor = [UIColor grayColor];
//            config.borderColorSelected = AppOrange;

//            NSArray *title = @[@"7",@"1",@"2",@"3",@"1231231231314124"];
            
//            PooTagsLabel *tag = [[PooTagsLabel alloc] initWithTagsArray:title config:config wihtSection:0];
            PooTagsLabel *tag = [[PooTagsLabel alloc] initWithTagsNormalArray:self.taglabelNormalArr tagsSelectArray:self.taglabelSelected tagsTitleArray:self.roomSetArray config:[self tagConfig] wihtSection:0];
            tag.backgroundColor = kRandomColor;
            [self.view addSubview:tag];
            [tag mas_makeConstraints:^(MASConstraintMaker *make) {
                make.left.right.bottom.equalTo(self.view);
                make.top.equalTo(self.view).offset(HEIGHT_NAVBAR*2);
            }];
            tag.tagHeightBlock = ^(PooTagsLabel *aTagsView, CGFloat viewHeight) {
                PNSLog(@"%f",viewHeight);
            };
            
            UIButton *pBtnsssss = [UIButton buttonWithType:UIButtonTypeCustom];
            pBtnsssss.backgroundColor = kRandomColor;
            [pBtnsssss addActionHandler:^(UIButton *sender) {
                self.titleS = @[@"空调",@"床",@"热水器"];
                [tag reloadTag:[self tagConfig]];
            }];
            [self.view addSubview:pBtnsssss];
            [pBtnsssss mas_makeConstraints:^(MASConstraintMaker *make) {
                make.width.height.offset(100);
                make.centerX.centerY.equalTo(self.view);
            }];
        }
            break;
            case ShowFunctionInputView:
        {
            PooNumberKeyBoard *userNameKeyboard = [PooNumberKeyBoard pooNumberKeyBoardWithType:PKeyboardTypeInputID backSpace:^(PooNumberKeyBoard *keyboardView) {
                if (self.textField.text.length != 0)
                {
                    self.textField.text = [self.textField.text substringToIndex:self.textField.text.length -1];
                }
                
            } returnSTH:^(PooNumberKeyBoard *keyboardView, NSString *returnSTH) {
                self.textField.text = [self.textField.text stringByAppendingString:returnSTH];
                
            }];
            //
            self.textField = [UITextField new];
            self.textField.placeholder = @"用来展示数字键盘";
            //    self.textField.UI_PlaceholderLabel.text = @"11111";
            //    self.textField.UI_PlaceholderLabel.textAlignment = NSTextAlignmentCenter;
            //    self.textField.UI_PlaceholderLabel.textColor = kRandomColor;
            //    self.textField.UI_PlaceholderLabel.font = [UIFont systemFontOfSize:14];
            self.textField.inputView = userNameKeyboard;
            [self.view addSubview:self.textField];
            [self.textField mas_makeConstraints:^(MASConstraintMaker *make) {
                make.top.equalTo(self.view).offset(HEIGHT_NAVBAR);
                make.left.right.equalTo(self.view);
                make.height.offset(44);
            }];
            
            PooSearchBar *searchBar = [PooSearchBar new];
            searchBar.barStyle     = UIBarStyleDefault;
            searchBar.translucent  = YES;
            //    searchBar.delegate     = self;
            searchBar.keyboardType = UIKeyboardTypeDefault;
            searchBar.searchPlaceholder = @"点击此处查找地市名字";
            searchBar.searchPlaceholderColor = kRandomColor;
            searchBar.searchPlaceholderFont = [UIFont systemFontOfSize:24];
            searchBar.searchTextColor = kRandomColor;
            //    searchBar.searchBarImage = kImageNamed(@"Search");
            searchBar.searchTextFieldBackgroundColor = kRandomColor;
            searchBar.searchBarOutViewColor = kRandomColor;
            searchBar.searchBarTextFieldCornerRadius = 15;
            searchBar.cursorColor = kRandomColor;
            [self.view addSubview:searchBar];
            [searchBar mas_makeConstraints:^(MASConstraintMaker *make) {
                make.top.equalTo(self.textField.mas_bottom).offset(10);
                make.left.right.equalTo(self.view);
                make.height.offset(44);
            }];
            
            PooTextView *textView = [PooTextView new];
            textView.backgroundColor = kRandomColor;
            textView.placeholder = @"我是TextView";
            textView.delegate = self;
            textView.returnKeyType = UIReturnKeyDone;
            textView.font = APPFONT(20);
            textView.textColor = kRandomColor;
            [self.view addSubview:textView];
            [textView mas_makeConstraints:^(MASConstraintMaker *make) {
                make.top.equalTo(searchBar.mas_bottom).offset(10);
                make.left.right.equalTo(self.view);
                make.height.offset(44);
            }];

        }
            break;
            case ShowFunctionViewCorner:
        {
            self.cornerBtn = [UIButton buttonWithType:UIButtonTypeCustom];
            self.cornerBtn.frame = CGRectMake((kSCREEN_WIDTH-100)/2, HEIGHT_NAVBAR+HEIGHT_NAVBAR, 100, 100);
            self.cornerBtn.viewUI_rectCornerRadii = 20;
            self.cornerBtn.backgroundColor = kRandomColor;
            [self.view addSubview:self.cornerBtn];
            
            //    NSMutableArray *_RectCornerArr = [NSMutableArray array];
            //    [_RectCornerArr addObject:@(UIRectCornerAllCorners)];
            
            self.cornerBtn.viewUI_rectCorner = UIRectCornerBottomRight;

            NSArray *arr = @[@"左上",@"右上",@"左下",@"右下",@"全部"];
            
            for (int i = 0; i < arr.count; i++) {
                UIButton *pBtn = [UIButton buttonWithType:UIButtonTypeCustom];
                pBtn.frame = CGRectMake((kSCREEN_WIDTH/arr.count)*i, BOTTOM(self.cornerBtn)+20, kSCREEN_WIDTH/arr.count, kSCREEN_WIDTH/arr.count);
                [pBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
                [pBtn setTitle:arr[i] forState:UIControlStateNormal];
                pBtn.tag = i;
                [pBtn addTarget:self action:@selector(cornerAction:) forControlEvents:UIControlEventTouchUpInside];
                [self.view addSubview:pBtn];
            }
            
        }
            break;
        case ShowFunctionLabelThroughLine:
        {
            PLabel *aaaaaaaaaaaaaa = [PLabel new];
            aaaaaaaaaaaaaa.backgroundColor = kRandomColor;
            [aaaaaaaaaaaaaa setVerticalAlignment:VerticalAlignmentMiddle strikeThroughAlignment:StrikeThroughAlignmentMiddle setStrikeThroughEnabled:YES];
            aaaaaaaaaaaaaa.text = @"111111111111111";
            [self.view addSubview:aaaaaaaaaaaaaa];
            [aaaaaaaaaaaaaa mas_makeConstraints:^(MASConstraintMaker *make) {
                make.top.equalTo(self.view).offset(HEIGHT_NAVBAR);
                make.left.right.equalTo(self.view);
                make.height.offset(44);
            }];
        }
            break;
        case ShowFunctionShowAlert:
        {
            NSArray *arr = @[@"ActionSheet",@"CustomAlert",@"SystemAlert"];
            
            for (int i = 0; i < arr.count; i++) {
                UIButton *pBtn = [UIButton buttonWithType:UIButtonTypeCustom];
                pBtn.frame = CGRectMake((kSCREEN_WIDTH/arr.count)*i, HEIGHT_NAVBAR*2, kSCREEN_WIDTH/arr.count, kSCREEN_WIDTH/arr.count);
                [pBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
                [pBtn setTitle:arr[i] forState:UIControlStateNormal];
                pBtn.tag = i;
                [pBtn addTarget:self action:@selector(showAlertAction:) forControlEvents:UIControlEventTouchUpInside];
                [self.view addSubview:pBtn];
            }
        }
            break;
        case ShowFunctionPicker:
        {
            NSArray *arr = @[@"日期",@"时间",@"普通"];
            
            for (int i = 0; i < arr.count; i++) {
                UIButton *pBtn = [UIButton buttonWithType:UIButtonTypeCustom];
                pBtn.frame = CGRectMake((kSCREEN_WIDTH/arr.count)*i, HEIGHT_NAVBAR*2, kSCREEN_WIDTH/arr.count, kSCREEN_WIDTH/arr.count);
                [pBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
                [pBtn setTitle:arr[i] forState:UIControlStateNormal];
                pBtn.tag = i;
                [pBtn addTarget:self action:@selector(showPickerAction:) forControlEvents:UIControlEventTouchUpInside];
                [self.view addSubview:pBtn];
            }
        }
            break;
        case ShowFunctionCountryCodeSelect:
        {
            UIButton *pBtn = [UIButton buttonWithType:UIButtonTypeCustom];
            pBtn.frame = CGRectMake(0, HEIGHT_NAVBAR*2, kSCREEN_WIDTH, kSCREEN_WIDTH);
            [pBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
            [pBtn setTitle:@"选择国家" forState:UIControlStateNormal];
            [pBtn addTarget:self action:@selector(showCountryPickerAction:) forControlEvents:UIControlEventTouchUpInside];
            [self.view addSubview:pBtn];

        }
            break;
        case ShowFunctionCountryLoading:
        {
            NSArray *arr = @[@"Google",@"GIF",@"Other"];
            
            for (int i = 0; i < arr.count; i++) {
                UIButton *pBtn = [UIButton buttonWithType:UIButtonTypeCustom];
                pBtn.frame = CGRectMake((kSCREEN_WIDTH/arr.count)*i, HEIGHT_NAVBAR*2, kSCREEN_WIDTH/arr.count, kSCREEN_WIDTH/arr.count);
                [pBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
                [pBtn setTitle:arr[i] forState:UIControlStateNormal];
                pBtn.tag = i;
                [pBtn addTarget:self action:@selector(showLoadingHubAction:) forControlEvents:UIControlEventTouchUpInside];
                [self.view addSubview:pBtn];
            }
        }
            break;
        case ShowFunctionAboutImage:
        {
            UIImage *placeholderImage = kImageNamed(@"DemoImage");
            
            UIImageView *blurGlassImage = [UIImageView new];
            blurGlassImage.image = [placeholderImage imgWithBlur];
            [self.view addSubview:blurGlassImage];
            [blurGlassImage mas_makeConstraints:^(MASConstraintMaker *make) {
                make.left.equalTo(self.view);
                make.top.equalTo(self.view).offset(HEIGHT_NAVBAR);
                make.width.height.offset(100);
            }];
        }
            break;
        case ShowFunctionLabelCountingLabel:
        {
            UICountingLabel *balanceLabel = [UICountingLabel new];
            balanceLabel.textAlignment = NSTextAlignmentCenter;
            balanceLabel.font = kDEFAULT_FONT(FontName, 30);
            balanceLabel.textColor = [UIColor blackColor];
            [self.view addSubview:balanceLabel];
            //设置格式
            balanceLabel.format = @"%.2f";
            //设置分隔符样式
            //self.balanceLabel.positiveFormat = @"###,##0.00";
            [balanceLabel countFrom:99999.99 to:0.00 withDuration:1.0f];
            [balanceLabel mas_makeConstraints:^(MASConstraintMaker *make) {
                make.left.right.equalTo(self.view);
                make.height.offset(44);
                make.centerY.equalTo(self.view);
            }];

        }
            break;
        default:
            break;
    }
}

#pragma mark ------> BtnAction
-(void)cornerAction:(UIButton *)sender
{
    switch (sender.tag) {
        case 0:
        {
            self.cornerBtn.viewUI_rectCorner = UIRectCornerTopLeft;

        }
            break;
        case 1:
        {
            self.cornerBtn.viewUI_rectCorner = UIRectCornerTopRight;

        }
            break;
        case 2:
        {
            self.cornerBtn.viewUI_rectCorner = UIRectCornerBottomLeft;

        }
            break;
        case 3:
        {
            self.cornerBtn.viewUI_rectCorner = UIRectCornerBottomRight;
        }
            break;
        default:
        {
            self.cornerBtn.viewUI_rectCorner = UIRectCornerAllCorners;
        }
            break;
    }
}

-(void)showAlertAction:(UIButton *)sender
{
    switch (sender.tag) {
        case 0:
        {
            ALActionSheetView *actionSheet = [[ALActionSheetView alloc] initWithTitle:@"标题" cancelButtonTitle:@"取消" destructiveButtonTitle:@"红色" otherButtonTitles:@[@"按钮1",@"按钮2"] buttonFontName:FontNameBold handler:^(ALActionSheetView *actionSheetView, NSInteger buttonIndex) {
            }];
            [actionSheet show];
        }
            break;
        case 1:
        {
            YXCustomAlertView *alert = [[YXCustomAlertView alloc] initAlertViewWithSuperView:[PTAppDelegate appDelegate].window alertTitle:@"111123123" withButtonAndTitleFont:[UIFont systemFontOfSize:20] titleColor:kRandomColor bottomButtonTitleColor:kRandomColor verLineColor:kRandomColor moreButtonTitleArray:@[@"111",@"222"] viewTag:1 setCustomView:^(YXCustomAlertView *alertView) {
                
//                UILabel *aaa = [UILabel new];
//                aaa.backgroundColor = kRandomColor;
//                aaa.text = @"1123123123123";
//                [alertView.customView addSubview:aaa];
//                [aaa mas_makeConstraints:^(MASConstraintMaker *make) {
//                    make.left.right.top.bottom.equalTo(alertView.customView);
//                }];
                
                UITextField *textField = [UITextField new];
                textField.placeholder = @"用来展示数字键盘";
                [alertView.customView addSubview:textField];
                [textField mas_makeConstraints:^(MASConstraintMaker *make) {
                    make.top.equalTo(alertView.customView).offset(10);
                    make.left.right.equalTo(alertView.customView);
                    make.height.offset(44);
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
            [alert mas_makeConstraints:^(MASConstraintMaker *make) {
                make.height.offset(64+[YXCustomAlertView titleAndBottomViewNormalH]);
                make.width.offset(kSCREEN_WIDTH-20);
                make.centerX.centerY.equalTo([PTAppDelegate appDelegate].window);
            }];
            
        }
            break;
        case 2:
        {
            [Utils alertVCWithTitle:@"123123" message:@"2123" cancelTitle:@"2" okTitle:@"1" otherButtonArray:@[] shouIn:self alertStyle:UIAlertControllerStyleActionSheet
                           okAction:^{
                               
                           } cancelAction:^{
                               
                           } otherButtonAction:^(NSInteger aaaaaaaaaa) {
                               PNSLog(@"%ld",(long)aaaaaaaaaa);
                           }];
        }
            break;
        default:
            break;
    }
}

-(void)showPickerAction:(UIButton *)sender
{
    switch (sender.tag) {
        case 0:
        {
            PooDatePicker *view = [[PooDatePicker alloc] initWithTitle:@"1111" toolBarBackgroundColor:kRandomColor labelFont:APPFONT(16) toolBarTitleColor:kRandomColor pickerFont:APPFONT(16) pickerType:PPickerTypeYMD inPutDataString:@"2018-07-08"];
            [view pickerShow];
            view.block = ^(NSString *dateString) {
                PNSLog(@">>>>>>>>>>>%@",dateString);
            };
        }
            break;
        case 1:
        {
            PooTimePicker *view = [[PooTimePicker alloc] initWithTitle:@"1111" toolBarBackgroundColor:kRandomColor labelFont:APPFONT(16) toolBarTitleColor:kRandomColor pickerFont:APPFONT(16)];
            view.delegate = self;
            [view pickerShow];
            //    view.block = ^(NSString *dateString) {
            //        PNSLog(@">>>>>>>>>>>%@",dateString);
            //    };
            
            [view customPickerView:view.pickerView didSelectRow:10 inComponent:0];
            [view customSelectRow:10 inComponent:0 animated:YES];
            
            [view customPickerView:view.pickerView didSelectRow:1 inComponent:1];
            [view customSelectRow:1 inComponent:1 animated:YES];
            view.dismissBlock = ^(PooTimePicker *timePicker) {
                [timePicker removeFromSuperview];
                timePicker = nil;
            };
            
        }
            break;
        case 2:
        {
            PTNormalPickerModel *aaaaa = [PTNormalPickerModel new];
            aaaaa.pickerTitle = @"1111111";
            PTNormalPickerModel *bbbbbb = [PTNormalPickerModel new];
            bbbbbb.pickerTitle = @"222222222";

            PTNormalPicker *nP = [[PTNormalPicker alloc] initWithNormalPickerBackgroundColor:[UIColor whiteColor] withTapBarBGColor:[UIColor blueColor] withTitleAndBtnTitleColor:[UIColor whiteColor] withTitleFont:APPFONT(18) withPickerData:@[aaaaa,bbbbbb] withPickerTitle:@"111111111111312312312312312312312312312312312312312312312" checkPickerCurrentRow:@"1111111"];
            nP.returnBlock = ^(PTNormalPicker *normalPicker, PTNormalPickerModel *pickerModel) {
                PNSLog(@">>>>>>>>>>>>%@>>>>>>>>>>%@>>>>>>>>>>>>>>>%@",normalPicker,pickerModel.pickerTitle,pickerModel.pickerIndexPath);
            };
            [nP pickerShow];
//            [[PTAppDelegate appDelegate].window addSubview:nP];
//            [nP mas_makeConstraints:^(MASConstraintMaker *make) {
//                make.left.right.top.bottom.equalTo([PTAppDelegate appDelegate].window);
//            }];
        }
            break;
        default:
            break;
    }
}

-(void)showCountryPickerAction:(UIButton *)sender
{
    UIPickerView *_pickerView = [UIPickerView new];
    _pickerView.dataSource = self;
    _pickerView.delegate = self;
    _pickerView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:_pickerView];
    [_pickerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.view);
        make.height.offset(216);
        make.bottom.equalTo(self.view);
    }];
}

-(void)showLoadingHubAction:(UIButton *)sender
{
    switch (sender.tag) {
        case 0:
        {
            [WMHub show];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC*DelaySecond), dispatch_get_main_queue(), ^{
                [WMHub hide];
            });
        }
            break;
        case 1:
        {
            [PGifHud gifHUDShowIn:kAppDelegateWindow];
            [PGifHud setGifWithURL:[NSURL URLWithString:@"https://timgsa.baidu.com/timg?image&quality=80&size=b9999_10000&sec=1535114837724&di=c006441b6c288352e1fcdfc7b47db2b3&imgtype=0&src=http%3A%2F%2Fimg5.duitang.com%2Fuploads%2Fitem%2F201412%2F13%2F20141213142127_yXadz.thumb.700_0.gif"]];
            [PGifHud setInfoLabelText:@"我是谁!!!!!!!!"];
            [PGifHud showWithOverlay];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC*DelaySecond*3), dispatch_get_main_queue(), ^{
                [PGifHud dismiss];
            });
        }
            break;
        case 2:
        {
            PooLoadingView *loading = [[PooLoadingView alloc] initWithFrame:CGRectZero];
            [self.view addSubview:loading];
            [loading mas_makeConstraints:^(MASConstraintMaker *make) {
                make.width.height.offset(100);
                make.centerX.centerY.equalTo(self.view);
            }];
            [loading startAnimation];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC*DelaySecond*3), dispatch_get_main_queue(), ^{
                [loading stopAnimation];
            });
        }
            break;
        default:
            break;
    }
}

#pragma mark - <GCDWebUploaderDelegate>
- (void)webUploader:(GCDWebUploader*)uploader didUploadFileAtPath:(NSString*)path {
    NSLog(@"[UPLOAD] %@", path);
}

- (void)webUploader:(GCDWebUploader*)uploader didMoveItemFromPath:(NSString*)fromPath toPath:(NSString*)toPath {
    NSLog(@"[MOVE] %@ -> %@", fromPath, toPath);
}

- (void)webUploader:(GCDWebUploader*)uploader didDeleteItemAtPath:(NSString*)path {
    NSLog(@"[DELETE] %@", path);
}

- (void)webUploader:(GCDWebUploader*)uploader didCreateDirectoryAtPath:(NSString*)path {
    NSLog(@"[CREATE] %@", path);
}

#pragma mark - <PooTimePickerDelegate>
-(void)timePickerReturnStr:(NSString *)timeStr timePicker:(PooTimePicker *)timePicker
{
    PNSLog(@">>>>>>>>>>>>>%@",timeStr);
}

-(void)timePickerDismiss:(PooTimePicker *)timePicker
{
    PNSLog(@">>>>>>>>>>>>>%@",timePicker);
}

#pragma mark ------> UIPickerViewDataSource
//返回有几列
-(NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView

{
    return 1;
}

//返回指定列的行数
-(NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component

{
    return  [[CountryCodes countryCodes] count];
}

// 自定义指定列的每行的视图，即指定列的每行的视图行为一致
- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view
{
    if (!view)
    {
        view = [[UIView alloc]init];
    }
    
    UILabel *text = [UILabel new];
    text.textColor = [UIColor blackColor];
    text.textAlignment = NSTextAlignmentCenter;
    text.font = kDEFAULT_FONT(FontName, 19);
    
    CountryCodeModel *model = [CountryCodes countryCodes][row];
    
    text.text = [NSString stringWithFormat:@"%@>>>>%@",model.countryName,model.countryCode];

    [view addSubview:text];
    [text mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.top.height.equalTo(view);
    }];
    
    return view;
}

//-(void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
//{
//}

//#pragma mark - Banner Delegate
//static UIImage *pi = nil;
//-(UIImage*)placeHolderImage{
//    if (!pi) {
//        pi = kImageNamed(@"DemoImage");
//    }
//    return pi;
//}
//
//-(void)bannerView:(IGBannerView *)bannerView didSelectItem:(IGBannerItem *)item
//{
//    PNSLog(@"%@",item);
//}

-(void)segAction:(UIButton *)sender
{
    [self.seg setSegCurrentIndex:3];
}
@end
