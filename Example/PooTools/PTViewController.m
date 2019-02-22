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
#import "PBiologyID.h"
#import "YMShowImageView.h"
#import "PTAppDelegate.h"
#import "PVideoViewController.h"
#import "UITextField+ModifyPlaceholder.h"
#import "UIView+ViewShaking.h"
#import "SensitiveWordTools.h"
#import "PopSignatureView.h"

#import "PTShowFunctionViewController.h"

#import <Masonry/Masonry.h>
#import <IQKeyboardManager/IQKeyboardManager.h>

#import "PCarrie.h"
#import "PooSystemInfo.h"
#import "PooPhoneBlock.h"
#import "PooCleanCache.h"

#define FontName @"HelveticaNeue-Light"
#define FontNameBold @"HelveticaNeue-Medium"

#define APPFONT(R) kDEFAULT_FONT(FontName,kAdaptedWidth(R))

@interface PTViewController ()<PVideoViewControllerDelegate,UITableViewDelegate,UITableViewDataSource>
{
    UITableView *tbView;
}
@property (nonatomic, strong) PBiologyID *touchID;
@property (nonatomic, strong) NSMutableArray *tableArr;
@property (nonatomic, strong) NSMutableArray *tableHeaderTitle;

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
    
    NSString *string = [NSString stringWithFormat:@"含有敏感词汇：%@",[[SensitiveWordTools sharedInstance]filter:@"裸体"]];
    PNSLog(@"%@",string);
   
    self.tableArr = [[NSMutableArray alloc] initWithArray:@[@[@"网页上传文件",@"广告展示功能",@"简单的评价界面",@"Segment",@"TagLabel",@"拍摄小视频",@"图片展示",@"生物识别",@"国家/国家代号选择"],@[@"手机判断",@"打电话到13800138000",[NSString stringWithFormat:@"获取缓存%@,并清理",[PooCleanCache getCacheSize]]],@[@"输入控件"],@[@"界面展示某个圆角"],@[@"Label的下划线",@"数字跳动Label"],@[@"各种弹出框"],@[@"Picker"],@[@"Loading"],@[@"关于图片"],@[@"签名"]]];
    self.tableHeaderTitle = [[NSMutableArray alloc] initWithArray:@[@"其他",@"关于手机",@"文字输入",@"View的处理",@"Label",@"弹出框",@"Picker",@"Loading",@"图片",@"签名"]];
    
    tbView    = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    tbView.dataSource                     = self;
    tbView.delegate                       = self;
    tbView.showsHorizontalScrollIndicator = NO;
    tbView.showsVerticalScrollIndicator   = NO;
    tbView.separatorStyle                 = UITableViewCellSeparatorStyleSingleLine;
    [self.view addSubview:tbView];
    [tbView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.top.bottom.equalTo(self.view);
    }];
    
    kAdaptedOtherFontSize(@"", 16);
    
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

#pragma mark - PVideoViewControllerDelegate
- (void)videoViewController:(PVideoViewController *)videoController didRecordVideo:(PVideoModel *)videoModel
{
    NSLog(@"%@>>>>>>>>>>%@>>>>>>>>>",videoController,videoModel);
    
    //    _videoModel = videoModel;
    //
    //    videoUrl = [NSURL fileURLWithPath:_videoModel.videoAbsolutePath];
    //    NSLog(@"----------------------------VideoPath:%@",videoUrl);
    //    [self.videoUrlArr addObject:videoUrl];
    //    NSError *error = nil;
    //    NSFileManager *fm = [NSFileManager defaultManager];
    //    NSDictionary *attri = [fm attributesOfItemAtPath:_videoModel.videoAbsolutePath error:&error];
    //    if (error) {
    //        NSLog(@"error:%@",error);
    //    }
    //    else {
    //        NSLog(@"%@",[NSString stringWithFormat:@"视频总大小:%.0fKB",attri.fileSize/1024.0]);
    //    }
    //
    //    imageVideo = [[UIImageView alloc] initWithFrame:videoV.bounds];
    //    imageVideo.image = [Utils thumbnailImageForVideo:videoUrl atTime:1];
    //    [videoV addSubview:imageVideo];
    //
    //    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:2]];
    //
    //    videoDeleteBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    //    videoDeleteBtn.frame = CGRectMake(imageVideo.width-30, 0, 30, 30);
    //    [videoDeleteBtn setImage:kImageNamed(@"list_icon_delete") forState:UIControlStateNormal];
    //    [videoDeleteBtn addTarget:self action:@selector(deleteVideoFirstView:) forControlEvents:UIControlEventTouchUpInside];
    //    [cell.contentView addSubview:videoDeleteBtn];
    //
    //    [self movChangeMP4:videoUrl];
}

