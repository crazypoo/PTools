//
//  NSString+Regulars.h
//  Tongxunlu
//
//  Created by 何桂强 on 14-9-3.
//  Copyright (c) 2014年 广州文思海辉亚信外派iOS开发小组. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (Regulars)
-(BOOL)isA2Z;
-(BOOL)isNumber;
-(BOOL)isNumberAndWord;
-(BOOL)isMail;
-(BOOL)isMobilePhoneNum;
-(BOOL)isPooPhoneNum;
-(BOOL)isHomePhone;
-(BOOL)isValidateIdentity;
-(BOOL)isIPAddress;
-(BOOL)isUrlString;
-(BOOL)isVaildRealName;
@end
