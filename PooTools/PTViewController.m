//
//  PTViewController.m
//  PooTools
//
//  Created by crazypoo on 05/01/2018.
//  Copyright (c) 2018 crazypoo. All rights reserved.
//

#import "PTViewController.h"
#import "Utils.h"
#import "PMacros.h"
#import "PTAppDelegate.h"
#import "UITextField+ModifyPlaceholder.h"

#import "PTShowFunctionViewController.h"

#import <Masonry/Masonry.h>
#import <IQKeyboardManager/IQKeyboardManager.h>
#import <WebKit/WebKit.h>

#import "MXRotationManager.h"

#import <PooTools/PooTools-Swift.h>

#define FontName @"HelveticaNeue-Light"
#define FontNameBold @"HelveticaNeue-Medium"


#define APPFONT(R) kDEFAULT_FONT(FontName,kAdaptedWidth(R))

@interface PTViewController ()<UITableViewDelegate,UITableViewDataSource,UIPopoverPresentationControllerDelegate>
{
}
@property (nonatomic, strong) PTBiologyID *touchID;
@property (nonatomic, strong) NSMutableArray *tableArr;
@property (nonatomic, strong) NSMutableArray *tableHeaderTitle;
@property (nonatomic, strong) id popover;
@property (nonatomic, strong) UITableView *tbView;
@property (nonatomic, strong) NSArray *tableNameArr;
@end

@implementation PTViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    self.view.backgroundColor = [UIColor whiteColor];
           
    self.tableNameArr = @[@[@"网页上传文件",@"广告展示功能",@"简单的评价界面",@"Segment",@"TagLabel",@"拍摄小视频",@"图片展示",@"生物识别",@"国家/国家代号选择"],@[@"手机判断",@"打电话到13800138000",[NSString stringWithFormat:@"获取缓存%@,并清理",[PCleanCache getCacheSize]]],@[@"输入控件"],@[@"界面展示某个圆角"],@[@"Label的下划线",@"数字跳动Label"],@[@"各种弹出框"],@[@"Picker"],@[@"Loading"],@[@"关于图片",@"验证码图片"],@[@"签名"],@[@"屏幕旋转"],@[@"Slider"]];
    self.tableArr = [[NSMutableArray alloc] initWithArray:self.tableNameArr];
    self.tableHeaderTitle = [[NSMutableArray alloc] initWithArray:@[@"其他",@"关于手机",@"文字输入",@"View的处理",@"Label",@"弹出框",@"Picker",@"Loading",@"图片",@"签名",@"屏幕旋转",@"Slider"]];
    
    self.tbView    = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    self.tbView.dataSource                     = self;
    self.tbView.delegate                       = self;
    self.tbView.showsHorizontalScrollIndicator = NO;
    self.tbView.showsVerticalScrollIndicator   = NO;
    self.tbView.separatorStyle                 = UITableViewCellSeparatorStyleSingleLine;
    [self.view addSubview:self.tbView];
    [self.tbView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.top.bottom.equalTo(self.view);
    }];
    
    self.popover = [[UIViewController alloc] init];
    
    kAdaptedOtherFontSize(@"", 16);
    UIView *views = [UIView new];
    views.backgroundColor = [UIColor redColor];
    views.bounds = CGRectMake(0, 0, 100, 300);
    
    UIButton *views2 = [UIButton buttonWithType:UIButtonTypeCustom];
    views2.backgroundColor = kRandomColor;
    [views addSubview:views2];
    [views2 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.offset(50);
        make.centerY.centerX.equalTo(views);
    }];
    [views2 addActionHandlersWithHandler:^(UIButton *sender) {
        if ([self.popover isKindOfClass:[PTCustomAlertView class]])
        {
            [(PTCustomAlertView *)self.popover dismiss];
        }
        else
        {
            [(UIViewController *)self.popover dismissViewControllerAnimated:YES completion:^{
                PTSwiftViewController *vc = [PTSwiftViewController new];
                [self.navigationController pushViewController:vc animated:YES];
            }];
        }
    }];
    

    UIButton *bbbbbbbbb = [UIButton buttonWithType:UIButtonTypeCustom];
    [bbbbbbbbb setTitleColor:kRandomColor forState:UIControlStateNormal];
    [bbbbbbbbb setTitle:@"222222222" forState:UIControlStateNormal];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:bbbbbbbbb];
    [bbbbbbbbb addActionHandlersWithHandler:^(UIButton *sender) {
        PNSLog(@"222222222");
        
        [self popoverWithPopoverVC:self.popover contentView:views sender:sender arrowDirections:UIPopoverArrowDirectionAny];
    }];
        
    PTDevMaskView *mask = [[PTDevMaskView alloc] initWithConfig:[PTDevMaskConfig new]];
    [self.view addSubview:mask];
    [mask mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.top.bottom.equalTo(self.view);
    }];
}

