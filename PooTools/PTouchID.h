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
    TouchIDStatusSuccess,//成功
    TouchIDStatusDuplicateItem,//试多一次
    TouchIDStatusItemNotFound,//没有发现
    TouchIDStatusKeyboardIDNotFound,//没有密码
    TouchIDStatusTouchIDNotFound,//没有touchid
    TouchIDStatusAlertCancel,//弹出验证框后按取消
    TouchIDStatusPassWordKilled,//失效
    TouchIDStatusUnknowStatus,//未知状态
    TouchIDStatusKeyboardCancel,//touchid键盘取消
    TouchIDStatusKeyboardTouchID,//输入密码
    TouchIDStatusTouchIDNotOpen,//touchid开启不了
    TouchIDStatusAuthenticationFailed,//验证失败
    TouchIDStatusSystemCancel//系统取消
} TouchIDStatus;

@protocol PTouchIDDelegate <NSObject>
-(void)touchIDStatus:(TouchIDStatus)status;
@end

@interface PTouchID : NSObject
@property (nonatomic, weak) id<PTouchIDDelegate>delegate;
@property (nonatomic, copy) void(^touchIDBlock)(TouchIDStatus touchIDStatus);
//初始化
+(instancetype)defaultTouchID;
-(void)initTouchID;
//TouchID操作
-(void)deleteTouchID;
-(void)keyboardAndTouchID;
-(void)touchIDAction;
@end
