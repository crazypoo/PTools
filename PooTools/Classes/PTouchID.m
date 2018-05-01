//
//  PTouchID.m
//  adasdasdadadasdasdadadadad
//
//  Created by MYX on 2017/4/24.
//  Copyright © 2017年 邓杰豪. All rights reserved.
//

#import "PTouchID.h"
#import <LocalAuthentication/LocalAuthentication.h>
#import <Security/Security.h>
#import "PMacros.h"

static PTouchID *pTouchID = nil;

@interface PTouchID()
{
    TouchIDStatus touchIDStatus;
}
@property (nonatomic, retain) NSString *strBeDelete;
@end

@implementation PTouchID

+(instancetype)defaultTouchID
{
    @synchronized (self) {
        if (!pTouchID) {
            pTouchID = [[PTouchID alloc] init];
        }
        [pTouchID initTouchID];
        return pTouchID;
    }
}

-(void)initTouchID
{
    CFErrorRef error = NULL;
    SecAccessControlRef sacObject;
    sacObject = SecAccessControlCreateWithFlags(kCFAllocatorDefault,
                                                kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
                                                kSecAccessControlUserPresence, &error);
    if(sacObject == NULL || error != NULL)
    {
        touchIDStatus = TouchIDStatusItemNotFound;
        if ([self.delegate respondsToSelector:@selector(touchIDStatus:)]) {
            [self.delegate touchIDStatus:touchIDStatus];
        }
        return;
    }
    
    NSDictionary *attributes = @{
                                 (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
                                 (__bridge id)kSecAttrService: @"PTouchIDService",
                                 (__bridge id)kSecValueData: [@"SECRET_PASSWORD_TEXT" dataUsingEncoding:NSUTF8StringEncoding],
                                 (__bridge id)kSecUseNoAuthenticationUI: @YES,
                                 (__bridge id)kSecAttrAccessControl: (__bridge id)sacObject
                                 };
    
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        OSStatus status =  SecItemAdd((__bridge CFDictionaryRef)attributes, nil);
        
        touchIDStatus = [self touchStatusReturn:status];
        
        if ([self.delegate respondsToSelector:@selector(touchIDStatus:)]) {
            [self.delegate touchIDStatus:touchIDStatus];
        }
    });

}

-(void)touchIDAction
{
    LAContext *security = [[LAContext alloc] init];
    
    NSError *error = nil;
    NSString *touchIDAlertTitle = @"验证TouchID";
    //TODO:TOUCHID是否存在
    if ([security canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:&error]) {
        //TODO:TOUCHID开始运作
        [security evaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics localizedReason:touchIDAlertTitle reply:^(BOOL succes, NSError *error)
         {
             if (succes) {
                 touchIDStatus = TouchIDStatusSuccess;
                 if ([self.delegate respondsToSelector:@selector(touchIDStatus:)]) {
                     [self.delegate touchIDStatus:touchIDStatus];
                 }
             }
             else
             {
                 NSLog(@"%@",error.localizedDescription);
                 switch (error.code) {
                     case LAErrorSystemCancel:
                     {
                         touchIDStatus = TouchIDStatusSystemCancel;
                         break;
                     }
                     case LAErrorUserCancel:
                     {
                         touchIDStatus = TouchIDStatusAlertCancel;
                         break;
                     }
                     case LAErrorAuthenticationFailed:
                     {
                         touchIDStatus = TouchIDStatusAuthenticationFailed;
                         break;
                     }
                     case LAErrorPasscodeNotSet:
                     {
                         touchIDStatus = TouchIDStatusKeyboardIDNotFound;
                         break;
                     }
                     case LAErrorTouchIDNotAvailable:
                     {
                         touchIDStatus = TouchIDStatusTouchIDNotOpen;
                         break;
                     }
                     case LAErrorTouchIDNotEnrolled:
                     {
                         touchIDStatus = TouchIDStatusTouchIDNotFound;
                         break;
                     }
                     case LAErrorUserFallback:
                     {
                         [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                             touchIDStatus = TouchIDStatusKeyboardTouchID;
                         }];
                         break;
                     }
                     default:
                     {
                         [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                             touchIDStatus = TouchIDStatusUnknowStatus;
                         }];
                         break;
                     }
                 }
                 if ([self.delegate respondsToSelector:@selector(touchIDStatus:)]) {
                     [self.delegate touchIDStatus:touchIDStatus];
                 }
             }
         }];
    }
    else
    {
        switch (error.code) {
            case LAErrorTouchIDNotEnrolled:
            {
                touchIDStatus = TouchIDStatusTouchIDNotFound;
                break;
            }
            case LAErrorPasscodeNotSet:
            {
                touchIDStatus = TouchIDStatusKeyboardIDNotFound;
                break;
            }
            default:
            {
                touchIDStatus = TouchIDStatusUnknowStatus;
                break;
            }
        }
        if ([self.delegate respondsToSelector:@selector(touchIDStatus:)]) {
            [self.delegate touchIDStatus:touchIDStatus];
        }
        NSLog(@"%@",error.localizedDescription);
    }
    
}

-(void)deleteTouchID
{
    NSDictionary *query = @{
                            (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
                            (__bridge id)kSecAttrService: @"PTouchIDService"
                            };
    
    GCDWithGlobal(
                  OSStatus status = SecItemDelete((__bridge CFDictionaryRef)(query));
                  
                  switch (status) {
                      case errSecSuccess:
                          touchIDStatus = TouchIDStatusPassWordKilled;
                          break;
                      case errSecDuplicateItem:
                          touchIDStatus = TouchIDStatusDuplicateItem;
                          break;
                      case errSecItemNotFound:
                          touchIDStatus = TouchIDStatusItemNotFound;
                          break;
                      case -26276:
                          touchIDStatus = TouchIDStatusAlertCancel;
                      default:
                          break;
                  }
                  if ([self.delegate respondsToSelector:@selector(touchIDStatus:)])
                  {
                      [self.delegate touchIDStatus:touchIDStatus];
                  }
                  );
}

-(void)keyboardAndTouchID
{
    NSDictionary *query = @{
                            (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
                            (__bridge id)kSecAttrService: @"PTouchIDService",
                            (__bridge id)kSecUseOperationPrompt: @"验证TouchID"
                            };
    
    NSDictionary *changes = @{
                              (__bridge id)kSecValueData: [@"UPDATED_SECRET_PASSWORD_TEXT" dataUsingEncoding:NSUTF8StringEncoding]
                              };
    
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        OSStatus status = SecItemUpdate((__bridge CFDictionaryRef)query, (__bridge CFDictionaryRef)changes);
        touchIDStatus = [self touchStatusReturn:status];
        if ([self.delegate respondsToSelector:@selector(touchIDStatus:)]) {
            [self.delegate touchIDStatus:touchIDStatus];
        }
    });
}

-(TouchIDStatus)touchStatusReturn:(OSStatus)status
{
    TouchIDStatus ss;
    switch (status) {
        case errSecSuccess:
            ss = TouchIDStatusSuccess;
            break;
        case errSecDuplicateItem:
            ss = TouchIDStatusDuplicateItem;
            break;
        case errSecItemNotFound:
            ss = TouchIDStatusItemNotFound;
            break;
        case -26276:
            ss = TouchIDStatusAlertCancel;
            break;
        case errSecUserCanceled:
            ss = TouchIDStatusKeyboardCancel;
            break;
        default:
            ss = TouchIDStatusUnknowStatus;
            break;
    }
    return ss;
}
@end
