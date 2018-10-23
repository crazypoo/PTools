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
#import "PStarRateView.h"
#import "PADView.h"
#import "PLabel.h"
#import "PVideoViewController.h"
#import "UIView+ViewRectCorner.h"
#import "UITextField+ModifyPlaceholder.h"
#import "UIView+ViewShaking.h"
#import "CountryCodes.h"
#import "PGetIpAddresses.h"

#import <Masonry/Masonry.h>
#import <IQKeyboardManager/IQKeyboardManager.h>
#import <GCDWebServer/GCDWebUploader.h>

#define FontName @"HelveticaNeue-Light"
#define FontNameBold @"HelveticaNeue-Medium"

#define APPFONT(R) kDEFAULT_FONT(FontName,kAdaptedWidth(R))

@interface PTViewController ()<PooNumberKeyBoardDelegate,PVideoViewControllerDelegate,PooTimePickerDelegate,GCDWebUploaderDelegate,UITableViewDelegate,UITableViewDataSource>
{
    UITableView *tbView;
}
@property (nonatomic, strong) PBiologyID *touchID;
@property (nonatomic, strong) UITextField *textField;
@property (nonatomic, strong) GCDWebUploader *webServer;
@property (nonatomic, strong) NSMutableArray *tableArr;
@property (nonatomic, strong) NSMutableArray *tableHeaderTitle;

@end

@implementation PTViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    [self.webServer stop];
    self.webServer = nil;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    CountryCodeModel *model = [CountryCodes countryCodes][1];
    PNSLog(@"%@-----%@",model.countryName,model.countryCode);
    
    self.tableArr = [[NSMutableArray alloc] initWithArray:@[@[@"网页上传文件",@"广告展示功能",@"简单的评价界面",@"Segment",@"TagLabel",@"拍摄小视频",@"图片展示",@"生物识别"],@[@"手机判断"],@[@"数字键盘展示",@"SearchBar"],@[@"界面展示某个圆角"],@[@"label的下划线"],@[@"ActionSheet",@"CustomAlertView",@"系统自带AlertView的封装"]]];
    self.tableHeaderTitle = [[NSMutableArray alloc] initWithArray:@[@"其他",@"关于手机",@"文字输入",@"View的处理",@"Label",@"弹出框"]];
    
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
//    PooDatePicker *view = [[PooDatePicker alloc] initWithTitle:@"1111" toolBarBackgroundColor:kRandomColor labelFont:APPFONT(16) toolBarTitleColor:kRandomColor pickerFont:APPFONT(16) pickerType:PPickerTypeY];
//    [self.view addSubview:view];
//    [view mas_makeConstraints:^(MASConstraintMaker *make) {
//        make.left.right.top.bottom.equalTo(self.view);
//    }];
//    view.block = ^(NSString *dateString) {
//        PNSLog(@">>>>>>>>>>>%@",dateString);
//    };
    
    PooTimePicker *view = [[PooTimePicker alloc] initWithTitle:@"1111" toolBarBackgroundColor:kRandomColor labelFont:APPFONT(16) toolBarTitleColor:kRandomColor pickerFont:APPFONT(16)];
    view.delegate = self;
    [[PTAppDelegate appDelegate].window addSubview:view];
    [view mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.top.bottom.equalTo(self.view);
    }];
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
//    [self.textField ViewUI_viewShaking];
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

-(void)timePickerReturnStr:(NSString *)timeStr timePicker:(PooTimePicker *)timePicker
{
    PNSLog(@">>>>>>>>>>>>>%@",timeStr);
}

