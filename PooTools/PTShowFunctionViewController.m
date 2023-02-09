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

#import <PooTools/PooTools-Swift.h>

#define FontName @"HelveticaNeue-Light"
#define FontNameBold @"HelveticaNeue-Medium"

#define DelaySecond 1

@interface PTShowFunctionViewController ()<GCDWebUploaderDelegate,UITextViewDelegate>
@property (nonatomic,assign)ShowFunction showType;

@property (nonatomic, strong) GCDWebUploader *webServer;

@property (nonatomic, strong) UITextField *textField;

@property (nonatomic, strong) UIButton *cornerBtn;

@property (nonatomic, strong) NSArray *titleS;

@property (nonatomic, strong) id popover;

@end

@implementation PTShowFunctionViewController

-(NSArray *)roomSetArray
{
    return @[@"空调lllllllllllllllllllllllllllllllllllllllllllll...................;",@"床",@"床",@"床",@"床",@"床",@"床",@"床",@"床",@"床",@"床",@"床",@"床",@"床",@"床",@"床",@"床",@"床",@"床"];
//    return @[@"空调lllllllllllllllllllllllllllllllllllllllllllll...................;",@"床",@"热水器",@"洗衣机",@"沙发",@"电视机",@"冰箱",@"天然气",@"宽带",@"衣柜",@"衣柜",@"衣柜",@"衣柜",@"衣柜",@"衣柜",@"衣柜",@"衣柜",@"衣柜",@"衣柜",@"衣柜",@"衣柜",@"衣柜",@"衣柜",@"衣柜",@"衣柜",@"衣柜",@"衣柜",@"衣柜",@"衣柜",@"衣柜",@"衣柜",@"11",@"12",@"13",@"14"];
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
                NSString *ipString = [PTPhoneNetWorkInfo ipv4String];
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
        }
            break;
            case ShowFunctionStarRate:
        {
            PTRateConfig *config = [[PTRateConfig alloc] init];
            config.canTap = YES;
            config.hadAnimation = YES;
            config.scorePercent = 2.f;
            
            PTRateView *rV = [[PTRateView alloc] initWithViewConfig:config];
            rV.rateBlock = ^(CGFloat score){
                PNSLog(@"%f",score);
            };
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
            
            PooSegmentModel * segModel = [[PooSegmentModel alloc] init];
            segModel.titles = @"aaaaaa";
            segModel.imageURL = @"DemoImage";
            segModel.selectedImageURL = @"DemoImage";

            PooSegmentModel * segModels = [[PooSegmentModel alloc] init];
            segModels.titles = @"22222";
            segModels.imageURL = @"DemoImage";
            segModels.selectedImageURL = @"DemoImage";
            PooSegmentConfig *config = [[PooSegmentConfig alloc] init];

            PooSegmentView *sgView = [[PooSegmentView alloc] initWithConfig:config];
            sgView.backgroundColor = UIColor.randomColor;
            sgView.viewDatas = @[segModel,segModels];
            [sgView reloadViewDataWithBlock:^(NSInteger index) {

            }];
            [self.view addSubview:sgView];
            [sgView mas_makeConstraints:^(MASConstraintMaker *make) {
                make.centerY.equalTo(self.view);
                make.height.offset(44);
                make.left.right.equalTo(self.view);
            }];
        }
            break;
            case ShowFunctionTagLabel:
        {
        }
            break;
            case ShowFunctionInputView:
        {
            PTNumberKeyBoard *aaaa = [PTNumberKeyBoard createKeyboardWithType:PTKeyboardTypeNormal backSpace:^(PTNumberKeyBoard * keyboard) {
                if (self.textField.text.length != 0)
                {
                    self.textField.text = [self.textField.text substringToIndex:self.textField.text.length -1];
                }
            } returnSTH:^(PTNumberKeyBoard * keyboard, NSString * returnSTH) {
                self.textField.text = [self.textField.text stringByAppendingString:returnSTH];
            }];
            self.textField = [UITextField new];
            self.textField.placeholder = @"用来展示数字键盘";
            //    self.textField.UI_PlaceholderLabel.text = @"11111";
            //    self.textField.UI_PlaceholderLabel.textAlignment = NSTextAlignmentCenter;
            //    self.textField.UI_PlaceholderLabel.textColor = kRandomColor;
            //    self.textField.UI_PlaceholderLabel.font = [UIFont systemFontOfSize:14];
            self.textField.inputView = aaaa;
            [self.view addSubview:self.textField];
            [self.textField mas_makeConstraints:^(MASConstraintMaker *make) {
                make.top.equalTo(self.view).offset(HEIGHT_NAVBAR);
                make.left.right.equalTo(self.view);
                make.height.offset(44);
            }];
            PTSearchBar *searchBar = [PTSearchBar new];
            searchBar.barStyle     = UIBarStyleDefault;
            searchBar.translucent  = YES;
            //    searchBar.delegate     = self;
            searchBar.keyboardType = UIKeyboardTypeDefault;
            searchBar.searchPlaceholder = @"点击此处查找地市名字";
            searchBar.searchPlaceholderColor = [UIColor purpleColor];
            searchBar.searchPlaceholderFont = [UIFont systemFontOfSize:24];
            searchBar.searchTextColor = [UIColor brownColor];
            searchBar.searchBarImage = [UIImage imageNamed:@"image_day_normal_1"];
            searchBar.searchTextFieldBackgroundColor = [UIColor yellowColor];
            searchBar.searchBarOutViewColor = UIColor.randomColor;
            searchBar.searchBarTextFieldCornerRadius = [[NSDecimalNumber alloc] initWithString:@"15.0"];
            searchBar.cursorColor = [UIColor redColor];
            [self.view addSubview:searchBar];
            [searchBar mas_makeConstraints:^(MASConstraintMaker *make) {
                make.top.equalTo(self.textField.mas_bottom).offset(10);
                make.left.right.equalTo(self.view);
                make.height.offset(44);
            }];
            
            UITextView *textView = [UITextView new];
            [self.view addSubview:textView];
            textView.backgroundColor = UIColor.randomColor;
            textView.delegate = self;
            textView.returnKeyType = UIReturnKeyDone;
            textView.font = [UIFont appCustomFontWithSize:20 customFont:FontName];
            textView.textColor = UIColor.randomColor;
            textView.bk_placeholder = @"我是TextView";
            textView.pt_maxWordCount = @30;
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
            self.cornerBtn.backgroundColor = UIColor.randomColor;
            [self.view addSubview:self.cornerBtn];
            
            //    NSMutableArray *_RectCornerArr = [NSMutableArray array];
            //    [_RectCornerArr addObject:@(UIRectCornerAllCorners)];
            [self.cornerBtn viewCornerRectCornerWithCornerRadii:20 borderWidth:0 borderColor:UIColor.clearColor corner:UIRectCornerBottomRight];
            
            NSArray *arr = @[@"左上",@"右上",@"左下",@"右下",@"全部"];
            
            for (int i = 0; i < arr.count; i++) {
                UIButton *pBtn = [UIButton buttonWithType:UIButtonTypeCustom];
                [pBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
                [pBtn setTitle:arr[i] forState:UIControlStateNormal];
                pBtn.tag = i;
                [pBtn addTarget:self action:@selector(cornerAction:) forControlEvents:UIControlEventTouchUpInside];
                [self.view addSubview:pBtn];
                [pBtn mas_makeConstraints:^(MASConstraintMaker *make) {
                    make.centerY.equalTo(self.view);
                    make.left.offset((kSCREEN_WIDTH/arr.count)*i);
                    make.width.offset(kSCREEN_WIDTH/arr.count);
                    make.height.offset(kSCREEN_WIDTH/arr.count);
                }];
                [pBtn viewCornerWithRadius:5 borderWidth:1 borderColor:UIColor.randomColor];
            }
            
        }
            break;
        case ShowFunctionLabelThroughLine:
        {
            PTLabel *aaaaaaaaaaaaaa = [PTLabel new];
            aaaaaaaaaaaaaa.text = @"111111111111111";
            aaaaaaaaaaaaaa.backgroundColor = UIColor.randomColor;
            [aaaaaaaaaaaaaa setVerticalAlignmentWithValue:PTVerticalAlignmentMiddle];
            [aaaaaaaaaaaaaa setStrikeThroughAlignmentWithValue:PTStrikeThroughAlignmentMiddle];
            aaaaaaaaaaaaaa.strikeThroughColor = UIColor.randomColor;
            [PTUtils gcdAfterTime:0.2 block:^{
                [aaaaaaaaaaaaaa setStrikeThroughEnabledWithValue:YES];
            }];
            [self.view addSubview:aaaaaaaaaaaaaa];
            [aaaaaaaaaaaaaa mas_makeConstraints:^(MASConstraintMaker *make) {
                make.top.equalTo(self.view).offset(HEIGHT_NAVBAR);
                make.left.right.equalTo(self.view);
                make.height.offset(44);
            }];

            UIButton *randomLineBtn = [UIButton buttonWithType:UIButtonTypeCustom];
            [randomLineBtn setTitleColor:UIColor.randomColor forState:UIControlStateNormal];
            [randomLineBtn setTitle:@"随机画线" forState:UIControlStateNormal];
            [randomLineBtn addActionHandlersWithHandler:^(UIButton * sender) {
                [aaaaaaaaaaaaaa setVerticalAlignmentWithValue:random()%4];
                [aaaaaaaaaaaaaa setStrikeThroughAlignmentWithValue:random()%4];
                [aaaaaaaaaaaaaa setStrikeThroughEnabledWithValue:random()%2];
            }];
            [self.view addSubview:randomLineBtn];
            [randomLineBtn mas_makeConstraints:^(MASConstraintMaker *make) {
                make.height.width.offset(100);
                make.centerX.centerY.equalTo(self.view);
            }];
        }
            break;
        case ShowFunctionShowAlert:
        {
            NSArray *arr = @[@"ActionSheet",@"CustomAlert",@"SystemAlert",@"Popover"];

            for (int i = 0; i < arr.count; i++) {
                UIButton *pBtn = [UIButton buttonWithType:UIButtonTypeCustom];
//                pBtn.frame = CGRectMake((kSCREEN_WIDTH/arr.count)*i, HEIGHT_NAVBAR*2, kSCREEN_WIDTH/arr.count, kSCREEN_WIDTH/arr.count);
                [pBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
                [pBtn setTitle:arr[i] forState:UIControlStateNormal];
                pBtn.tag = i;
                [pBtn addTarget:self action:@selector(showAlertAction:) forControlEvents:UIControlEventTouchUpInside];
                [self.view addSubview:pBtn];
                [pBtn mas_makeConstraints:^(MASConstraintMaker *make) {
                    make.centerY.equalTo(self.view);
                    make.left.offset((kSCREEN_WIDTH/arr.count)*i);
                    make.width.offset(kSCREEN_WIDTH/arr.count);
                    make.height.offset(kSCREEN_WIDTH/arr.count);
                }];
                [pBtn viewCornerWithRadius:5 borderWidth:1 borderColor:UIColor.randomColor];
            }
        }
            break;
        case ShowFunctionPicker:
        {
            NSArray *arr = @[@"日期",@"时间",@"普通"];
            
            for (int i = 0; i < arr.count; i++) {
                UIButton *pBtn = [UIButton buttonWithType:UIButtonTypeCustom];
                [pBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
                [pBtn setTitle:arr[i] forState:UIControlStateNormal];
                pBtn.tag = i;
                [pBtn addTarget:self action:@selector(showPickerAction:) forControlEvents:UIControlEventTouchUpInside];
                [self.view addSubview:pBtn];
                [pBtn mas_makeConstraints:^(MASConstraintMaker *make) {
                    make.centerY.equalTo(self.view);
                    make.left.offset((kSCREEN_WIDTH/arr.count)*i);
                    make.width.offset(kSCREEN_WIDTH/arr.count);
                    make.height.offset(kSCREEN_WIDTH/arr.count);
                }];
                [pBtn viewCornerWithRadius:5 borderWidth:1 borderColor:UIColor.randomColor];
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
                [pBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
                [pBtn setTitle:arr[i] forState:UIControlStateNormal];
                pBtn.tag = i;
                [pBtn addTarget:self action:@selector(showLoadingHubAction:) forControlEvents:UIControlEventTouchUpInside];
                [self.view addSubview:pBtn];
                [pBtn mas_makeConstraints:^(MASConstraintMaker *make) {
                    make.centerY.equalTo(self.view);
                    make.left.offset((kSCREEN_WIDTH/arr.count)*i);
                    make.width.offset(kSCREEN_WIDTH/arr.count);
                    make.height.offset(kSCREEN_WIDTH/arr.count);
                }];
                [pBtn viewCornerWithRadius:5 borderWidth:1 borderColor:UIColor.randomColor];
            }
        }
            break;
        case ShowFunctionAboutImage:
        {
            UIImage *placeholderImage = [UIImage imageNamed:@"DemoImage"];
            UIImageView *blurGlassImage = [UIImageView new];
            blurGlassImage.image = [[placeholderImage transformImageWithSize:CGSizeMake(30, 30)] blurImage];
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
            PTCountingLabel *balanceLabel = [PTCountingLabel new];
            balanceLabel.textAlignment = NSTextAlignmentCenter;
            balanceLabel.font = [UIFont appCustomFontWithSize:30 customFont:FontName];
            balanceLabel.textColor = [UIColor blackColor];
            [self.view addSubview:balanceLabel];
            //设置格式
            balanceLabel.format = @"%.2f";
            //设置分隔符样式
            //self.balanceLabel.positiveFormat = @"###,##0.00";
            [balanceLabel countFromStarValue:99999.99 toValue:0.00 duration:1];
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
            [self.cornerBtn viewCornerRectCornerWithCornerRadii:20 borderWidth:0 borderColor:UIColor.clearColor corner:UIRectCornerTopLeft];
        }
            break;
        case 1:
        {
            [self.cornerBtn viewCornerRectCornerWithCornerRadii:20 borderWidth:0 borderColor:UIColor.clearColor corner:UIRectCornerTopRight];
        }
            break;
        case 2:
        {
            [self.cornerBtn viewCornerRectCornerWithCornerRadii:20 borderWidth:0 borderColor:UIColor.clearColor corner:UIRectCornerBottomLeft];
        }
            break;
        case 3:
        {
            [self.cornerBtn viewCornerRectCornerWithCornerRadii:20 borderWidth:0 borderColor:UIColor.clearColor corner:UIRectCornerBottomRight];
        }
            break;
        default:
        {
            [self.cornerBtn viewCornerRectCornerWithCornerRadii:20 borderWidth:0 borderColor:UIColor.clearColor corner:UIRectCornerAllCorners];
        }
            break;
    }
}

-(void)showAlertAction:(UIButton *)sender
{
    switch (sender.tag) {
        case 0:
        {
            NSArray<NSString *> * titles = @[@"按钮1",@"按钮2",@"按钮2",@"按钮2",@"按钮2",@"按钮2",@"按钮2",@"按钮2",@"按钮2",@"按钮2",@"按钮2",@"按钮2",@"按钮2",@"按钮2",@"按钮2",@"按钮2"];
            PTActionSheetView * aaaaa = [[PTActionSheetView alloc] initWithTitle:@"" subTitle:@"" cancelButton:@"取消" destructiveButton:@"" otherButtonTitles:titles];
            aaaaa.actionSheetSelectBlock = ^(PTActionSheetView * sheet, NSInteger buttonIndex) {
                PNSLog(@">>>>>>>>>>%ld",(long)buttonIndex);
            };
            [aaaaa show];
        }
            break;
        case 1:
        {
            NSString *title = @"111123123111123123111123123111123123111123123111123123111123123111123123111123123111123123111123123111123123111123123111123123111123123111123123111123123111123123111123123111123123111123123111123123112312312312312312312312312312334313123123sdsfsdfsdfsdfsdfsfsdsdsfsdfsdfsdfsdfsfsdsdsfsdfsdfsdfsdfsfsdsdsfsdfsdfsdfsdfsfsdsdsfsdfsdfsdfsdfsfsdsdsfsdfsdfsdfsdfsfsdsdsfsdfsdfsdfsdfsfsdsdsfsdfsdfsdfsdfsfsdsdsfsdfsdfsdfsdfsfsdsdsfsdfsdfsdfsdfsfsdsdsfsdfsdfsdfsdfsfsdsdsfsdfsdfsdfsdfsfsdsdsfsdfsdfsdfsdfsfsdsdsfsdfsdfsdfsdfsfsdsdsfsdfsdfsdfsdfsfsdsdsfsdfsdfsdfsdfsfsdsdsfsdfsdfsdfsdfsfsdsdsfsdfsdfsdfsdfsfsdsdsfsdfsdfsdfsdfsfsdsdsfsdfsdfsdfsdfsfsdsdsfsdfsdfsdfsdfsfsdsdsfsdfsdfsdfsdfsfsdsdsfsdfsdfsdfsdfsfsdsdsfsdfsdfsdfsdfsfsdsdsfsdfsdfsdfsdfsfsdsdsfsdfsdfsdfsdfsfsdsdsfsdfsdfsdfsdfsfsdsdsfsdfsdfsdfsdfsfsdsdsfsdfsdfsdfsdfsfsdsdsfsdfsdfsdfsdfsfsdsdsfsdfsdfsdfsdfsfsdsdsfsdfsdfsdfsdfsfsdsdsfsdfsdfsdfsdfsfsdsdsfsdfsdfsdfsdfsfsdsdsfsdfsdfsdfsdfsfsdsdsfsdfsdfsdfsdfsfsdsdsfsdfsdfsdfsdfsfsdsdsfsdfsdfsdfsdfsfsdsdsfsdfsdfsdfsdfsfsdsdsfsdfsdfsdfsdfsfsdsdsfsdfsdfsdfsdfsfsdsdsfsdfsdfsdfsdfsfsdsdsfsdfsdfsdfsdfsfsdsdsfsdfsdfsdfsdfsfsdsdsfsdfsdfsdfsdfsfsdsdsfsdfsdfsdfsdfsfsdsdsfsdfsdfsdfsdfsfsdsdsfsdfsdfsdfsdfsfsdsdsfsdfsdfsdfsdfsfsdsdsfsdfsdfsdfsdfsfsdsdsfsdfsdfsdfsdfsfsdsdsfsdfsdfsdfsdfsfsdsdsfsdfsdfsdfsdfsfsdsdsfsdfsdfsdfsdfsfsdsdsfsdfsdfsdfsdfsfsdsdsfsdfsdfsdfsdfsfsdsdsfsdfsdfsdfsdfsfsdsdsfsdfsdfsdfsdfsfsdsdsfsdfsdfsdfsdfsfsdsdsfsdfsdfsdfsdfsfsdsdsfsdfsdfsdfsdfsfsdsdsfsdfsdfsdfsdfsfsdsdsfsdfsdfsdfsdfsfsdsdsfsdfsdfsdfsdfsfsdsdsfsdfsdfsdfsdfsfsdsdsfsdfsdfsdfsdfsfsdsdsfsdfsdfsdfsdfsfsdsdsfsdfsdfsdfsdfsfsdsdsfsdfsdfsdfsdfsfsdsdsfsdfsdfsdfsdfsfsdsdsfsdfsdfsdfsdfsfsdsdsfsdfsdfsdfsdfsfsd";
            
            PTCustomBottomButtonModel *models = [[PTCustomBottomButtonModel alloc] init];
            models.titleColor = UIColor.redColor;
            models.titleName = @"123123";
            
            NSArray <PTCustomBottomButtonModel *>* titles = @[models];
            
            PTCustomAlertView * alerts = [[PTCustomAlertView alloc] initWithSuperView:[PTAppDelegate appDelegate].window alertTitle:title font:[UIFont appCustomFontWithSize:25 customFont:FontName] titleColor:UIColor.randomColor alertVerLineColor:UIColor.randomColor alertBackgroundColor:UIColor.randomColor heightlightedColor:UIColor.randomColor moreButtons:titles];
            [alerts mas_makeConstraints:^(MASConstraintMaker *make) {
                make.height.offset(64+[PTCustomAlertView titleAndBottomViewNormalHeightWithWidth:kSCREEN_WIDTH-20 title:title font:[UIFont appCustomFontWithSize:25 customFont:FontName] buttonArray:titles]);
                make.width.offset(kSCREEN_WIDTH-20);
                make.centerX.centerY.equalTo([PTAppDelegate appDelegate].window);
            }];
            alerts.customerBlock = ^(UIView * customerView) {
                UITextField *textField = [UITextField new];
                textField.placeholder = @"用来展示数字键盘";
                [customerView addSubview:textField];
                [textField mas_makeConstraints:^(MASConstraintMaker *make) {
                    make.top.equalTo(customerView).offset(10);
                    make.left.right.equalTo(customerView);
                    make.height.offset(44);
                }];
            };
            alerts.buttonClick = ^(PTCustomAlertView * alertView, NSInteger buttonIndex) {
                switch (buttonIndex) {
                    case 0:
                    {
                        [alertView dismiss];
                    }
                        break;
                    case 1:
                    {
                    }
                        break;
                    default:
                        break;
                }
            };
            alerts.didDismissBlock = ^(PTCustomAlertView * alertView) {
                
            };
        }
            break;
        case 2:
        {
            [UIAlertController base_alertVCWithTitle:@"111111111111111111111111111111111111111111111111111111111111111111" titleColor:nil titleFont:nil msg:@"11111111111111111111111111111111111234234234234234234234243" msgColor:nil msgFont:nil okBtns:nil cancelBtn:@"qqqqq" showIn:nil cancelBtnColor:nil doneBtnColors:nil alertBGColor:nil alertCornerRadius:nil cancel:nil moreBtn:nil];
        }
            break;
        case 3:
        {
            UIView *views = [UIView new];
            views.backgroundColor = UIColor.randomColor;
            views.bounds = CGRectMake(0, 0, 100, 300);
            [self popoverWithPopoverVC:[[UIViewController alloc] init] popoverSize:CGSizeMake(100, 100) sender:sender arrowDirections:UIPopoverArrowDirectionAny];
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
        }
            break;
        case 1:
        {
            
        }
            break;
        case 2:
        {
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
//    UIPickerView *_pickerView = [UIPickerView new];
//    _pickerView.dataSource = self;
//    _pickerView.delegate = self;
//    _pickerView.backgroundColor = [UIColor whiteColor];
//    [self.view addSubview:_pickerView];
//    [_pickerView mas_makeConstraints:^(MASConstraintMaker *make) {
//        make.left.right.equalTo(self.view);
//        make.height.offset(216);
//        make.bottom.equalTo(self.view);
//    }];
}

-(void)showLoadingHubAction:(UIButton *)sender
{
    switch (sender.tag) {
        case 0:
        {
            PTHudView *hud = [PTHudView new];
            [hud hudShow];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC*DelaySecond), dispatch_get_main_queue(), ^{
                [hud hideWithCompletion:^{
                    
                }];
            });
        }
            break;
        case 1:
        {
//        https://github.com/kirualex/SwiftyGif
//        http://img.t.sinajs.cn/t35/style/images/common/face/ext/normal/7a/shenshou_thumb.gif
        }
            break;
        case 2:
        {
            PTCycleLoadingView *loading = [[PTCycleLoadingView alloc] initWithFrame:CGRectZero];
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

//#pragma mark ------> UIPickerViewDataSource
////返回有几列
//-(NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
//
//{
//    return 1;
//}
//
////返回指定列的行数
//-(NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
//
//{
//    return  [[CountryCodes countryCodes] count];
//}
//
//// 自定义指定列的每行的视图，即指定列的每行的视图行为一致
//- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view
//{
//    if (!view)
//    {
//        view = [[UIView alloc]init];
//    }
//
//    UILabel *text = [UILabel new];
//    text.textColor = [UIColor blackColor];
//    text.textAlignment = NSTextAlignmentCenter;
//    text.font = kDEFAULT_FONT(FontName, 19);
//
//    CountryCodeModel *model = [CountryCodes countryCodes][row];
//
//    text.text = [NSString stringWithFormat:@"%@>>>>%@",model.countryName,model.countryCode];
//
//    [view addSubview:text];
//    [text mas_makeConstraints:^(MASConstraintMaker *make) {
//        make.left.right.top.height.equalTo(view);
//    }];
//
//    return view;
//}

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

@end
