//
//  DOGobalFileManager.h
//  Diou
//
//  Created by ken lam on 2021/6/29.
//  Copyright © 2021 DO. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface DOGobalFileManager : NSObject
+(NSString *)gobalShareFileURL;
+(void)createExcelFilePath;
+(void)createLogFilePath;
+(NSString *)gobalLogFileURL;
+(BOOL)isFileExist:(NSString *)fileName withFilePath:(NSString *)filePaths;

+ (NSString *)p_setupFileRename:(NSString *)filePath;
+(void)test:(NSURL *)url;

+(NSString *)gobalCacheFileURL;
+(void)createCacheFilePath;
@end

NS_ASSUME_NONNULL_END