-(void)aaaaa
{
//    [self.textField ViewUI_viewShaking];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark ---------------> UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.tableArr[section] count];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.tableArr.count;
}

static NSString *cellIdentifier = @"CELL";

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = nil;
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    else
    {
        while ([cell.contentView.subviews lastObject] != nil) {
            [(UIView *)[cell.contentView.subviews lastObject] removeFromSuperview];
        }
    }
    
    UILabel *functionName = [UILabel new];
    functionName.text = self.tableArr[indexPath.section][indexPath.row];
    [cell.contentView addSubview:functionName];
    [functionName mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.top.equalTo(cell.contentView);
        make.height.offset(20);
    }];
    
    UILabel *infoLabel = [UILabel new];
    infoLabel.textColor = [UIColor blackColor];
    infoLabel.textAlignment = NSTextAlignmentCenter;
    infoLabel.numberOfLines = 0;
    infoLabel.lineBreakMode = NSLineBreakByCharWrapping;
    infoLabel.text = [NSString stringWithFormat:@"点我展现%@",self.tableArr[indexPath.section][indexPath.row]];
    [cell.contentView addSubview:infoLabel];
    [infoLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(functionName.mas_bottom);
        make.left.right.bottom.equalTo(cell.contentView);
    }];
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    switch (indexPath.section) {
        case 0:
            break;
        case 1:
        {
            switch (indexPath.row) {
                case 0:
                {
                    infoLabel.hidden = YES;
                    
                    NSString *isiPhoneX;
                    if (isIPhoneXSeries()) {
                        isiPhoneX = @"是";
                    }
                    else
                    {
                        isiPhoneX = @"否";
                    }
                    
                    NSString *isJailBroken = @"";
                    
                    UILabel *infoLabel = [UILabel new];
                    infoLabel.textColor = [UIColor blackColor];
                    infoLabel.textAlignment = NSTextAlignmentCenter;
                    infoLabel.numberOfLines = 0;
                    infoLabel.lineBreakMode = NSLineBreakByCharWrapping;
                    infoLabel.text = [NSString stringWithFormat:@"是否iPhoneX?%@.运营商:%@.是否越狱了?%@.机型:%@",isiPhoneX,[PTCarrie currentRadioAccessTechnology],isJailBroken,@"???"];
                    [cell.contentView addSubview:infoLabel];
                    [infoLabel mas_makeConstraints:^(MASConstraintMaker *make) {
                        make.top.equalTo(functionName.mas_bottom);
                        make.left.right.bottom.equalTo(cell.contentView);
                    }];
                }
                    break;
                    
                default:
                    break;
            }
        }
            break;
        case 2:
            break;
        case 3:
            break;
        case 4:
            break;
        case 5:
            break;
        case 6:
            break;
        default:
            break;
    }
    
    return cell;
}

#pragma mark ---------------> UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 64;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 44;
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *hView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 50)];
    
    UILabel *hTitle = [UILabel new];
    hTitle.text = self.tableHeaderTitle[section];
    [hView addSubview:hTitle];
    [hTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.top.bottom.equalTo(hView);
    }];

    return hView;
}

