//
//  IGFileDownLoadManager.h
//  CloudGateCustom
//
//  Created by 邓杰豪 on 2019/3/11.
//  Copyright © 2019年 邓杰豪. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface IGFileDownLoadManager : NSObject
+(void)fileDownloadWithUrl:(NSString * _Nonnull)fileURL withFileSavePath:(NSString * _Nonnull)savePath withTimeOut:(NSTimeInterval)timeout progress:(void (^)(NSProgress *downloadProgress))downloadProgressBlock completionHandler:(void (^)(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error))block;
@end

NS_ASSUME_NONNULL_END
