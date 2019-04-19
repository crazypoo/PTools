//
//  PooSystemInfo.m
//  WNMPro
//
//  Created by crazypoo on 1/8/14.
//  Copyright (c) 2014 鄧傑豪. All rights reserved.
//

#import "PooSystemInfo.h"

@implementation PooSystemInfo

#pragma mark -- App
+ (NSString*)appName
{
    return [[[NSBundle mainBundle] infoDictionary] objectForKey:
            @"CFBundleDisplayName"];
}

+ (NSString*)appVersion
{
    return [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
}

#pragma mark -- 硬件
+ (NSString*)getDeviceVersion{
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char *machine = (char*)malloc(size);
    sysctlbyname("hw.machine", machine, &size, NULL, 0);
    NSString *platform = [NSString stringWithCString:machine encoding:NSUTF8StringEncoding];
    free(machine);
    return platform;
}

+ (NSString *) platformString{
    NSString *platform = [PooSystemInfo getDeviceVersion];;
    // iPhone
    if ([platform isEqualToString:@"iPhone11,8"])   return @"iPhone XR";
    if ([platform isEqualToString:@"iPhone11,6"])   return @"iPhone XS Max";
    if ([platform isEqualToString:@"iPhone11,4"])   return @"iPhone XS Max";
    if ([platform isEqualToString:@"iPhone11,2"])   return @"iPhone XS";
    if ([platform isEqualToString:@"iPhone10,6"])   return @"iPhone X";         // GSM
    if ([platform isEqualToString:@"iPhone10,5"])   return @"iPhone 8 Plus";    // GSM
    if ([platform isEqualToString:@"iPhone10,4"])   return @"iPhone 8";         // GSM
    if ([platform isEqualToString:@"iPhone10,3"])   return @"iPhone X";         // Global
    if ([platform isEqualToString:@"iPhone10,2"])   return @"iPhone 8 Plus";    // Global
    if ([platform isEqualToString:@"iPhone10,1"])   return @"iPhone 8";         // Global
    if ([platform isEqualToString:@"iPhone9,4"])    return @"iPhone 7 Plus";    // GSM
    if ([platform isEqualToString:@"iPhone9,3"])    return @"iPhone 7";         // GSM
    if ([platform isEqualToString:@"iPhone9,2"])    return @"iPhone 7 Plus";    // Global
    if ([platform isEqualToString:@"iPhone9,1"])    return @"iPhone 7";         // Global
    if ([platform isEqualToString:@"iPhone8,4"])    return @"iPhone SE";
    if ([platform isEqualToString:@"iPhone8,2"])    return @"iPhone 6s Plus";
    if ([platform isEqualToString:@"iPhone8,1"])    return @"iPhone 6s";
    if ([platform isEqualToString:@"iPhone7,2"])    return @"iPhone 6";
    if ([platform isEqualToString:@"iPhone7,1"])    return @"iPhone 6 Plus";
    if ([platform isEqualToString:@"iPhone6,2"])    return @"iPhone 5s";
    if ([platform isEqualToString:@"iPhone6,1"])    return @"iPhone 5s";
    if ([platform isEqualToString:@"iPhone5,4"])    return @"iPhone 5c";
    if ([platform isEqualToString:@"iPhone5,3"])    return @"iPhone 5c";
    if ([platform isEqualToString:@"iPhone5,2"])    return @"iPhone 5 (CDMA)";
    if ([platform isEqualToString:@"iPhone5,1"])    return @"iPhone 5 (GSM)";
    if ([platform isEqualToString:@"iPhone4,1"])    return @"iPhone 4S";
    if ([platform isEqualToString:@"iPhone3,3"])    return @"iPhone 4 (CDMA)";
    if ([platform isEqualToString:@"iPhone3,2"])    return @"iPhone 4 (GSM Rev A)";
    if ([platform isEqualToString:@"iPhone3,1"])    return @"iPhone 4 (GSM)";
    if ([platform isEqualToString:@"iPhone2,1"])    return @"iPhone 3GS";
    if ([platform isEqualToString:@"iPhone1,2"])    return @"iPhone 3G";
    if ([platform isEqualToString:@"iPhone1,1"])    return @"iPhone 1G";
    
    // iPod touch
    if ([platform isEqualToString:@"iPod7,1"])      return @"iPod touch 6G";
    if ([platform isEqualToString:@"iPod5,1"])      return @"iPod touch 5G";
    if ([platform isEqualToString:@"iPod4,1"])      return @"iPod touch 4G";
    if ([platform isEqualToString:@"iPod3,1"])      return @"iPod touch 3G";
    if ([platform isEqualToString:@"iPod2,1"])      return @"iPod touch 2G";
    if ([platform isEqualToString:@"iPod1,1"])      return @"iPod touch 1G";
    
    // iPad
    if ([platform isEqualToString:@"iPad7,6"])      return @"iPad 6 (Cellular)";
    if ([platform isEqualToString:@"iPad7,5"])      return @"iPad 6 (WiFi)";
    if ([platform isEqualToString:@"iPad7,4"])      return @"iPad Pro 10.5-inch (Cellular)";
    if ([platform isEqualToString:@"iPad7,3"])      return @"iPad Pro 10.5-inch (WiFi)";
    if ([platform isEqualToString:@"iPad7,2"])      return @"iPad Pro 12.9-inch 2nd-gen (Cellular)";
    if ([platform isEqualToString:@"iPad7,1"])      return @"iPad Pro 12.9-inch 2nd-gen (WiFi)";
    if ([platform isEqualToString:@"iPad6,12"])     return @"iPad 5 (Cellular)";
    if ([platform isEqualToString:@"iPad6,11"])     return @"iPad 5 (WiFi)";
    if ([platform isEqualToString:@"iPad6,8"])      return @"iPad Pro 12.9-inch (Cellular)";
    if ([platform isEqualToString:@"iPad6,7"])      return @"iPad Pro 12.9-inch (WiFi)";
    if ([platform isEqualToString:@"iPad6,4"])      return @"iPad Pro 9.7-inch (Cellular)";
    if ([platform isEqualToString:@"iPad6,3"])      return @"iPad Pro 9.7-inch (WiFi)";
    if ([platform isEqualToString:@"iPad5,4"])      return @"iPad Air 2 (Cellular)";
    if ([platform isEqualToString:@"iPad5,3"])      return @"iPad Air 2 (WiFi)";
    if ([platform isEqualToString:@"iPad5,2"])      return @"iPad Mini 4 (Cellular)";
    if ([platform isEqualToString:@"iPad5,1"])      return @"iPad Mini 4 (WiFi)";
    if ([platform isEqualToString:@"iPad4,9"])      return @"iPad Mini 3 (Cellular)";
    if ([platform isEqualToString:@"iPad4,8"])      return @"iPad Mini 3 (Cellular)";
    if ([platform isEqualToString:@"iPad4,7"])      return @"iPad Mini 3 (WiFi)";
    if ([platform isEqualToString:@"iPad4,6"])      return @"iPad Mini Retina (China)";
    if ([platform isEqualToString:@"iPad4,5"])      return @"iPad Mini Retina (Cellular)";
    if ([platform isEqualToString:@"iPad4,4"])      return @"iPad Mini Retina (WiFi)";
    if ([platform isEqualToString:@"iPad4,3"])      return @"iPad Air (CDMA)";
    if ([platform isEqualToString:@"iPad4,2"])      return @"iPad Air (GSM)";
    if ([platform isEqualToString:@"iPad4,1"])      return @"iPad Air (WiFi)";
    if ([platform isEqualToString:@"iPad3,6"])      return @"iPad 4 (CDMA)";
    if ([platform isEqualToString:@"iPad3,5"])      return @"iPad 4 (GSM)";
    if ([platform isEqualToString:@"iPad3,4"])      return @"iPad 4 (WiFi)";
    if ([platform isEqualToString:@"iPad3,3"])      return @"iPad 3 (GSM)";
    if ([platform isEqualToString:@"iPad3,2"])      return @"iPad 3 (CDMA)";
    if ([platform isEqualToString:@"iPad3,1"])      return @"iPad 3 (WiFi)";
    if ([platform isEqualToString:@"iPad2,7"])      return @"iPad Mini (CDMA)";
    if ([platform isEqualToString:@"iPad2,6"])      return @"iPad Mini (GSM)";
    if ([platform isEqualToString:@"iPad2,5"])      return @"iPad Mini (WiFi)";
    if ([platform isEqualToString:@"iPad2,4"])      return @"iPad 2 (WiFi)";
    if ([platform isEqualToString:@"iPad2,3"])      return @"iPad 2 (CDMA)";
    if ([platform isEqualToString:@"iPad2,2"])      return @"iPad 2 (GSM)";
    if ([platform isEqualToString:@"iPad2,1"])      return @"iPad 2 (WiFi)";
    if ([platform isEqualToString:@"iPad1,1"])      return @"iPad";
    
    // Simulator
    if ([platform isEqualToString:@"i386"])         return [NSString stringWithFormat:@"%@ Simulator", [UIDevice currentDevice].model];
    if ([platform isEqualToString:@"x86_64"])       return [NSString stringWithFormat:@"%@ Simulator", [UIDevice currentDevice].model];
    return platform;
}

+(BOOL)isRetinaDevice{
    BOOL isRetina=YES;
    NSString *platform = [PooSystemInfo getDeviceVersion];
    if ([platform isEqualToString:@"iPhone1,1"])    isRetina=NO;
    if ([platform isEqualToString:@"iPhone1,2"])    isRetina=NO;
    if ([platform isEqualToString:@"iPhone2,1"])    isRetina=NO;
    if ([platform isEqualToString:@"iPhone3,1"])    isRetina=NO;
    if ([platform isEqualToString:@"iPhone3,3"])    isRetina=NO;
    if ([platform isEqualToString:@"iPhone4,1"])    isRetina=YES;
    if ([platform isEqualToString:@"iPhone5,3"]   ||
        [platform isEqualToString:@"iPhone5,4"])    isRetina=YES;
    if ([platform isEqualToString:@"iPhone6,1"]   ||
        [platform isEqualToString:@"iPhone6,2"])    isRetina=YES;
    if ([platform isEqualToString:@"iPhone7,2"])    isRetina=YES;
    if ([platform isEqualToString:@"iPhone7,1"])    isRetina=YES;
    if ([platform isEqualToString:@"iPod1,1"])      isRetina=NO;
    if ([platform isEqualToString:@"iPod2,1"])      isRetina=NO;
    if ([platform isEqualToString:@"iPod3,1"])      isRetina=NO;
    if ([platform isEqualToString:@"iPod4,1"])      isRetina=YES;
    if ([platform isEqualToString:@"iPad1,1"])      isRetina=NO;
    if ([platform isEqualToString:@"iPad2,1"])      isRetina=NO;
    if ([platform isEqualToString:@"iPad2,2"])      isRetina=NO;
    if ([platform isEqualToString:@"iPad2,3"])      isRetina=NO;
    if ([platform isEqualToString:@"iPad3,1"])      isRetina=YES;
    if ([platform isEqualToString:@"iPad3,2"])      isRetina=YES;
    if ([platform isEqualToString:@"iPad3,3"])      isRetina=YES;
    if ([platform isEqualToString:@"i386"])         isRetina=NO;
    if ([platform isEqualToString:@"x86_64"])       isRetina=NO;
    return isRetina;
}

+ (NSString *)bootTime {
    NSInteger ti = (NSInteger)[[NSProcessInfo processInfo] systemUptime];
    NSInteger seconds = ti % 60;
    NSInteger minutes = (ti / 60) % 60;
    NSInteger hours = (ti / 3600);
    return [NSString stringWithFormat:@"%02li:%02li:%02li", (long)hours, (long)minutes, (long)seconds];
}

#define MB (1024*1024)
#define GB (MB*1024)

+ (NSString *)memoryFormatter:(long long)diskSpace {
    NSString *formatted;
    double bytes = 1.0 * diskSpace;
    double megabytes = bytes / MB;
    double gigabytes = bytes / GB;
    if (gigabytes >= 1.0)
        formatted = [NSString stringWithFormat:@"%.2f GB", gigabytes];
    else if (megabytes >= 1.0)
        formatted = [NSString stringWithFormat:@"%.2f MB", megabytes];
    else
        formatted = [NSString stringWithFormat:@"%.2f bytes", bytes];
    
    return formatted;
}

+ (NSString *)totalDiskSpace {
    long long space = [[[[NSFileManager defaultManager] attributesOfFileSystemForPath:NSHomeDirectory() error:nil] objectForKey:NSFileSystemSize] longLongValue];
    return [self memoryFormatter:space];
}

+ (NSString *)freeDiskSpace {
    long long freeSpace = [[[[NSFileManager defaultManager] attributesOfFileSystemForPath:NSHomeDirectory() error:nil] objectForKey:NSFileSystemFreeSize] longLongValue];
    return [self memoryFormatter:freeSpace];
}

+ (NSString *)usedDiskSpace {
    return [self memoryFormatter:[self usedDiskSpaceInBytes]];
}

+ (CGFloat)totalDiskSpaceInBytes {
    long long space = [[[[NSFileManager defaultManager] attributesOfFileSystemForPath:NSHomeDirectory() error:nil] objectForKey:NSFileSystemSize] longLongValue];
    return space;
}

+ (CGFloat)freeDiskSpaceInBytes {
    long long freeSpace = [[[[NSFileManager defaultManager] attributesOfFileSystemForPath:NSHomeDirectory() error:nil] objectForKey:NSFileSystemFreeSize] longLongValue];
    return freeSpace;
}

+ (CGFloat)usedDiskSpaceInBytes {
    long long usedSpace = [self totalDiskSpaceInBytes] - [self freeDiskSpaceInBytes];
    return usedSpace;
}

+ (CGFloat)numberOfNodes {
    long long numberOfNodes = [[[[NSFileManager defaultManager] attributesOfFileSystemForPath:NSHomeDirectory() error:nil] objectForKey:NSFileSystemNodes] longLongValue];
    return numberOfNodes;
}


#pragma mark -- 附件
+ (BOOL)accessoriesPluggedIn {
    int accessoryCount = (int)[[[EAAccessoryManager sharedAccessoryManager] connectedAccessories] count];
    if (accessoryCount > 0)
        return YES;
    else
        return NO;
}

+ (NSInteger)numberOfAccessoriesPluggedIn {
    return [[[EAAccessoryManager sharedAccessoryManager] connectedAccessories] count];
}

+ (BOOL)isHeadphonesAttached {
    return NO;
}

#pragma mark -- 越狱检测
static const char* jailbreak_apps[] =
{
    "/Applications/Cydia.app",
    "/Applications/limera1n.app",
    "/Applications/greenpois0n.app",
    "/Applications/blackra1n.app",
    "/Applications/blacksn0w.app",
    "/Applications/redsn0w.app",
    NULL,
};

+(BOOL)isJailBroken
{
    for (int i = 0; jailbreak_apps[i] != NULL; ++i)
    {
        if ([[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithUTF8String:jailbreak_apps[i]]])
        {
            return YES;
        }
    }
    return NO;
}

#pragma mark -- Localization

+ (NSString *)language {
    return [[NSLocale preferredLanguages] objectAtIndex:0];
}

+ (NSString *)timeZone {
    return [[NSTimeZone systemTimeZone] name];
}

+ (NSString *)currencySymbol {
    return [[NSLocale currentLocale] objectForKey:NSLocaleCurrencySymbol];
}

+ (NSString *)currencyCode {
    return [[NSLocale currentLocale] objectForKey:NSLocaleCurrencyCode];
}

+ (NSString *)country {
    return [[NSLocale currentLocale] localeIdentifier];
}

+ (NSString *)measurementSystem {
    return [[NSLocale currentLocale] objectForKey:NSLocaleMeasurementSystem];
}

#pragma mark -- 内存信息

+ (NSInteger)totalMemory {
    int nearest = 256;
    int totalMemory = (int)[[NSProcessInfo processInfo] physicalMemory] / 1024 / 1024;
    int rem = (int)totalMemory % nearest;
    int tot = 0;
    if (rem >= nearest/2) {
        tot = ((int)totalMemory - rem)+256;
    } else {
        tot = ((int)totalMemory - rem);
    }
    
    return tot;
}

+ (CGFloat)freeMemory {
    double totalMemory = 0.00;
    vm_statistics_data_t vmStats;
    mach_msg_type_number_t infoCount = HOST_VM_INFO_COUNT;
    kern_return_t kernReturn = host_statistics(mach_host_self(), HOST_VM_INFO, (host_info_t)&vmStats, &infoCount);
    if(kernReturn != KERN_SUCCESS) {
        return -1;
    }
    totalMemory = ((vm_page_size * vmStats.free_count) / 1024) / 1024;
    
    return totalMemory;
}

+ (CGFloat)usedMemory {
    double usedMemory = 0.00;
    vm_statistics_data_t vmStats;
    mach_msg_type_number_t infoCount = HOST_VM_INFO_COUNT;
    kern_return_t kernReturn = host_statistics(mach_host_self(), HOST_VM_INFO, (host_info_t)&vmStats, &infoCount);
    if(kernReturn != KERN_SUCCESS) {
        return -1;
    }
    usedMemory = ((vm_page_size * (vmStats.active_count + vmStats.inactive_count + vmStats.wire_count)) / 1024) / 1024;
    
    return usedMemory;
}

+ (CGFloat)activeMemory {
    double activeMemory = 0.00;
    vm_statistics_data_t vmStats;
    mach_msg_type_number_t infoCount = HOST_VM_INFO_COUNT;
    kern_return_t kernReturn = host_statistics(mach_host_self(), HOST_VM_INFO, (host_info_t)&vmStats, &infoCount);
    if(kernReturn != KERN_SUCCESS) {
        return -1;
    }
    activeMemory = ((vm_page_size * vmStats.active_count) / 1024) / 1024;
    
    return activeMemory;
}

+ (CGFloat)wiredMemory {
    double wiredMemory = 0.00;
    vm_statistics_data_t vmStats;
    mach_msg_type_number_t infoCount = HOST_VM_INFO_COUNT;
    kern_return_t kernReturn = host_statistics(mach_host_self(), HOST_VM_INFO, (host_info_t)&vmStats, &infoCount);
    if(kernReturn != KERN_SUCCESS) {
        return -1;
    }
    wiredMemory = ((vm_page_size * vmStats.wire_count) / 1024) / 1024;
    
    return wiredMemory;
}

+ (CGFloat)inactiveMemory {
    double inactiveMemory = 0.00;
    vm_statistics_data_t vmStats;
    mach_msg_type_number_t infoCount = HOST_VM_INFO_COUNT;
    kern_return_t kernReturn = host_statistics(mach_host_self(), HOST_VM_INFO, (host_info_t)&vmStats, &infoCount);
    if(kernReturn != KERN_SUCCESS) {
        return -1;
    }
    inactiveMemory = ((vm_page_size * vmStats.inactive_count) / 1024) / 1024;
    
    return inactiveMemory;
}

#pragma mark --处理器
+ (NSInteger)processorsNumber {
    return [[NSProcessInfo processInfo] processorCount];
}

+ (NSInteger)activeProcessorsNumber {
    return [[NSProcessInfo processInfo] activeProcessorCount];
}

+ (CGFloat)cpuUsageForApp {
    kern_return_t kr;
    task_info_data_t tinfo;
    mach_msg_type_number_t task_info_count;
    
    task_info_count = TASK_INFO_MAX;
    kr = task_info(mach_task_self(), TASK_BASIC_INFO, (task_info_t)tinfo, &task_info_count);
    if (kr != KERN_SUCCESS)
        return -1;
    
    task_basic_info_t      basic_info;
    thread_array_t         thread_list;
    mach_msg_type_number_t thread_count;
    thread_info_data_t     thinfo;
    mach_msg_type_number_t thread_info_count;
    thread_basic_info_t basic_info_th;
    uint32_t stat_thread = 0;
    
    basic_info = (task_basic_info_t)tinfo;
    
    kr = task_threads(mach_task_self(), &thread_list, &thread_count);
    if (kr != KERN_SUCCESS)
        return -1;
    if (thread_count > 0)
        stat_thread += thread_count;
    
    long tot_sec = 0;
    long tot_usec = 0;
    float tot_cpu = 0;
    int j;
    
    for (j = 0; j < thread_count; j++) {
        thread_info_count = THREAD_INFO_MAX;
        kr = thread_info(thread_list[j], THREAD_BASIC_INFO,
                         (thread_info_t)thinfo, &thread_info_count);
        if (kr != KERN_SUCCESS)
            return -1;
        
        basic_info_th = (thread_basic_info_t)thinfo;
        if (!(basic_info_th->flags & TH_FLAGS_IDLE)) {
            tot_sec = tot_sec + basic_info_th->user_time.seconds + basic_info_th->system_time.seconds;
            tot_usec = tot_usec + basic_info_th->system_time.microseconds + basic_info_th->system_time.microseconds;
            tot_cpu = tot_cpu + basic_info_th->cpu_usage / (float)TH_USAGE_SCALE;
        }
        
    }
    
    return tot_cpu;
}

+ (NSArray *)activeProcesses {
    int mib[4] = {CTL_KERN, KERN_PROC, KERN_PROC_ALL, 0};
    size_t miblen = 4;
    size_t size;
    int st = sysctl(mib, (int)miblen, NULL, &size, NULL, 0);
    struct kinfo_proc * process = NULL;
    struct kinfo_proc * newprocess = NULL;
    do {
        
        size += size / 10;
        newprocess = realloc(process, size);
        if (!newprocess) {
            if (process) {
                free(process);
            }
            return nil;
        }
        process = newprocess;
        st = sysctl(mib, (int)miblen, process, &size, NULL, 0);
        
    } while (st == -1 && errno == ENOMEM);
    
    if (st == 0) {
        if (size % sizeof(struct kinfo_proc) == 0){
            int nprocess = (int)size / sizeof(struct kinfo_proc);
            if (nprocess) {
                NSMutableArray * array = [[NSMutableArray alloc] init];
                for (int i = nprocess - 1; i >= 0; i--) {
                    NSString * processID = [[NSString alloc] initWithFormat:@"%d", process[i].kp_proc.p_pid];
                    NSString * processName = [[NSString alloc] initWithFormat:@"%s", process[i].kp_proc.p_comm];
                    NSDictionary * dict = [[NSDictionary alloc] initWithObjects:[NSArray arrayWithObjects:processID, processName, nil] forKeys:[NSArray arrayWithObjects:@"ProcessID", @"ProcessName", nil]];
                    [array addObject:dict];
                }
                free(process);
                return array;
            }
        }
    }
    
    return nil;
}

+ (NSInteger)numberOfActiveProcesses {
    return [[self activeProcesses] count];
}

@end