-(NSMutableArray *)typeArr
{
    NSMutableArray *arr = [[NSMutableArray alloc] init];
    for (int i = 0; i < 14; i++) {
        NSString *str = [NSString stringWithFormat:@"%d",i];
        [arr addObject:str];
    }
    NSArray *arrA = @[@[arr[ShowFunctionFile],arr[ShowFunctionCollectionAD],arr[ShowFunctionStarRate],arr[ShowFunctionSegmented],arr[ShowFunctionTagLabel],@"",@"",@"",arr[ShowFunctionCountryCodeSelect]],@[@[@"",@""]],@[arr[ShowFunctionInputView]],@[arr[ShowFunctionViewCorner]],@[arr[ShowFunctionLabelThroughLine],arr[ShowFunctionLabelCountingLabel]],@[arr[ShowFunctionShowAlert]],@[arr[ShowFunctionPicker]],@[arr[ShowFunctionCountryLoading]],@[arr[ShowFunctionAboutImage]]];
    NSMutableArray *arrB = [[NSMutableArray alloc] initWithArray:arrA];
    return arrB;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case 0:
        {
            switch (indexPath.row) {
                case 5:
                {
                    PNSLog(@"123");
                }
                    break;
                case 6:
                {
                    
                    
                    PTViewerModel *imageModelV = [[PTViewerModel alloc] init];
                    imageModelV.imageURL = @"http://p3.music.126.net/VDn1p3j4g2z4p16Gux969w==/2544269907756816.jpg";
                    imageModelV.imageShowType = PTViewerDataTypeNormal;
                    imageModelV.imageInfo = @"56555555555555655555555555565555555555556555555555555655555555555565555555555556555555555555655555555555565555555555556555555555555655555555555565555555555556555555555555655555555555565555555555556555555555555655555555555565555555555556555555555555655555555555565555555555556555555555555655555555555565555555555556555555555555655555555555565555555555556555555555555655555555555565555555555556555555555551312333444444>>>>>>>>>>>>>>>>>>>>>";
                    
                    PTViewerModel *imageModel1 = [[PTViewerModel alloc] init];
                    imageModel1.imageURL = @"http://p3.music.126.net/VDn1p3j4g2z4p16Gux969w==/2544269907756816.jpg";
                    imageModel1.imageShowType = PTViewerDataTypeNormal;
                    imageModel1.imageInfo = @"123";

                    PTViewerModel *imageModel1aaaa = [[PTViewerModel alloc] init];
                    imageModel1aaaa.imageURL = @"http://clips.vorwaerts-gmbh.de/big_buck_bunny.mp4";
                    imageModel1aaaa.imageShowType = PTViewerDataTypeVideo;
                    imageModel1aaaa.imageInfo = @"123";

                    PTViewerModel *imageModel1aaaag = [[PTViewerModel alloc] init];
                    imageModel1aaaag.imageURL = @"http://img.t.sinajs.cn/t35/style/images/common/face/ext/normal/7a/shenshou_thumb.gif";
                    imageModel1aaaag.imageShowType = PTViewerDataTypeGIF;
                    imageModel1aaaag.imageInfo = @"12344444";

                    PTViewerConfig *config = [[PTViewerConfig alloc] init];
                    config.actionType = PTViewerActionTypeAll;
                    config.closeViewerImageName = @"DemoImage";
                    config.moreActionImageName = @"DemoImage";
                    config.mediaData = @[imageModelV,imageModel1,imageModel1aaaa,imageModel1aaaag];
                    
                    PTMediaViewer *viewer = [[PTMediaViewer alloc] initWithViewConfig:config];
                    [viewer showImageViewer];
                    [viewer setViewerDismissBlock:^{
                        
                    }];
//
//
//
////                    PooShowImageModel *imageModel = [[PooShowImageModel alloc] init];
////                    imageModel.imageUrl = @"http://p3.music.126.net/VDn1p3j4g2z4p16Gux969w==/2544269907756816.jpg";
////                    imageModel.imageShowType = PooShowImageModelTypeFullView;
////                    imageModel.imageInfo = @"11111111241241241241928390128309128";
////                    imageModel.imageTitle = @"22222212312312312312312312312";
////
//                    PooShowImageModel *imageModelV = [[PooShowImageModel alloc] init];
//                    imageModelV.imageUrl = @"http://clips.vorwaerts-gmbh.de/big_buck_bunny.mp4";
//                    imageModelV.imageShowType = PooShowImageModelTypeVideo;
//                    imageModelV.imageInfo = @"11111111241241241241928390128309128";
//
//
//                    //    PooShowImageModel *imageModel1 = [[PooShowImageModel alloc] init];
//                    //    imageModel1.imageUrl = @"http://p3.music.126.net/VDn1p3j4g2z4p16Gux969w==/2544269907756816.jpg";
//                    //    imageModel1.imageFullView = @"0";
//                    //    imageModel1.imageInfo = @"444444";
//                    //    imageModel1.imageTitle = @"333333";
//
////                    PooShowImageModel *imageModel2 = [[PooShowImageModel alloc] init];
////                    imageModel2.imageUrl = @"http://ww4.sinaimg.cn/bmiddle/677febf5gw1erma1g5xd0j20k0esa7wj.jpg";
////                    imageModel2.imageShowType = PooShowImageModelTypeNormal;
////                    imageModel2.imageInfo = @"4444444444444";
////
////                    PooShowImageModel *imageModelT = [[PooShowImageModel alloc] init];
////                    imageModelT.imageUrl = @"http://ww4.sinaimg.cn/bmiddle/677febf5gw1erma1g5xd0j20k0esa7wj.jpg";
////                    imageModelT.imageShowType = PooShowImageModelTypeNormal;
////                    imageModelT.imageInfo = @"6666666";
////                    imageModelT.imageTitle = @"5555555";
////
////                    PooShowImageModel *imageModel3 = [[PooShowImageModel alloc] init];
////                    imageModel3.imageUrl = @"https://timgsa.baidu.com/timg?image&quality=80&size=b9999_10000&sec=1535114837724&di=c006441b6c288352e1fcdfc7b47db2b3&imgtype=0&src=http%3A%2F%2Fimg5.duitang.com%2Fuploads%2Fitem%2F201412%2F13%2F20141213142127_yXadz.thumb.700_0.gif";
////                    imageModel3.imageShowType = PooShowImageModelTypeGIF;
////                    imageModel3.imageInfo = @"444444";
////                    imageModel3.imageTitle = @"333333";
//
////                    PooShowImageModel *imageModel4 = [[PooShowImageModel alloc] init];
////                    imageModel4.imageUrl = kImageNamed(@"DemoImage");
////                    imageModel4.imageShowType = PooShowImageModelType3D;
////                    imageModel4.imageInfo = @"3333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333";
//
//                    PooShowImageModel *imageModel100 = [[PooShowImageModel alloc] init];
//                    imageModel100.imageUrl = @"https://www.cloudgategz.com/chl/photo/allPic.jpg";
//                    imageModel100.imageShowType = PooShowImageModelTypeFullView;
//                    imageModel100.imageInfo = @"5655555555555";
//
//                    PooShowImageModel *imageModel1001 = [[PooShowImageModel alloc] init];
//                    imageModel1001.imageUrl = @"https://www.cloudgategz.com/chl/photo/allPic.jpg";
//                    imageModel1001.imageShowType = PooShowImageModelTypeNormal;
//                    imageModel1001.imageInfo = @"5655555555555565555555555556555555555555655555555555565555555555556555555555555655555555555565555555555556555555555555655555555555565555555555556555555555555655555555555565555555555556555555555555655555555555565555555555556555555555555655555555555565555555555556555555555555655555555555565555555555556555555555555655555555555565555555555556555555555555655555555555565555555555556555555555555655555555555";
//
////                    NSArray *arr = @[imageModel2,imageModel3,imageModelT,imageModel4];
//                    NSArray *arr = @[imageModelV,imageModel100];
//
//                    YMShowImageView *ymImageV = [[YMShowImageView alloc] initWithByClick:YMShowImageViewClickTagAppend+0 appendArray:arr titleColor:nil font:[UIFont fontWithName:FontName size:20] showImageBackgroundColor:[UIColor blackColor] showWindow:[PTAppDelegate appDelegate].window loadingImageName:@"DemoImage" deleteAble:YES saveAble:YES moreActionImageName:@"DemoImage" hideImageName:@"DemoImage"];
//                    [ymImageV showWithFinish:^{
//                    }];
//                    [ymImageV mas_makeConstraints:^(MASConstraintMaker *make) {
//                        make.left.right.top.bottom.equalTo([PTAppDelegate appDelegate].window);
//                    }];
//                    [ymImageV setOtherBlock:^(NSInteger index) {
//                        PNSLog(@"%ld",(long)index);
//
//                        WKWebView *webView = [WKWebView new];
//                        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"https://www.cloudgategz.com/chl/photo/photograph.html"]];
//                        [webView loadRequest:request];
//                        [kAppDelegateWindow addSubview:webView];
//                        [webView mas_makeConstraints:^(MASConstraintMaker *make) {
//                            make.left.right.top.bottom.equalTo(kAppDelegateWindow);
//                        }];
////                        UIWebView *webView = [UIWebView new];
////                        NSURLRequest *request =[NSURLRequest requestWithURL:[NSURL URLWithString:@"https://www.cloudgategz.com/chl/photo/photograph.html"]];
////                        [webView loadRequest:request];
////                        [kAppDelegateWindow addSubview:webView];
////                        [webView mas_makeConstraints:^(MASConstraintMaker *make) {
////                            make.left.right.top.bottom.equalTo(kAppDelegateWindow);
////                        }];
////                        UIView *aaaaa = [UIView new];
////                        aaaaa.backgroundColor = kRandomColor;
////                        [kAppDelegateWindow addSubview:aaaaa];
////                        [aaaaa mas_makeConstraints:^(MASConstraintMaker *make) {
////                            make.left.right.top.bottom.equalTo(kAppDelegateWindow);
////                        }];
//
//                        UIButton *pBtn = [UIButton buttonWithType:UIButtonTypeCustom];
//                        pBtn.frame = CGRectMake(0, 0, 50, 50);
//                        pBtn.backgroundColor = kRandomColor;
//                        [pBtn setTitleColor:kRandomColor forState:UIControlStateNormal];
//                        [pBtn setTitle:@"1111" forState:UIControlStateNormal];
//                        [pBtn addActionHandlersWithHandler:^(UIButton *sender) {
//                            [webView removeFromSuperview];
//                        }];
//                        [webView addSubview:pBtn];
//                    }];
//                    ymImageV.saveImageStatus = ^(BOOL saveStatus) {
//                        PNSLog(@"%d",saveStatus);
//                    };
                    
                }
                    break;
                case 7:
                {
                    self.touchID = [PTBiologyID shared];
                    self.touchID.biologyStatusBlock = ^(PTBiologyStatus biologyIDType) {
                        PNSLog(@"%ld",(long)biologyIDType);
                    };
                    [self.touchID biologyStartWithAlertTitle:@"123123123123123"];
//                    self.touchID = [PBiologyID defaultBiologyID];
//                    self.touchID.biologyIDBlock = ^(BiologyIDType biologyIDType) {
//                        PNSLog(@"%ld",(long)biologyIDType);
//                    };
//                    [self.touchID biologyAction];
                }
                    break;
                    
                default:
                {
                    PTShowFunctionViewController *view  = [[PTShowFunctionViewController alloc] initWithShowFunctionType:[self.typeArr[indexPath.section][indexPath.row] integerValue]];
                    [self.navigationController pushViewController:view animated:YES];
                }
                    break;
            }
        }
            break;
        case 1:
        {
            switch (indexPath.row) {
                case 1:
                {
                    [PTPhoneBlock callPhoneNumberWithPhoneNumber:@"13800138000" call:^(NSTimeInterval duration) {
                        
                    } cancel:^{
                        
                    } canCall:^(BOOL finish) {
                        
                    }];
                }
                    break;
                case 2:
                {
                    if ([PCleanCache clearCaches]) {
                        [Utils alertVCOnlyShowWithTitle:nil andMessage:@"清理成功"];
                        self.tableArr = [[NSMutableArray alloc] initWithArray:self.tableNameArr];
                        GCDAfter(0.1, ^{
                            [self.tbView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:2 inSection:1]] withRowAnimation:UITableViewRowAnimationNone];
                        });
                    }
                    else
                    {
                        [Utils alertVCOnlyShowWithTitle:nil andMessage:@"没有缓存"];
                    }
                }
                    break;
                default:
                    break;
            }
        }
            break;
        case 8:
        {
            switch (indexPath.row) {
                case 1:
                {
                    PTCodeView *codeView = [[PTCodeView alloc] initWithFrame:CGRectZero numberOfCodes:4 numberOfLines:3 changeTimes:3];
                    [self createAlertViewWithTitle:@"验证码图片" withAlertBtns:@[@"222"] customeViewHeight:100 initCustomView:^(UIView *customView) {
                        [customView addSubview:codeView];
                        [codeView mas_makeConstraints:^(MASConstraintMaker *make) {
                            make.centerX.centerY.equalTo(customView);
                            make.width.height.offset(100);
                        }];
                        codeView.codeBlock = ^(PTCodeView * codeView, NSString * codeString) {
                            PNSLog(@">>>>>>>>%@",codeString);
                        };
                    } alertBtnTapBlock:^(NSInteger btnIndex) {
                        
                    } alertDismissBlock:^{
                    }];
                }
                    break;
                default:
                {
                    PTShowFunctionViewController *view  = [[PTShowFunctionViewController alloc] initWithShowFunctionType:[self.typeArr[indexPath.section][indexPath.row] integerValue]];
                    [self.navigationController pushViewController:view animated:YES];
                }
                    break;
            }
        }
            break;
        case 9:
        {
//            [MXRotationManager defaultManager].orientation = UIDeviceOrientationLandscapeRight;
//            PopSignatureView *socialSingnatureView = [[PopSignatureView alloc] initWithNavColor:kRandomColor maskString:nil withViewFontName:FontName withNavFontName:FontNameBold withLinePathWidth:10 withBtnTitleColor:kRandomColor handleDone:^(PopSignatureView *signView, UIImage *signImage) {
//                [MXRotationManager defaultManager].orientation = UIDeviceOrientationPortrait;
//            } handleCancle:^(PopSignatureView *signView) {
//                [MXRotationManager defaultManager].orientation = UIDeviceOrientationPortrait;
//            }];
//            [socialSingnatureView show];
            
            PTSignatureConfig *signConfig = [PTSignatureConfig new];
            PTSignView *socialSingnatureView = [[PTSignView alloc] initWithViewConfig:signConfig];
            [socialSingnatureView showView];
            socialSingnatureView.doneBlock = ^(UIImage * iamge) {
                
            };
            socialSingnatureView.dismissBlock = ^{
                
            };
        }
            break;
        case 10:
        {
            NSUInteger r = arc4random_uniform(6);
            [MXRotationManager defaultManager].orientation = r;
        }
            break;
        case 11:
        {
            [self createAlertViewWithTitle:@"Slider" withAlertBtns:@[@"222"] customeViewHeight:200 initCustomView:^(UIView *customView) {
                
                PTSlider *slider = [[PTSlider alloc] initWithShowTitle:YES];
                [customView addSubview:slider];
                [slider mas_makeConstraints:^(MASConstraintMaker *make) {
                    make.width.offset(100);
                    make.height.offset(80);
                    make.centerX.equalTo(customView);
                    make.top.equalTo(customView).offset(5);
                }];

//                DoubleSliderView *dSlider = [DoubleSliderView new];
//                [customView addSubview:dSlider];
//                [dSlider mas_makeConstraints:^(MASConstraintMaker *make) {
//                    make.width.offset(kSCREEN_WIDTH - 40);
//                    make.height.offset(50);
//                    make.centerX.equalTo(customView);
//                    make.top.equalTo(slider.mas_bottom).offset(5);
//                }];
            } alertBtnTapBlock:^(NSInteger btnIndex) {
                
            } alertDismissBlock:^{
                
            }];
        }
            break;
        default:
        {
            PTShowFunctionViewController *view  = [[PTShowFunctionViewController alloc] initWithShowFunctionType:[self.typeArr[indexPath.section][indexPath.row] integerValue]];
            [self.navigationController pushViewController:view animated:YES];
        }
            break;
    }
}

