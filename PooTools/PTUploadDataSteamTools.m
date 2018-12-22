//
//  PTUploadDataSteamTools.m
//  PooTools_Example
//
//  Created by 邓杰豪 on 2018/12/22.
//  Copyright © 2018年 crazypoo. All rights reserved.
//

#import "PTUploadDataSteamTools.h"

#import <AFNetworking/AFNetworking.h>
#import "YMShowImageView.h"
#import "WMHub.h"
#import <Masonry/Masonry.h>
#import "PMacros.h"

@implementation PTUploadDataSteamTools

+(void)uploadComboDataSteamProgressInView:(UIView *)view withParameters:(NSDictionary *)parameters withServerAddress:(NSString *)serverAddress withDataName:(NSString *)dataName imageArray:(NSArray <PTUploadDataModel *>*)dataModelArr timeOut:(NSTimeInterval)timeoutInterval success:(PTUploadDataToServerSuccessBlock)successBlock failure:(PTUploadDataToServerFailureBlock)failureBlock
{
    HZWaitingView *waitingView = [[HZWaitingView alloc] init];
    waitingView.mode = HZWaitingViewModeLoopDiagram;
    [view addSubview:waitingView];
    [waitingView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.offset(kSCREEN_WIDTH * 0.5);
        make.centerX.centerY.equalTo(view);
    }];
    
    //表单请求，上传文件
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];//请求
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];//响应
    manager.requestSerializer.timeoutInterval = timeoutInterval;
    [manager.responseSerializer setAcceptableContentTypes:[NSSet setWithObjects:@"application/json", @"text/json", @"text/javascript",@"textml",@"text/css",@"text/plain", @"application/javascript",@"application/json", @"application/x-www-form-urlencoded",@"multipart/form-data",@"image/jpg",@"image/png",@"image/jpeg",@"video/mp4",@"audio/mpeg",@"flv/qsv",@"mp3/mp3",@"application/octet-stream",@"text/html", nil]];
    
    [manager POST:serverAddress parameters:parameters constructingBodyWithBlock:^(id<AFMultipartFormData> _Nonnull formData){
        [WMHub hide];
        for (int i = 0; i < dataModelArr.count; i++)
        {
            PTUploadDataModel *model = dataModelArr[i];
            [formData appendPartWithFileData:model.imageData name:dataName fileName:model.imageName mimeType:[PTUploadDataSteamTools imageMimeTypeWith:model.imageType]];
        }
    }progress:^(NSProgress *uploadProgress){
        dispatch_async(dispatch_get_main_queue(), ^{
            waitingView.progress = uploadProgress.fractionCompleted;
        });
    }success:^(NSURLSessionDataTask *task, id responseObject){
        [waitingView removeFromSuperview];
        NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingMutableContainers error:nil];
        if (successBlock) {
            successBlock(dic);
        }
    }failure:^(NSURLSessionDataTask *task, NSError *error){
        [waitingView removeFromSuperview];
        if (failureBlock) {
            failureBlock(error);
        }
    }];
}

+(NSString *)imageMimeTypeWith:(CGUploadType)type
{
    switch (type) {
        case CGUploadTypeGIF:
        {
            return @"image/gif";
        }
            break;
        case CGUploadTypeFULLVIEW:
        {
            return @"image/jpg";
        }
            break;
        case CGUploadTypeMP4:
        {
            return @"video/mp4";
        }
            break;
        case CGUploadTypeJPG:
        {
            return @"image/jpg";
        }
            break;
        case CGUploadTypePNG:
        {
            return @"image/png";
        }
            break;
        case CGUploadTypeJPEG:
        {
            return @"image/jpeg";
        }
            break;
        case CGUploadTypeAUDIO:
        {
            return @"audio/mpeg";
        }
            break;
        case CGUploadTypeFLV:
        {
            return @"flv/qsv";
        }
            break;
        case CGUploadTypeMP3:
        {
            return @"mp3/mp3";
        }
            break;
        default:
        {
            return @"image/jpg";
        }
            break;
    }
    return nil;
}

@end
