//
//  PooCleanCache.h
//  CloudGateCustom
//
//  Created by mouth on 2018/5/16.
//  Copyright © 2018年 邓杰豪. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PooCleanCache : NSObject
/*! @brief 获取缓存大小
*/
+ (NSString *)getCacheSize;
/*! @brief 清理缓存
 */
+ (BOOL)clearCaches;
/*! @brief 获取文件的大小
 */
+ (long long)fileSizeAtPath:(NSString*)filePath;
/*! @brief 获取文件夹的大小
 */
+ (float)folderSizeAtPath:(NSString *)folderPath;
/*! @brief 清除某个文件内的文件
 */
+ (BOOL)cleanDocumentAtPath:(NSString *)floderPath;
@end
