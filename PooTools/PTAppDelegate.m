//
//  PTAppDelegate.m
//  PooTools
//
//  Created by crazypoo on 05/01/2018.
//  Copyright (c) 2018 crazypoo. All rights reserved.
//

#import "PTAppDelegate.h"
#import "PTViewController.h"

#import "PMacros.h"

#import <IQKeyboardManager/IQKeyboardManager.h>

#define FontName @"HelveticaNeue-Light"
#define FontNameBold @"HelveticaNeue-Medium"

/*
 pod trunk register 273277355@qq.com 'HelloKitty' --description='Mac mini'
 //重装后先登录
 git tag 1.11.23//版本设置
 git push --tags//版本推送
 pod spec lint PooTools.podspec --allow-warnings --verbose //第一次验证
 pod trunk push /Users/crazypoo/ST/PTools/PooTools.podspec --verbose --allow-warnings//通过第一次验证后提交
 */

@implementation PTAppDelegate

- (UIInterfaceOrientationMask)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window {
    return  [PTRotationManager share].interfaceOrientationMask;
}

+ (PTAppDelegate *)appDelegate
{
    return (PTAppDelegate *)[[UIApplication sharedApplication] delegate];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
//    [PTSensitiveWordTools shared];
//    NSString *string = [NSString stringWithFormat:@"含有敏感词汇：%@",[[PTSensitiveWordTools shared]filter:@"裸体123123123裸体133333333"]];
//    PNSLog(@"%@",string);
    
//    PNSLog(@">>>>>>>>>>>>>>>>>%@",[PTUtils jsonStringToArrayWithJsonStr:@"{\"json\":11111,\"b\"123344}"]);

    PNSLog(@"有没有敏感词%d",[[PTCheckFWords share] haveFWordWithStr:@"公安局"]);    
    PNSLog(@">>>>>>>>>>>>%@",[[UIColor.redColor createImageWithColor] transformImageWithSize:CGSizeMake(100, 100)]);
    [IQKeyboardManager sharedManager].enable = YES;
    [IQKeyboardManager sharedManager].keyboardDistanceFromTextField = 50;
    
    // Override point for customization after application launch.
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    PTViewController *view = [[PTViewController alloc] init];
    UINavigationController *mainNav = [[UINavigationController alloc] initWithRootViewController:view];
    self.window.rootViewController = mainNav;
    [self.window makeKeyAndVisible];
        
//    http://clips.vorwaerts-gmbh.de/big_buck_bunny.mp4
//    http://p3.music.126.net/VDn1p3j4g2z4p16Gux969w==/2544269907756816.jpg
    [PTLaunchAdMonitor showAtPath:@[@"http://p3.music.126.net/VDn1p3j4g2z4p16Gux969w==/2544269907756816.jpg"] onView:kAppDelegateWindow timeInterval:10 param:@{@"123":@"https://www.qq.com"} year:@"2000" skipFont:[UIFont appCustomFontWithSize:10 customFont:FontName scale:NO] comName:@"11111" comNameFont:[UIFont appCustomFontWithSize:10 customFont:FontName scale:NO] callBack:^{
        PNSLog(@"1231231231231231231231");
    }];
                    
    [[PCheckAppStatus shared] open];
        
    PTImaginaryLineView *imageLine = [[PTImaginaryLineView alloc] init];
    [self.window addSubview:imageLine];
    [imageLine mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.window);
        make.height.equalTo(@3);
        make.top.equalTo(self.window).offset(100);
    }];
    
    PTDevFunction *devFunction = [PTDevFunction share];
    [devFunction createLabBtn];
    devFunction.goToAppDevVC = ^{
        PTDebugViewController *vc = [[PTDebugViewController alloc] init];
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
        [[PTUtils getCurrentVCWithAnyClass:[UIViewController new]] presentViewController:nav animated:YES completion:^{
        }];
    };
    
//    [PTAppDelegate.appDelegate.localConsoles print:[NSString stringWithFormat:@">>>>>>>>>>>>>>>>>>>>>>>>>>>>>%@>>>>>>>>>>>%lu",[Utils fewMonthLater:3 fromNow:[NSDate date] timeType:FewMonthLaterTypeContract],(unsigned long)[@"520dengjieHAO" passwordLevel]]];
    
    
    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
    [dic setObject:@"true" forKey:@"isLogin"];
    [dic setObject:@"1" forKey:@"phoneType"];//手机型号
    [dic setObject:@"2" forKey:@"phoneSystem"];//手机系统版本
    [dic setObject:@"" forKey:@"tokenID"];//tokenid
    [dic setObject:@"1" forKey:@"appVersion"];//app版本
    [dic setObject:@"1" forKey:@"systemType"];//手机系统
    [dic setObject:@"" forKey:@"landingPhone"];
    [dic setObject:@"" forKey:@"phone"];
    [dic setObject:@"2" forKey:@"appName"];//app代号 0:工人,1房东,2房客
    [dic setObject:@"0.00" forKey:@"userLat"];//经度
    [dic setObject:@"0.00" forKey:@"userLon"];//纬度
    
