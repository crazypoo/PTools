//
//  PTUploadDataSteamTools.h
//  PooTools_Example
//
//  Created by 邓杰豪 on 2018/12/22.
//  Copyright © 2018年 crazypoo. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "PTUploadDataModel.h"

typedef void (^PTUploadDataToServerSuccessBlock)(NSDictionary *result);
typedef void (^PTUploadDataToServerFailureBlock)(NSError *error);

NS_ASSUME_NONNULL_BEGIN

@interface PTUploadDataSteamTools : NSObject
+(void)uploadComboDataSteamProgressInView:(UIView *)view withParameters:(NSDictionary *)parameters withServerAddress:(NSString *)serverAddress withDataName:(NSString *)dataName imageArray:(NSArray <PTUploadDataModel *>*)dataModelArr timeOut:(NSTimeInterval)timeoutInterval success:(PTUploadDataToServerSuccessBlock)successBlock failure:(PTUploadDataToServerFailureBlock)failureBlock;
@end

NS_ASSUME_NONNULL_END