- (void)videoViewControllerDidCancel:(PVideoViewController *)videoController {
    NSLog(@"没有录到视频");
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
                    
                    NSString *isJailBroken;
                    if ([PooSystemInfo isJailBroken]) {
                        isJailBroken = @"是";
                    }
                    else
                    {
                        isJailBroken = @"否";
                    }
                    
                    UILabel *infoLabel = [UILabel new];
                    infoLabel.textColor = [UIColor blackColor];
                    infoLabel.textAlignment = NSTextAlignmentCenter;
                    infoLabel.numberOfLines = 0;
                    infoLabel.lineBreakMode = NSLineBreakByCharWrapping;
                    infoLabel.text = [NSString stringWithFormat:@"是否iPhoneX?%@.运营商:%@.是否越狱了?%@.机型:%@",isiPhoneX,[PCarrie currentRadioAccessTechnology],isJailBroken,[PooSystemInfo getDeviceVersion]];
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
                    PVideoViewController *videoVC = [[PVideoViewController alloc] initWithRecordTime:20 video_W_H:(4.0/3) withVideoWidthPX:200 withControViewHeight:120];
                    videoVC.delegate = self;
                    [videoVC startAnimationWithType:PVideoViewShowTypeSmall];
                }
                    break;
                case 6:
                {
//                    PooShowImageModel *imageModel = [[PooShowImageModel alloc] init];
//                    imageModel.imageUrl = @"http://p3.music.126.net/VDn1p3j4g2z4p16Gux969w==/2544269907756816.jpg";
//                    imageModel.imageShowType = PooShowImageModelTypeFullView;
//                    imageModel.imageInfo = @"11111111241241241241928390128309128";
//                    imageModel.imageTitle = @"22222212312312312312312312312";
//
//                    PooShowImageModel *imageModelV = [[PooShowImageModel alloc] init];
//                    imageModelV.imageUrl = @"http://clips.vorwaerts-gmbh.de/big_buck_bunny.mp4";
//                    imageModelV.imageShowType = PooShowImageModelTypeVideo;
//                    imageModelV.imageInfo = @"11111111241241241241928390128309128";
//                    imageModelV.imageTitle = @"22222212312312312312312312312";
                    
                    
                    //    PooShowImageModel *imageModel1 = [[PooShowImageModel alloc] init];
                    //    imageModel1.imageUrl = @"http://p3.music.126.net/VDn1p3j4g2z4p16Gux969w==/2544269907756816.jpg";
                    //    imageModel1.imageFullView = @"0";
                    //    imageModel1.imageInfo = @"444444";
                    //    imageModel1.imageTitle = @"333333";
                    
                    PooShowImageModel *imageModel2 = [[PooShowImageModel alloc] init];
                    imageModel2.imageUrl = @"http://ww4.sinaimg.cn/bmiddle/677febf5gw1erma1g5xd0j20k0esa7wj.jpg";
                    imageModel2.imageShowType = PooShowImageModelTypeNormal;
                    imageModel2.imageInfo = @"4444444444444";
//
//                    PooShowImageModel *imageModelT = [[PooShowImageModel alloc] init];
//                    imageModelT.imageUrl = @"http://ww4.sinaimg.cn/bmiddle/677febf5gw1erma1g5xd0j20k0esa7wj.jpg";
//                    imageModelT.imageShowType = PooShowImageModelTypeNormal;
//                    imageModelT.imageInfo = @"6666666";
//                    imageModelT.imageTitle = @"5555555";
//
//                    PooShowImageModel *imageModel3 = [[PooShowImageModel alloc] init];
//                    imageModel3.imageUrl = @"https://timgsa.baidu.com/timg?image&quality=80&size=b9999_10000&sec=1535114837724&di=c006441b6c288352e1fcdfc7b47db2b3&imgtype=0&src=http%3A%2F%2Fimg5.duitang.com%2Fuploads%2Fitem%2F201412%2F13%2F20141213142127_yXadz.thumb.700_0.gif";
//                    imageModel3.imageShowType = PooShowImageModelTypeGIF;
//                    imageModel3.imageInfo = @"444444";
//                    imageModel3.imageTitle = @"333333";
                    
                    PooShowImageModel *imageModel4 = [[PooShowImageModel alloc] init];
                    imageModel4.imageUrl = kImageNamed(@"DemoImage");
                    imageModel4.imageShowType = PooShowImageModelTypeNormal;
                    imageModel4.imageInfo = @"333333333333333";
                    
//                    NSArray *arr = @[imageModel2,imageModel3,imageModelT,imageModel4];
                    NSArray *arr = @[imageModel4,imageModel2,imageModel2,imageModel2];

                    YMShowImageView *ymImageV = [[YMShowImageView alloc] initWithByClick:YMShowImageViewClickTagAppend+0 appendArray:arr titleColor:nil fontName:FontName showImageBackgroundColor:[UIColor blackColor] showWindow:[PTAppDelegate appDelegate].window loadingImageName:@"DemoImage" deleteAble:YES saveAble:YES moreActionImageName:@"DemoImage" hideImageName:@"DemoImage"];
                    [ymImageV showWithFinish:^{
                        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
                    }];
                    [ymImageV mas_makeConstraints:^(MASConstraintMaker *make) {
                        make.left.right.top.bottom.equalTo([PTAppDelegate appDelegate].window);
                    }];
                    ymImageV.saveImageStatus = ^(BOOL saveStatus) {
                        PNSLog(@"%d",saveStatus);
                    };
                    
                }
                    break;
                case 7:
                {
                    self.touchID = [PBiologyID defaultBiologyID];
                    self.touchID.biologyIDBlock = ^(BiologyIDType biologyIDType) {
                        PNSLog(@"%ld",(long)biologyIDType);
                    };
                    [self.touchID biologyAction];
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
                    [PooPhoneBlock callPhoneNumber:@"13800138000" call:^(NSTimeInterval duration) {
                        
                    } cancel:^{
                        
                    }];
                }
                    break;
                case 2:
                {
                    if ([PooCleanCache clearCaches]) {
                        [Utils alertShowWithMessage:@"清理成功"];
                        [tbView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:2 inSection:1]] withRowAnimation:UITableViewRowAnimationNone];
                    }
                }
                    break;
                default:
                    break;
            }
        }
            break;
        case 9:
        {
            PopSignatureView *socialSingnatureView = [[PopSignatureView alloc] initWithNavColor:kRandomColor maskString:nil withViewFontName:FontName withNavFontName:FontNameBold];
//            socialSingnatureView.delegate = self;
            [socialSingnatureView show];
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

@end
