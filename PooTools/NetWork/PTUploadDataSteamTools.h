//
//  PTUploadDataSteamTools.h
//  PooTools_Example
//
//  Created by 邓杰豪 on 2018/12/22.
//  Copyright © 2018年 crazypoo. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, CGUploadType) {
    CGUploadTypeGIF,
    CGUploadTypeJPG,
    CGUploadTypePNG,
    CGUploadTypeJPEG,
    CGUploadTypeMP4,
    CGUploadTypeAUDIO,
    CGUploadTypeFLV,
    CGUploadTypeMP3,
    CGUploadTypeFULLVIEW,
    CGUploadTypeZIPFILE
};

NS_ASSUME_NONNULL_BEGIN

typedef void (^PTUploadDataToServerSuccessBlock)(NSDictionary * _Nonnull result);
typedef void (^PTUploadDataToServerFailureBlock)(NSError *error);

@interface PTUploadDataModel : NSObject
@property (nonatomic,strong) UIImage *uploadImage;
@property (nonatomic,assign) CGUploadType imageType;
@property (nonatomic,strong) NSString *imageName;
@property (nonatomic,strong) NSData *imageData;
@property (nonatomic,strong) NSString *imageDataName;
@end

@interface PTUploadDataSteamTools : NSObject
/*! @brief 上传方法
 * @param view 初始化在哪个界面
 * @param parameters 上传数据字典
 * @param serverAddress 上传地址
 * @param dataModelArr 上传图片model
 * @param timeoutInterval 超时时间
 * @param successBlock 成功回调
 * @param failureBlock 失败回调
 */
+(void)uploadComboDataSteamProgressInView:(UIView *)view
                           withParameters:(NSDictionary *)parameters
                        withServerAddress:(NSString *)serverAddress
                               imageArray:(NSArray <PTUploadDataModel *>*)dataModelArr
                                  timeOut:(NSTimeInterval)timeoutInterval
                                  success:(PTUploadDataToServerSuccessBlock)successBlock
                                  failure:(PTUploadDataToServerFailureBlock)failureBlock;
@end

NS_ASSUME_NONNULL_END
