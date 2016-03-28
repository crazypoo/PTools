//
//  PooSystemInfo.h
//  WNMPro
//
//  Created by crazypoo on 1/8/14.
//  Copyright (c) 2014 鄧傑豪. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <sys/socket.h>
#import <sys/types.h>
#import <sys/sysctl.h>
#import <ExternalAccessory/ExternalAccessory.h>
#import <AudioToolbox/AudioToolbox.h>
#import <mach/mach.h>
#import <mach/mach_host.h>


@interface PooSystemInfo : NSObject

//App
+ (NSString*)appName;
+ (NSString*)appVersion;

//Phone
+ (NSString*)getDeviceVersion;
+ (NSString *) platformString;
+ (BOOL)isRetinaDevice;
+ (NSString *)bootTime;
+ (NSString *)totalDiskSpace;
+ (NSString *)freeDiskSpace;
+ (NSString *)usedDiskSpace;
+ (CGFloat)totalDiskSpaceInBytes;
+ (CGFloat)freeDiskSpaceInBytes;
+ (CGFloat)usedDiskSpaceInBytes;

//Accessories
+ (BOOL)accessoriesPluggedIn;
+ (NSInteger)numberOfAccessoriesPluggedIn;
+ (BOOL)isHeadphonesAttached;

//JailBroken
+ (BOOL)isJailBroken;

//Localization
+ (NSString *)language;
+ (NSString *)timeZone;
+ (NSString *)currencySymbol;
+ (NSString *)currencyCode;
+ (NSString *)country;
+ (NSString *)measurementSystem;

//Memory
+ (NSInteger)totalMemory;
+ (CGFloat)freeMemory;
+ (CGFloat)usedMemory;
+ (CGFloat)activeMemory;
+ (CGFloat)wiredMemory;
+ (CGFloat)inactiveMemory;

//Processor
+ (NSInteger)processorsNumber;
+ (NSInteger)activeProcessorsNumber;
+ (CGFloat)cpuUsageForApp;
+ (NSArray *)activeProcesses;
+ (NSInteger)numberOfActiveProcesses;

@end
