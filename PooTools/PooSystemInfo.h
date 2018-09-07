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

#pragma mark ---------------> APP
/*! @brief App名字
 */
+ (NSString*)appName;
/*! @brief App版本
 */
+ (NSString*)appVersion;

#pragma mark ---------------> Phone
/*! @brief 设备版本 (硬件)
 */
+ (NSString*)getDeviceVersion;
/*! @brief 获取平台
 */
+ (NSString*)platformString;
/*! @brief 是否高清屏
 */
+ (BOOL)isRetinaDevice;
/*! @brief 启动时长
 */
+ (NSString *)bootTime;
/*! @brief 硬盘空间
 */
+ (NSString *)totalDiskSpace;
/*! @brief 硬盘可用空间
 */
+ (NSString *)freeDiskSpace;
/*! @brief 硬盘已用空间
 */
+ (NSString *)usedDiskSpace;
/*! @brief 硬盘空间 (Bytes)
 */
+ (CGFloat)totalDiskSpaceInBytes;
/*! @brief 硬盘可用空间 (Bytes)
 */
+ (CGFloat)freeDiskSpaceInBytes;
/*! @brief 硬盘已用空间 (Bytes)
 */
+ (CGFloat)usedDiskSpaceInBytes;

#pragma mark ---------------> Accessories
/*! @brief 是否插入配件
 */
+ (BOOL)accessoriesPluggedIn;
/*! @brief 配件数量
 */
+ (NSInteger)numberOfAccessoriesPluggedIn;
/*! @brief 是否插入耳机
 */
+ (BOOL)isHeadphonesAttached;

#pragma mark ---------------> JailBroken
/*! @brief 是否越狱
 */
+ (BOOL)isJailBroken;

#pragma mark ---------------> Localization
/*! @brief 当前语言
 */
+ (NSString *)language;
/*! @brief 当前时区
 */
+ (NSString *)timeZone;
/*! @brief 当前地区货币
 */
+ (NSString *)currencySymbol;
/*! @brief 当前时区代号
 */
+ (NSString *)currencyCode;
/*! @brief 当前国家
 */
+ (NSString *)country;
/*! @brief 当前测量系统
 */
+ (NSString *)measurementSystem;

#pragma mark ---------------> Memory
/*! @brief 内存重量
 */
+ (NSInteger)totalMemory;
/*! @brief 空间内存
 */
+ (CGFloat)freeMemory;
/*! @brief 已用内存
 */
+ (CGFloat)usedMemory;
/*! @brief 活动中内存
 */
+ (CGFloat)activeMemory;
/*! @brief 活跃内存
 */
+ (CGFloat)wiredMemory;
/*! @brief 不活跃内存
 */
+ (CGFloat)inactiveMemory;

#pragma mark ---------------> Processor
/*! @brief 处理器数量
 */
+ (NSInteger)processorsNumber;
/*! @brief 活动中的处理器数量
 */
+ (NSInteger)activeProcessorsNumber;
/*! @brief 在App中cpu使用量
 */
+ (CGFloat)cpuUsageForApp;
/*! @brief 活动中的处理器数组
 */
+ (NSArray *)activeProcesses;
/*! @brief 有多少个活动中的处理器
 */
+ (NSInteger)numberOfActiveProcesses;

@end
