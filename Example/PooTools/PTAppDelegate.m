//
//  PTAppDelegate.m
//  PooTools
//
//  Created by crazypoo on 05/01/2018.
//  Copyright (c) 2018 crazypoo. All rights reserved.
//

#import "PTAppDelegate.h"
#import "PLaunchAdMonitor.h"
#import "PTViewController.h"

#import "PMacros.h"

#define FontName @"HelveticaNeue-Light"
#define FontNameBold @"HelveticaNeue-Medium"

#define APPFONT(R) kDEFAULT_FONT(FontName,kAdaptedWidth(R))

@implementation PTAppDelegate

+ (PTAppDelegate *)appDelegate
{
    return (PTAppDelegate *)[[UIApplication sharedApplication] delegate];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

    PTViewController *view = [[PTViewController alloc] init];
    UINavigationController *mainNav = [[UINavigationController alloc] initWithRootViewController:view];
    self.window.rootViewController = mainNav;
    [self.window makeKeyAndVisible];
    
    [PLaunchAdMonitor showAdAtPath:@[@"http://p3.music.126.net/VDn1p3j4g2z4p16Gux969w==/2544269907756816.jpg"] onView:self.window.rootViewController.view timeInterval:3 detailParameters:@{} years:@"2000" skipButtonFont:APPFONT(16) comName:@"11111" comNameFont:APPFONT(12) callback:^{
    }];

    PNSLog(@">>>>>>%@>>>>>>%@>>>>%@>>>>%@>>>>%@>>>>%@",[Utils getTimeWithType:GetTimeTypeYMDHHS],[Utils getTimeWithType:GetTimeTypeYMD],[Utils getTimeWithType:GetTimeTypeMD],[Utils getTimeWithType:GetTimeTypeTimeStamp],[Utils getTimeWithType:GetTimeTypeHHS],[Utils getTimeWithType:GetTimeTypeHH]);
    
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
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
