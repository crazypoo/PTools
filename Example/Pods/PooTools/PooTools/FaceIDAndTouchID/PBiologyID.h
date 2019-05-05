//
//  PTouchID.h
//  adasdasdadadasdasdadadadad
//
//  Created by MYX on 2017/4/24.
//  Copyright © 2017年 邓杰豪. All rights reserved.
//

#import <Foundation/Foundation.h>
typedef enum
{
    BiologyIDVerifyStatusTypeSuccess,//成功
    BiologyIDVerifyStatusTypeDuplicateItem,//试多一次
    BiologyIDVerifyStatusTypeItemNotFound,//没有发现
    BiologyIDVerifyStatusTypeKeyboardIDNotFound,//没有密码
    BiologyIDVerifyStatusTypeTouchIDNotFound,//没有touchid
    BiologyIDVerifyStatusTypeAlertCancel,//弹出验证框后按取消
    BiologyIDVerifyStatusTypePassWordKilled,//失效
    BiologyIDVerifyStatusTypeUnknowStatus,//未知状态
    BiologyIDVerifyStatusTypeKeyboardCancel,//touchid键盘取消
    BiologyIDVerifyStatusTypeKeyboardTouchID,//输入密码
    BiologyIDVerifyStatusTypeTouchIDNotOpen,//touchid开启不了
    BiologyIDVerifyStatusTypeAuthenticationFailed,//验证失败
    BiologyIDVerifyStatusTypeSystemCancel//系统取消
} BiologyIDVerifyStatusType;

typedef NS_ENUM(NSInteger,BiologyIDType){
    BiologyIDTypeNone = 0,
    BiologyIDTypeFaceID,
    BiologyIDTypeTouchID
};

@protocol PBiologyIDDelegate <NSObject>
-(void)biologyIDVerifyStatus:(BiologyIDVerifyStatusType)status;
@end

@interface PBiologyID : NSObject
/*! @brief 生物技术验证代理
 */
@property (nonatomic, weak) id<PBiologyIDDelegate>delegate;
/*! @brief 生物技术验证回调
 */
@property (nonatomic, copy) void(^biologyIDVerifyBlock)(BiologyIDVerifyStatusType biologyIDVerifyStatus);
/*! @brief 生物技术功能回调
 */
@property (nonatomic, copy) void(^biologyIDBlock)(BiologyIDType biologyIDType);
/*! @brief 生物识别技术单例化
 */
+(instancetype)defaultBiologyID;
/*! @brief 验证生物技术
 */
-(void)verifyBiologyIDAction;
/*! @brief 删除生物技术
 */
-(void)deleteBiologyID;
/*! @brief 生物技术操作
 */
-(void)biologyAction;
@end
