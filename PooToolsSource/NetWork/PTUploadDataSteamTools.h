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

typedef void (^PTUploadDataToServerSuccessBlock)(NSDictionary * _Nonnull result);
typedef void (^PTUploadDataToServerFailureBlock)(NSError * _Nonnull error);

@interface PTUploadDataModel : NSObject
@property (nonatomic,strong) UIImage * _Nullable uploadImage;
@property (nonatomic,assign) CGUploadType imageType;
@property (nonatomic,strong) NSString * _Nonnull imageName;
@property (nonatomic,strong) NSData * _Nonnull imageData;
@property (nonatomic,strong) NSString * _Nonnull imageDataName;
@end

@interface PTUploadDataSteamTools : NSObject

+ (instancetype _Nonnull )sharedInstance;

/*! @brief 上传方法
 * @param view 初始化在哪个界面
 * @param parameters 上传数据字典
 * @param serverAddress 上传地址
 * @param dataModelArr 上传图片model
 * @param timeoutInterval 超时时间
 * @param successBlock 成功回调
 * @param failureBlock 失败回调
 */
-(void)uploadComboDataSteamProgressInView:(UIView  * _Nullable )view
                           withParameters:(NSDictionary * _Nullable)parameters
                        withServerAddress:(NSString * _Nonnull)serverAddress
                               imageArray:(NSArray <PTUploadDataModel *>* _Nonnull)dataModelArr
                                  timeOut:(NSTimeInterval)timeoutInterval
                                  success:(PTUploadDataToServerSuccessBlock _Nonnull)successBlock
                                  failure:(PTUploadDataToServerFailureBlock _Nonnull)failureBlock;
@end
