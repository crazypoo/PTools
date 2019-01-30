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
    CGUploadTypeFULLVIEW
};

typedef void (^PTUploadDataToServerSuccessBlock)(NSDictionary *result);
typedef void (^PTUploadDataToServerFailureBlock)(NSError *error);

@interface PTUploadDataModel : NSObject
@property (nonatomic,strong) UIImage *uploadImage;
@property (nonatomic,assign) CGUploadType imageType;
@property (nonatomic,strong) NSString *imageName;
@property (nonatomic,strong) NSData *imageData;
@property (nonatomic,strong) NSString *imageDataName;
@end

NS_ASSUME_NONNULL_BEGIN

@interface PTUploadDataSteamTools : NSObject
+(void)uploadComboDataSteamProgressInView:(UIView *)view withParameters:(NSDictionary *)parameters withServerAddress:(NSString *)serverAddress imageArray:(NSArray <PTUploadDataModel *>*)dataModelArr timeOut:(NSTimeInterval)timeoutInterval success:(PTUploadDataToServerSuccessBlock)successBlock failure:(PTUploadDataToServerFailureBlock)failureBlock;
@end

NS_ASSUME_NONNULL_END
