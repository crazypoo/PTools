//
//  NSString+Regulars.m
//  Tongxunlu
//
//  Created by 何桂强 on 14-9-3.
//  Copyright (c) 2014年 广州文思海辉亚信外派iOS开发小组. All rights reserved.
//

#import "NSString+Regulars.h"

@implementation NSString (Regulars)

static NSString *A2Z = @"^[a-z]?$";
static NSString *Number = @"^[0-9]*$";
static NSString *NumberAndWord = @"^[0-9_a-zA-Z]*$";

static NSString *Mail = @"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}?$";

static NSString *MOBILE = @"^(86){0,1}1(3[0-9]|5[0-35-9]|8[025-9])\\d{8}$";
static NSString *CM     = @"^(86){0,1}1(34[0-8]|(3[5-9]|5[017-9]|8[278])\\d)\\d{7}$";
static NSString *CU     = @"^(86){0,1}1(3[0-2]|5[256]|8[56])\\d{8}$";
static NSString *CT     = @"^(86){0,1}1((33|53|8[09])[0-9]|349)\\d{7}$";
// NSString * PHS = @"^0(10|2[0-5789]|\\d{3})\\d{7,8}$";

-(BOOL)isA2Z{
    return [self checkWithRegular:A2Z];
}
-(BOOL)isNumber{
    return [self checkWithRegular:Number];
}
-(BOOL)isNumberAndWord{
    return [self checkWithRegular:NumberAndWord];
}

-(BOOL)isMail{
    return [self checkWithRegular:Mail];
}

-(BOOL)isMobilePhoneNum{
    return [self checkWithRegulars:@[MOBILE,CM,CU,CT]];
}

-(BOOL)checkWithRegular:(NSString*)expression{
    NSPredicate *regextest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", expression];
    return [regextest evaluateWithObject:self];
}

-(BOOL)checkWithRegulars:(NSArray*)expressions{
    BOOL res = NO;
    if (expressions && [expressions isKindOfClass:[NSArray class]]) {
        for (NSString *expression in expressions) {
            if ([expressions isKindOfClass:[NSString class]]) {
                NSPredicate *regextest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", expression];
                res = [regextest evaluateWithObject:self];
            }
            if (!res) {
                return NO;
            }
        }
    }
    return YES;
}
@end
