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
    TouchIDStatusSuccess,
    TouchIDStatusDuplicateItem,
    TouchIDStatusItemNotFound,
    TouchIDStatusKeyboardIDNotFound,
    TouchIDStatusTouchIDNotFound,
    TouchIDStatusAlertCancel,
    TouchIDStatusPassWordKilled,
    TouchIDStatusUnknowStatus,
    TouchIDStatusKeyboardCancel,
    TouchIDStatusKeyboardTouchID,
    TouchIDStatusTouchIDNotOpen,
    TouchIDStatusAuthenticationFailed,
    TouchIDStatusSystemCancel
} TouchIDStatus;


@protocol PTouchIDDelegate <NSObject>
-(void)touchIDStatus:(TouchIDStatus)status;
@end

@interface PTouchID : NSObject
@property (nonatomic, weak) id<PTouchIDDelegate>delegate;
//初始化
+(instancetype)defaultTouchID;
-(void)initTouchID;
//TouchID操作
-(void)deleteTouchID;
-(void)keyboardAndTouchID;
-(void)touchIDAction;
@end
