//
//  NSString+Regulars.m
//  Tongxunlu
//
//  Created by 何桂强 on 14-9-3.
//  Copyright (c) 2014年 广州文思海辉亚信外派iOS开发小组. All rights reserved.
//

#import "NSString+Regulars.h"
#import "PMacros.h"

@implementation NSString (Regulars)

static NSString *A2Z = @"^[a-z]?$";
static NSString *Number = @"^[0-9]*$";
static NSString *NumberAndWord = @"^[0-9_a-zA-Z]*$";

static NSString *Mail = @"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}?$";

static NSString *MOBILE = @"^(86){0,1}1(3[0-9]|5[0-35-9]|8[025-9])\\d{8}$";
static NSString *CM     = @"^(86){0,1}1(34[0-8]|(3[5-9]|5[017-9]|8[278])\\d)\\d{7}$";
static NSString *CU     = @"^(86){0,1}1(3[0-2]|5[256]|8[56])\\d{8}$";
static NSString *CT     = @"^(86){0,1}1((33|53|8[09])[0-9]|349)\\d{7}$";
static NSString *POOPHONE = @"^1[3|4|5|7|8][0-9]\\d{8}$";
static NSString *HomePhone = @"^\\d{3}-?\\d{8}|\\d{4}-?\\d{8}$";
// NSString * PHS = @"^0(10|2[0-5789]|\\d{3})\\d{7,8}$";
static NSString *IpAddress = @"^(1\\d{2}|2[0-4]\\d|25[0-5]|[1-9]\\d|[1-9])\\.(1\\d{2}|2[0-4]\\d|25[0-5]|[1-9]\\d|\\d)\\.(1\\d{2}|2[0-4]\\d|25[0-5]|[1-9]\\d|\\d)\\.(1\\d{2}|2[0-4]\\d|25[0-5]|[1-9]\\d|\\d)$";
static NSString *URL = @"[a-zA-z]+://.*";

- (BOOL)isUrlString
{
    return [self checkWithRegular:URL];
}

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

-(BOOL)isPooPhoneNum
{
    return [self checkWithRegular:POOPHONE];
}

-(BOOL)isHomePhone
{
    return [self checkWithRegular:HomePhone];
}

-(BOOL)isIPAddress
{
    return [self checkWithRegular:IpAddress];
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

-(BOOL)isValidateIdentity
{
    //判断是否为空
    if (self == nil || self.length <= 0) {
        return NO;
    }
    //判断是否是18位，末尾是否是x
    NSString *regex2 = @"^(\\d{14}|\\d{17})(\\d|[xX])$";
    NSPredicate *identityCardPredicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@",regex2];
    if(![identityCardPredicate evaluateWithObject:self]){
        return NO;
    }
    //判断生日是否合法
    NSRange range = NSMakeRange(6,8);
    NSString *datestr = [self substringWithRange:range];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat : @"yyyyMMdd"];
    if([formatter dateFromString:datestr]==nil){
        return NO;
    }

    //判断校验位
    if(self.length == 18)
    {
        NSArray *idCardWi= @[ @"7", @"9", @"10", @"5", @"8", @"4", @"2", @"1", @"6", @"3", @"7", @"9", @"10", @"5", @"8", @"4", @"2" ]; //将前17位加权因子保存在数组里
        NSArray * idCardY=@[ @"1", @"0", @"10", @"9", @"8", @"7", @"6", @"5", @"4", @"3", @"2" ]; //这是除以11后，可能产生的11位余数、验证码，也保存成数组
        int idCardWiSum = 0; //用来保存前17位各自乖以加权因子后的总和
        for(int i = 0 ; i < 17 ; i++){
            idCardWiSum += [[self substringWithRange:NSMakeRange(i,1)] intValue] * [idCardWi[i] intValue];
        }

        int idCardMod = idCardWiSum%11;//计算出校验码所在数组的位置
        NSString *idCardLast = [self substringWithRange:NSMakeRange(17,1)];//得到最后一位身份证号码

        //如果等于2，则说明校验码是10，身份证号码最后一位应该是X
        if(idCardMod == 2){
            if([idCardLast isEqualToString:@"X"] || [idCardLast isEqualToString:@"x"]){
                return YES;
            }
            else
            {
                return NO;
            }
        }
        else
        {
            //用计算出的验证码与最后一位身份证号码匹配，如果一致，说明通过，否则是无效的身份证号码
            if([idCardLast intValue] == [idCardY[idCardMod] intValue])
            {
                return YES;
            }
            else
            {
                return NO;
            }
        }
    }
    return NO;
}

- (BOOL)isVaildRealName
{
    if (kStringIsEmpty(self))
    {
     return NO;
    }
    
    NSRange range1 = [self rangeOfString:@"·"];
    NSRange range2 = [self rangeOfString:@"•"];
    if(range1.location != NSNotFound ||   // 中文 ·
       range2.location != NSNotFound )    // 英文 •
    {
        //一般中间带 `•`的名字长度不会超过15位，如果有那就设高一点
        if ([self length] < 2 || [self length] > 15)
        {
            return NO;
        }
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^[\u4e00-\u9fa5]+[·•][\u4e00-\u9fa5]+$" options:0 error:NULL];
        
        NSTextCheckingResult *match = [regex firstMatchInString:self options:0 range:NSMakeRange(0, [self length])];
        
        NSUInteger count = [match numberOfRanges];
        
        return count == 1;
    }
    else
    {
        //一般正常的名字长度不会少于2位并且不超过8位，如果有那就设高一点
        if ([self length] < 2 || [self length] > 8) {
            return NO;
        }
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^[\u4e00-\u9fa5]+$" options:0 error:NULL];
        
        NSTextCheckingResult *match = [regex firstMatchInString:self options:0 range:NSMakeRange(0, [self length])];
        
        NSUInteger count = [match numberOfRanges];
        
        return count == 1;
    }
}

@end