-(void)timePickerDismiss:(PooTimePicker *)timePicker
{
    PNSLog(@">>>>>>>>>>>>>%@",timePicker);
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
    
    switch (indexPath.section) {
            case 0:
        {
            switch (indexPath.row) {
                    case 0:
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
                    [cell.contentView addSubview:infoLabel];
                    [infoLabel mas_makeConstraints:^(MASConstraintMaker *make) {
                        make.top.equalTo(functionName.mas_bottom);
                        make.left.right.bottom.equalTo(cell.contentView);
                    }];

                }
                    break;
                case 1:
                {
                    CGAdBannerModel *aaaaa = [[CGAdBannerModel alloc] init];
                    aaaaa.bannerTitle = @"111111";
                    
                    PADView *adaaaa = [[PADView alloc] initWithAdArray:@[aaaaa,aaaaa] singleADW:kSCREEN_WIDTH singleADH:150 paddingY:5 paddingX:5 placeholderImage:@"DemoImage" pageTime:1 adTitleFont:kDEFAULT_FONT(FontName, 19)];
                    [cell.contentView addSubview:adaaaa];
                    [adaaaa mas_makeConstraints:^(MASConstraintMaker *make) {
                        make.top.equalTo(functionName.mas_bottom);
                        make.left.right.bottom.equalTo(cell.contentView);
                    }];

                }
                    break;
                case 2:
                {
                    PStarRateView *rV = [[PStarRateView alloc] initWithRateBlock:^(PStarRateView *rateView, CGFloat newScorePercent) {
                    }];
                    rV.backgroundColor = kRandomColor;
                    rV.scorePercent = 0.5;
                    rV.hasAnimation = NO;
                    rV.allowIncompleteStar = NO;
                    [cell.contentView addSubview:rV];
                    [rV mas_makeConstraints:^(MASConstraintMaker *make) {
                        make.top.equalTo(functionName.mas_bottom);
                        make.left.right.bottom.equalTo(cell.contentView);
                    }];
                }
                    break;
                    case 3:
                {
                    PooSegView *seg = [[PooSegView alloc] initWithTitles:@[@"1",@"2"] titleNormalColor:[UIColor lightGrayColor] titleSelectedColor:[UIColor redColor] titleFont:APPFONT(16) setLine:YES lineColor:[UIColor blackColor] lineWidth:1 selectedBackgroundColor:[UIColor yellowColor] normalBackgroundColor:[UIColor blueColor] showType:PooSegShowTypeUnderLine clickBlock:^(PooSegView *segViewView, NSInteger buttonIndex) {
                        
                    }];
                    [cell.contentView addSubview:seg];
                    [seg mas_makeConstraints:^(MASConstraintMaker *make) {
                        make.top.equalTo(functionName.mas_bottom);
                        make.left.right.bottom.equalTo(cell.contentView);
                    }];

                }
                    break;
                    case 4:
                {
                    NSArray *titleS = @[@"7"];
                    
                    PooTagsLabelConfig *config = [[PooTagsLabelConfig alloc] init];
                    config.itemHeight = 40;
                    config.itemWidth = 40;
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
                    config.showStatus = PooTagsLabelShowWithImageStatusNoTitle;
                    
                    //    NSArray *normalImage = @[@"image_day_normal_7",@"image_day_normal_1",@"image_day_normal_2",@"image_day_normal_3",@"image_day_normal_4",@"image_day_normal_5",@"image_day_normal_6"];
                    //    NSArray *selectImage = @[@"image_day_select_7",@"image_day_select_1",@"image_day_select_2",@"image_day_select_3",@"image_day_select_4",@"image_day_select_5",@"image_day_select_6"];
                    NSArray *title = @[@"7",@"1",@"2",@"3",@"1231231231314124"];
                    
                    PooTagsLabel *tag = [[PooTagsLabel alloc] initWithTagsArray:title config:config wihtSection:0];
                    //    PooTagsLabel *tag = [[PooTagsLabel alloc] initWithFrame:CGRectZero tagsNormalArray:normalImage tagsSelectArray:selectImage tagsTitleArray:title config:config wihtSection:0];
                    tag.backgroundColor = kRandomColor;
                    [cell.contentView addSubview:tag];
                    [tag mas_makeConstraints:^(MASConstraintMaker *make) {
                        make.top.equalTo(functionName.mas_bottom);
                        make.left.right.bottom.equalTo(cell.contentView);
                    }];
                    tag.tagHeightBlock = ^(PooTagsLabel *aTagsView, CGFloat viewHeight) {
                        PNSLog(@"%f",viewHeight);
                    };

                }
                    break;
                    case 5:
                {
                    UILabel *infoLabel = [UILabel new];
                    infoLabel.textColor = [UIColor blackColor];
                    infoLabel.textAlignment = NSTextAlignmentCenter;
                    infoLabel.numberOfLines = 0;
                    infoLabel.lineBreakMode = NSLineBreakByCharWrapping;
                    infoLabel.text = @"点我拍摄小视频";
                    [cell.contentView addSubview:infoLabel];
                    [infoLabel mas_makeConstraints:^(MASConstraintMaker *make) {
                        make.top.equalTo(functionName.mas_bottom);
                        make.left.right.bottom.equalTo(cell.contentView);
                    }];
                }
                    break;
                    case 6:
                {
                    UILabel *infoLabel = [UILabel new];
                    infoLabel.textColor = [UIColor blackColor];
                    infoLabel.textAlignment = NSTextAlignmentCenter;
                    infoLabel.numberOfLines = 0;
                    infoLabel.lineBreakMode = NSLineBreakByCharWrapping;
                    infoLabel.text = @"点我展示图片";
                    [cell.contentView addSubview:infoLabel];
                    [infoLabel mas_makeConstraints:^(MASConstraintMaker *make) {
                        make.top.equalTo(functionName.mas_bottom);
                        make.left.right.bottom.equalTo(cell.contentView);
                    }];
                }
                    break;
                    case 7:
                {
                    UILabel *infoLabel = [UILabel new];
                    infoLabel.textColor = [UIColor blackColor];
                    infoLabel.textAlignment = NSTextAlignmentCenter;
                    infoLabel.numberOfLines = 0;
                    infoLabel.lineBreakMode = NSLineBreakByCharWrapping;
                    infoLabel.text = @"点我展示生物技术";
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
        case 1:
        {
            switch (indexPath.row) {
                    case 0:
                {
                    NSString *isiPhoneX;
                    if (isIPhoneXSeries()) {
                        isiPhoneX = @"是";
                    }
                    else
                    {
                        isiPhoneX = @"否";
                    }
                    UILabel *infoLabel = [UILabel new];
                    infoLabel.textColor = [UIColor blackColor];
                    infoLabel.textAlignment = NSTextAlignmentCenter;
                    infoLabel.numberOfLines = 0;
                    infoLabel.lineBreakMode = NSLineBreakByCharWrapping;
                    infoLabel.text = [NSString stringWithFormat:@"是否iPhoneX?%@",isiPhoneX];
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
        {
            switch (indexPath.row) {
                    case 0:
                {
                    PooNumberKeyBoard *userNameKeyboard = [PooNumberKeyBoard pooNumberKeyBoardWithDog:YES backSpace:^(PooNumberKeyBoard *keyboardView) {
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
                    [cell.contentView addSubview:self.textField];
                    [self.textField mas_makeConstraints:^(MASConstraintMaker *make) {
                        make.top.equalTo(functionName.mas_bottom);
                        make.left.right.bottom.equalTo(cell.contentView);
                    }];

                }
                    break;
                    case 1:
                {
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
                    [cell.contentView addSubview:searchBar];
                    [searchBar mas_makeConstraints:^(MASConstraintMaker *make) {
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
            case 3:
        {
            switch (indexPath.row) {
                    case 0:
                {
                    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
                    btn.frame = CGRectMake(100, 20, 100, 100);
                    btn.viewUI_rectCornerRadii = 20;
                    btn.backgroundColor = kRandomColor;
                    [cell.contentView addSubview:btn];
                    
                    //    NSMutableArray *_RectCornerArr = [NSMutableArray array];
                    //    [_RectCornerArr addObject:@(UIRectCornerAllCorners)];
                    
                    btn.viewUI_rectCorner = UIRectCornerBottomRight;

                }
                    break;
                    
                default:
                    break;
            }
        }
            break;
        case 4:
        {
            switch (indexPath.row) {
                    case 0:
                {
                    PLabel *aaaaaaaaaaaaaa = [PLabel new];
                    aaaaaaaaaaaaaa.backgroundColor = kRandomColor;
                    [aaaaaaaaaaaaaa setVerticalAlignment:VerticalAlignmentMiddle strikeThroughAlignment:StrikeThroughAlignmentMiddle setStrikeThroughEnabled:YES];
                    aaaaaaaaaaaaaa.text = @"111111111111111";
                    [cell.contentView addSubview:aaaaaaaaaaaaaa];
                    [aaaaaaaaaaaaaa mas_makeConstraints:^(MASConstraintMaker *make) {
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
            case 5:
        {
            switch (indexPath.row) {
                    case 0:
                {
                    UILabel *infoLabel = [UILabel new];
                    infoLabel.textColor = [UIColor blackColor];
                    infoLabel.textAlignment = NSTextAlignmentCenter;
                    infoLabel.numberOfLines = 0;
                    infoLabel.lineBreakMode = NSLineBreakByCharWrapping;
                    infoLabel.text = @"点我弹出ActionSheet";
                    [cell.contentView addSubview:infoLabel];
                    [infoLabel mas_makeConstraints:^(MASConstraintMaker *make) {
                        make.top.equalTo(functionName.mas_bottom);
                        make.left.right.bottom.equalTo(cell.contentView);
                    }];
                }
                    break;
                    case 1:
                {
                    UILabel *infoLabel = [UILabel new];
                    infoLabel.textColor = [UIColor blackColor];
                    infoLabel.textAlignment = NSTextAlignmentCenter;
                    infoLabel.numberOfLines = 0;
                    infoLabel.lineBreakMode = NSLineBreakByCharWrapping;
                    infoLabel.text = @"点我弹出CustomAlertView";
                    [cell.contentView addSubview:infoLabel];
                    [infoLabel mas_makeConstraints:^(MASConstraintMaker *make) {
                        make.top.equalTo(functionName.mas_bottom);
                        make.left.right.bottom.equalTo(cell.contentView);
                    }];
                }
                    break;
                    case 2:
                {
                    UILabel *infoLabel = [UILabel new];
                    infoLabel.textColor = [UIColor blackColor];
                    infoLabel.textAlignment = NSTextAlignmentCenter;
                    infoLabel.numberOfLines = 0;
                    infoLabel.lineBreakMode = NSLineBreakByCharWrapping;
                    infoLabel.text = @"点我弹出系统自带弹出框";
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
        default:
            break;
    }
    
    return cell;
}

#pragma mark ---------------> UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 120;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 50;
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
                    PooShowImageModel *imageModel = [[PooShowImageModel alloc] init];
                    imageModel.imageUrl = @"http://p3.music.126.net/VDn1p3j4g2z4p16Gux969w==/2544269907756816.jpg";
                    imageModel.imageShowType = PooShowImageModelTypeFullView;
                    imageModel.imageInfo = @"11111111241241241241928390128309128";
                    imageModel.imageTitle = @"22222212312312312312312312312";
                    
                    PooShowImageModel *imageModelV = [[PooShowImageModel alloc] init];
                    imageModelV.imageUrl = @"http://clips.vorwaerts-gmbh.de/big_buck_bunny.mp4";
                    imageModelV.imageShowType = PooShowImageModelTypeVideo;
                    imageModelV.imageInfo = @"11111111241241241241928390128309128";
                    imageModelV.imageTitle = @"22222212312312312312312312312";
                    
                    
                    //    PooShowImageModel *imageModel1 = [[PooShowImageModel alloc] init];
                    //    imageModel1.imageUrl = @"http://p3.music.126.net/VDn1p3j4g2z4p16Gux969w==/2544269907756816.jpg";
                    //    imageModel1.imageFullView = @"0";
                    //    imageModel1.imageInfo = @"444444";
                    //    imageModel1.imageTitle = @"333333";
                    
                    PooShowImageModel *imageModel2 = [[PooShowImageModel alloc] init];
                    imageModel2.imageUrl = @"http://ww4.sinaimg.cn/bmiddle/677febf5gw1erma1g5xd0j20k0esa7wj.jpg";
                    imageModelV.imageShowType = PooShowImageModelTypeNormal;
                    imageModel2.imageInfo = @"6666666";
                    imageModel2.imageTitle = @"5555555";
                    
                    PooShowImageModel *imageModel3 = [[PooShowImageModel alloc] init];
                    imageModel3.imageUrl = @"https://timgsa.baidu.com/timg?image&quality=80&size=b9999_10000&sec=1535114837724&di=c006441b6c288352e1fcdfc7b47db2b3&imgtype=0&src=http%3A%2F%2Fimg5.duitang.com%2Fuploads%2Fitem%2F201412%2F13%2F20141213142127_yXadz.thumb.700_0.gif";
                    imageModelV.imageShowType = PooShowImageModelTypeGIF;
                    imageModel3.imageInfo = @"444444";
                    imageModel3.imageTitle = @"333333";
                    
                    NSArray *arr = @[imageModel,imageModelV,imageModel2,imageModel3];
                    
                    YMShowImageView *ymImageV = [[YMShowImageView alloc] initWithByClick:YMShowImageViewClickTagAppend appendArray:arr titleColor:[UIColor whiteColor] fontName:FontName showImageBackgroundColor:[UIColor blackColor] showWindow:[PTAppDelegate appDelegate].window loadingImageName:@"DemoImage" deleteAble:YES saveAble:YES moreActionImageName:@"DemoImage"];
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
                    break;
            }
        }
            break;
        case 5:
        {
            switch (indexPath.row) {
                    case 0:
                {
                    ALActionSheetView *actionSheet = [[ALActionSheetView alloc] initWithTitle:@"11111" cancelButtonTitle:@"11111" destructiveButtonTitle:@"11111" otherButtonTitles:@[@"1231",@"1231",@"1231",@"1231"] buttonFontName:FontNameBold handler:^(ALActionSheetView *actionSheetView, NSInteger buttonIndex) {
                    }];
                    [actionSheet show];
                }
                    break;
                    case 1:
                {
                    YXCustomAlertView *alert = [[YXCustomAlertView alloc] initAlertViewWithSuperView:self.view alertTitle:@"111123123" withButtonAndTitleFont:[UIFont systemFontOfSize:20] titleColor:kRandomColor bottomButtonTitleColor:kRandomColor verLineColor:kRandomColor moreButtonTitleArray:@[@"111",@"222"] viewTag:1 setCustomView:^(YXCustomAlertView *alertView) {
                        
                        UILabel *aaa = [UILabel new];
                        aaa.backgroundColor = kRandomColor;
                        aaa.text = @"1123123123123";
                        [alertView.customView addSubview:aaa];
                        [aaa mas_makeConstraints:^(MASConstraintMaker *make) {
                            make.left.right.top.bottom.equalTo(alertView.customView);
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
                        make.width.height.offset(310);
                        make.centerX.centerY.equalTo(self.view);
                    }];

                }
                    break;
                    case 2:
                {
                    [Utils alertVCWithTitle:@"123123" message:@"2123" cancelTitle:@"2" okTitle:@"1" otherButtonArrow:nil shouIn:self alertStyle:UIAlertControllerStyleActionSheet
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
            break;
            
        default:
            break;
    }
}

@end
