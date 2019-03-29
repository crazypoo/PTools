//
//  IGFileDownLoadManager.m
//  CloudGateCustom
//
//  Created by 邓杰豪 on 2019/3/11.
//  Copyright © 2019年 邓杰豪. All rights reserved.
//

#import "IGFileDownLoadManager.h"
#import "PMacros.h"
#import <AFNetworking/AFNetworking.h>

@implementation IGFileDownLoadManager

+(void)fileDownloadWithUrl:(NSString * _Nonnull)fileURL withFileSavePath:(NSString * _Nonnull)savePath withTimeOut:(NSTimeInterval)timeout progress:(void (^)(NSProgress *downloadProgress))downloadProgressBlock completionHandler:(void (^)(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error))block
{
    kShowNetworkActivityIndicator();

    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    //创建AFN的manager对象
    AFHTTPSessionManager *manager = [[AFHTTPSessionManager alloc] initWithSessionConfiguration:configuration];
    //构造URL对象
    NSURL *url = [NSURL URLWithString:fileURL];
#if DEBUG
    PNSLog(@"CurrentDownURL:%@",url.description);
#endif
    //构造request对象
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setTimeoutInterval:timeout];

    //使用系统类创建downLoad Task对象
    NSURLSessionDownloadTask *task = [manager downloadTaskWithRequest:request progress:^(NSProgress * _Nonnull downloadProgress) {
        dispatch_async(dispatch_get_main_queue(), ^{
            downloadProgressBlock(downloadProgress);
        });
    } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
        //返回下载到哪里(返回值是一个路径)
        //拼接存放路径
        return [[NSURL URLWithString:[NSString stringWithFormat:@"file://%@",savePath]] URLByAppendingPathComponent:[response suggestedFilename]];
    } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
        block(response,filePath,error);
        kHideNetworkActivityIndicator();
    }];
    //开始请求
    [task resume];

}

@end