-(BOOL)shouldAutorotate
{
    return YES;
}

-(void)createAlertViewWithTitle:(NSString *)alertTitle withAlertBtns:(NSArray *)btns customeViewHeight:(CGFloat)cH initCustomView:(void (^)(UIView *customView))createBlock alertBtnTapBlock:(void (^)(NSInteger btnIndex))tapBlock alertDismissBlock:(void (^)(void))dBlock
{
    NSMutableArray <PTCustomBottomButtonModel *>*arr = [NSMutableArray array];
    for (NSString *title in btns) {
        PTCustomBottomButtonModel *models = [[PTCustomBottomButtonModel alloc] init];
        models.titleColor = UIColor.redColor;
        models.titleName = title;
        [arr addObject:models];
    }
            
    PTCustomAlertView * alerts = [[PTCustomAlertView alloc] initWithSuperView:[PTAppDelegate appDelegate].window alertTitle:alertTitle font:kDEFAULT_FONT(FontName, 15) titleColor:kRandomColor alertVerLineColor:kRandomColor alertBackgroundColor:kRandomColor heightlightedColor:kRandomColor moreButtons:arr];
    [alerts mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.offset(cH+[PTCustomAlertView titleAndBottomViewNormalHeightWithWidth:kSCREEN_WIDTH-20 title:alertTitle font:kDEFAULT_FONT(FontName, 15) buttonArray:arr]);
        make.width.offset(kSCREEN_WIDTH-20);
        make.centerX.centerY.equalTo([PTAppDelegate appDelegate].window);
    }];
    alerts.customerBlock = ^(UIView * customerView) {
        createBlock(customerView);
    };
    alerts.buttonClick = ^(PTCustomAlertView * alertView, NSInteger buttonIndex) {
        tapBlock(buttonIndex);
        [alertView dismiss];
    };
    alerts.didDismissBlock = ^(PTCustomAlertView * alertView) {
        dBlock();
    };
}

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller
{
    return UIModalPresentationNone;
}

@end