//    [CGBaseGobalTools apiServerAddress:@"www.cloudgategz.com" apiURL:@"/chl/enteringAdver/findFirstPic" withParmars:dic hideHub:YES hubColor:kRandomColor handle:^(BOOL success, NSMutableDictionary *infoDict) {
//
//    }];
//    RespDictionaryBlock dBlock = ^(NSMutableDictionary *infoDict, NSError *error) {
//        kHideNetworkActivityIndicator();
//        if (!error)
//        {
//            if (infoDict && [infoDict isKindOfClass:[NSMutableDictionary class]])
//            {
////                block(YES,infoDict);
//            }
//        }
//        else
//        {
////            block(NO,nil);
//        }
//    };
//
//    [HTTPClient(@"www.cloudgategz.com",YES) POSTApi:@"/chl/enteringAdver/findFirstPic"
//                                parameters:dic
//                                 parserKey:pkIGTestParserApp
//                                   success:[IGRespBlockGenerator taskSuccessBlockWithDictionaryBlock:dBlock]
//                                   failure:[IGRespBlockGenerator taskFailureBlockWithDictionaryBlock:dBlock]];
//
    
//    CheckNowTimeAndPastTimeRelationshipsExpire = 0,
//       CheckNowTimeAndPastTimeRelationshipsReadyExpire,
//       CheckNowTimeAndPastTimeRelationshipsNormal,
//       CheckNowTimeAndPastTimeRelationshipsError
    
//    NSMutableDictionary *dicaaaaaa = [NSMutableDictionary dictionaryWithDictionary:@{
//        @"clientStatus":@0,
//    }];
//
//    NSMutableDictionary * aaaaa = [NSMutableDictionary dictionaryWithDictionary:@{
//        @"userKey":@"3QzN2kjM4YTO2gjNx0SOhZmNhVWM1AzYyYTZjRDZ1cDMhVWY0YGZhNjMmBTZwojclNXdtEWO4MWN0UzY1ETZiBTYxIGNkFGNzkjZ3kTNkFTM5UGNtMkMENjRxMTN3MjN0UzQxIUNBhjR0IzQwYDMxQDRzkjM",
//        @"debug":@""
//    }];
    
//    [HTTPClient(@"https://diou.user.gdupb.com", YES) POST:@"https://diou.user.gdupb.com/banner/showBannerButtons" parameters:dicaaaaaa headers:aaaaa progress:^(NSProgress * _Nonnull uploadProgress) {
//
//    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
//        [PTAppDelegate.appDelegate.localConsoles print:[NSString stringWithFormat:@">>>%@",responseObject]];
//    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
//
//    }];
    
    PTGuidePageModel *model = [PTGuidePageModel new];
    model.mainView = self.window;
    model.imageArrays = @[@"DemoImage.png",@"image_aircondition_gray.png",@"DemoImage.png",@"DemoImage.png",@"DemoImage.png"];
    model.tapHidden = YES;
    model.forwardImage = @"image_aircondition_gray.png";
    model.backImage = @"DemoImage.png";
    model.pageControl = false;
    model.skipShow = false;

    PTGuidePageHUD *aasdasd = [[PTGuidePageHUD alloc] initWithViewModel:model];
    aasdasd.animationTime = 1.5;
    aasdasd.adHadRemove = ^{
        
    };
    [self.window addSubview:aasdasd];

    if (self.maskView == nil) {
        PTDevMaskConfig * config = [PTDevMaskConfig new];
        self.maskView = [[PTDevMaskView alloc] initWithConfig:config];
        self.maskView.frame = CGRectMake(0, 0, kSCREEN_WIDTH, kSCREEN_HEIGHT);
        [self.window addSubview:self.maskView];
    }
    
//    [PTUtils timeRunWithTime_baseWithCustomQueName:@"11111" timeInterval:10 finishBlock:^(BOOL finish, NSInteger time) {
//        PNSLog(@"111111%d>>>>>>%ld",finish,(long)time);
//    }];
//
//    [PTUtils timeRunWithTime_baseWithCustomQueName:@"222222" timeInterval:10 finishBlock:^(BOOL finish, NSInteger time) {
//        PNSLog(@"2222222%d>>>>>>%ld",finish,(long)time);
//    }];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    [PSecurityStrategy addBlurEffect];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    [PSecurityStrategy removeBlurEffect];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
