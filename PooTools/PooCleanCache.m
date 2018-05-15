//
//  PooCleanCache.m
//  CloudGateCustom
//
//  Created by mouth on 2018/5/16.
//  Copyright © 2018年 邓杰豪. All rights reserved.
//

#define fileManager [NSFileManager defaultManager]
#define cachePath [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject]

#import "PooCleanCache.h"
#import "PMacros.h"

@implementation PooCleanCache
// 获取cachePath路径下文件夹大小

+ (NSString *)getCacheSize
{
    // 调试
#ifdef DEBUG
    // 如果文件夹不存在或者不是一个文件夹那么就抛出一个异常
    // 抛出异常会导致程序闪退,所以只在调试阶段抛出，发布阶段不要再抛了,不然极度影响用户体验
    BOOL isDirectory = NO;
    BOOL isExist = [fileManager fileExistsAtPath:cachePath isDirectory:&isDirectory];
    
    if (!isExist || !isDirectory)
    {
        NSException *exception = [NSException exceptionWithName:@"文件错误" reason:@"请检查你的文件路径!" userInfo:nil];
        [exception raise];
    }
    
    //发布
#else
#endif
    //获取“cachePath”文件夹下面的所有文件
    NSArray *subpathArray= [fileManager subpathsAtPath:cachePath];
    NSString *filePath = nil;
    long long totalSize = 0;
    
    for (NSString *subpath in subpathArray)
    {
        // 拼接每一个文件的全路径
        filePath =[cachePath stringByAppendingPathComponent:subpath];
        // isDirectory，是否是文件夹，默认不是
        BOOL isDirectory = NO;
        // isExist，判断文件是否存在
        BOOL isExist = [fileManager fileExistsAtPath:filePath isDirectory:&isDirectory];
        // 文件不存在,是文件夹,是隐藏文件都过滤
        if (!isExist || isDirectory || [filePath containsString:@".DS"]) continue;
        // attributesOfItemAtPath 只可以获得文件属性，不可以获得文件夹属性，这个也就是需要遍历文件夹里面每一个文件的原因
        long long fileSize = [[fileManager attributesOfItemAtPath:filePath error:nil] fileSize];
        totalSize += fileSize;
    }
    
    // 将文件夹大小转换为 M/KB/B
    NSString *totalSizeString = nil;

    if (totalSize > 1000 * 1000)
    {
        totalSizeString = [NSString stringWithFormat:@"%.1fM",totalSize / 1000.0f /1000.0f];
    }
    else if (totalSize > 1000)
    {
        totalSizeString = [NSString stringWithFormat:@"%.1fKB",totalSize / 1000.0f ];
    }
    else
    {
        totalSizeString = [NSString stringWithFormat:@"%.1fB",totalSize / 1.0f];
    }
    return totalSizeString;
}

// 清除cachePath文件夹下缓存大小
+ (BOOL)clearCaches {
    // 拿到cachePath路径的下一级目录的子文件夹
    // contentsOfDirectoryAtPath:error:递归
    // subpathsAtPath:不递归
    NSArray *subpathArray = [fileManager contentsOfDirectoryAtPath:cachePath error:nil];
    // 如果数组为空，说明没有缓存或者用户已经清理过，此时直接return
    if (subpathArray.count == 0)
    {
#ifdef DEBUG
        PNSLog(@"此缓存路径很干净,不需要再清理了");
#else
#endif
        return NO;
    }
    NSError *error = nil;
    NSString *filePath = nil;
    BOOL flag = NO;
    
    for (NSString *subpath in subpathArray)
    {
        filePath = [cachePath stringByAppendingPathComponent:subpath];
        
        if ([fileManager fileExistsAtPath:cachePath])
        {
            // 删除子文件夹
            BOOL isRemoveSuccessed = [fileManager removeItemAtPath:filePath error:&error];
            
            if (isRemoveSuccessed)
            { // 删除成功
                flag = YES;
            }
        }
    }
    
    if (NO == flag)
    {
#ifdef DEBUG
        PNSLog(@"提示:您已经清理了所有可以访问的文件,不可访问的文件无法删除");  // 调试阶段才打印
#else
#endif
    }
    return flag;
}

@end
