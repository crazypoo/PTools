//
//  PTouchID.m
//  adasdasdadadasdasdadadadad
//
//  Created by MYX on 2017/4/24.
//  Copyright © 2017年 邓杰豪. All rights reserved.
//

#import "PBiologyID.h"
#import <LocalAuthentication/LocalAuthentication.h>
#import <Security/Security.h>
#import "PMacros.h"

static PBiologyID *pTouchID = nil;

@interface PBiologyID()

@property (nonatomic, strong) NSString *strBeDelete;
@property (nonatomic, assign) BiologyIDVerifyStatusType biologyIDVerifyType;
@property (nonatomic, strong) LAContext *security;
@end

@implementation PBiologyID

+(instancetype)defaultBiologyID
{
    @synchronized (self) {
        if (!pTouchID) {
            pTouchID = [[PBiologyID alloc] init];
        }
        
        GCDWithGlobal(
                      [pTouchID verifyBiologyIDAction];
                      );
        return pTouchID;
    }
}

-(void)verifyBiologyIDAction
{
    if (@available(iOS 8.0, *)) {
        self.security = [[LAContext alloc] init];
        
        NSError *error = nil;
        BOOL isCanEvaluatePolicy = [self.security canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:&error];
        //TODO:TOUCHID是否存在
        if (error) {
            if (self.biologyIDBlock) {
                self.biologyIDBlock(BiologyIDTypeNone);
            }
        }
        else
        {
            if (isCanEvaluatePolicy) {
                if (@available(iOS 11.0, *)) {
                    switch (self.security.biometryType) {
                        case LABiometryNone:
                        {
                            if (self.biologyIDBlock) {
                                self.biologyIDBlock(BiologyIDTypeNone);
                            }
                        }
                            break;
                        case LABiometryTypeTouchID:
                        {
                            if (self.biologyIDBlock) {
                                self.biologyIDBlock(BiologyIDTypeTouchID);
                            }
                        }
                            break;
                        case LABiometryTypeFaceID:
                        {
                            if (self.biologyIDBlock) {
                                self.biologyIDBlock(BiologyIDTypeFaceID);
                            }
                        }
                            break;
                        default:
                            break;
                    }
                }
                else
                {
                    // Fallback on earlier versions
                    if (self.biologyIDBlock) {
                        self.biologyIDBlock(BiologyIDTypeTouchID);
                    }
                }
            }
            else
            {
                if (self.biologyIDBlock) {
                    self.biologyIDBlock(BiologyIDTypeNone);
                }
            }
        }
    }
    else
    {
        if (self.biologyIDBlock) {
            self.biologyIDBlock(BiologyIDTypeNone);
        }
    }
}

-(void)biologyAction
{
    NSString *touchIDAlertTitle = @"生物技术验证";
    LAPolicy evaluatePolicyType;
    if (@available(iOS 9.0, *)) {
        evaluatePolicyType = LAPolicyDeviceOwnerAuthentication;
    }
    else
    {
        evaluatePolicyType = LAPolicyDeviceOwnerAuthenticationWithBiometrics;
    }
    
    //TODO:TOUCHID开始运作
    [self.security evaluatePolicy:evaluatePolicyType localizedReason:touchIDAlertTitle reply:^(BOOL succes, NSError *error)
     {
         if (succes)
         {
             self.biologyIDVerifyType = BiologyIDVerifyStatusTypeSuccess;
             if ([self.delegate respondsToSelector:@selector(biologyIDVerifyStatus:)]) {
                 [self.delegate biologyIDVerifyStatus:self.biologyIDVerifyType];
             }
             if (self.biologyIDVerifyBlock) {
                 self.biologyIDVerifyBlock(self.biologyIDVerifyType);
             }
         }
         else
         {
             switch (error.code) {
                 case LAErrorSystemCancel:
                 {
                     self. biologyIDVerifyType = BiologyIDVerifyStatusTypeSystemCancel;
                     break;
                 }
                 case LAErrorUserCancel:
                 {
                     self.biologyIDVerifyType = BiologyIDVerifyStatusTypeAlertCancel;
                     break;
                 }
                 case LAErrorAuthenticationFailed:
                 {
                     self.biologyIDVerifyType = BiologyIDVerifyStatusTypeAuthenticationFailed;
                     break;
                 }
                 case LAErrorPasscodeNotSet:
                 {
                     self.biologyIDVerifyType = BiologyIDVerifyStatusTypeKeyboardIDNotFound;
                     break;
                 }
                 case LAErrorTouchIDNotAvailable:
                 {
                     self.biologyIDVerifyType = BiologyIDVerifyStatusTypeTouchIDNotOpen;
                     break;
                 }
                 case LAErrorTouchIDNotEnrolled:
                 {
                     self.biologyIDVerifyType = BiologyIDVerifyStatusTypeTouchIDNotFound;
                     break;
                 }
                 case LAErrorUserFallback:
                 {
                     [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                         self.biologyIDVerifyType = BiologyIDVerifyStatusTypeKeyboardTouchID;
                     }];
                     break;
                 }
                 default:
                 {
                     [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                         self.biologyIDVerifyType = BiologyIDVerifyStatusTypeUnknowStatus;
                     }];
                     break;
                 }
             }
             if ([self.delegate respondsToSelector:@selector(biologyIDVerifyStatus:)]) {
                 [self.delegate biologyIDVerifyStatus:self.biologyIDVerifyType];
             }
             if (self.biologyIDVerifyBlock) {
                 self.biologyIDVerifyBlock(self.biologyIDVerifyType);
             }
         }
     }];

}


-(void)deleteBiologyID
{
    NSDictionary *query = @{
                            (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
                            (__bridge id)kSecAttrService: @"PTouchIDService"
                            };
    
    GCDWithGlobal(
                  OSStatus status = SecItemDelete((__bridge CFDictionaryRef)(query));
                  
                  switch (status) {
                      case errSecSuccess:
                          self.biologyIDVerifyType = BiologyIDVerifyStatusTypePassWordKilled;
                          break;
                      case errSecDuplicateItem:
                          self.biologyIDVerifyType = BiologyIDVerifyStatusTypeDuplicateItem;
                          break;
                      case errSecItemNotFound:
                          self.biologyIDVerifyType = BiologyIDVerifyStatusTypeItemNotFound;
                          break;
                      case -26276:
                          self.biologyIDVerifyType = BiologyIDVerifyStatusTypeAlertCancel;
                      default:
                          break;
                  }
                  if ([self.delegate respondsToSelector:@selector(biologyIDVerifyStatus:)]) {
                      [self.delegate biologyIDVerifyStatus:self.biologyIDVerifyType];
                  }
                  if (self.biologyIDVerifyBlock) {
                      self.biologyIDVerifyBlock(self.biologyIDVerifyType);
                  }
                  );
}

@end
