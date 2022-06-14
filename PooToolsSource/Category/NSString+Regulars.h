//
//  NSString+Regulars.h
//  Tongxunlu
//
//  Created by 何桂强 on 14-9-3.
//  Copyright (c) 2014年 广州文思海辉亚信外派iOS开发小组. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (Regulars)
/*! @brief 正则表达式(A到Z)
 */
-(BOOL)isA2Z;

/*! @brief 正则表达式(是否数字)
 */
-(BOOL)isNumber;

/*! @brief 正则表达式(是否数字和字母)
 */
-(BOOL)isNumberAndWord;

/*! @brief 正则表达式(是否邮箱)
 */
-(BOOL)isMail;

/*! @brief 正则表达式(是否电话)
 */
-(BOOL)isMobilePhoneNum;

/*! @brief 正则表达式(是否电话,这个貌似才能用)
 */
-(BOOL)isPooPhoneNum;

/*! @brief 正则表达式(是否家庭电话)
 */
-(BOOL)isHomePhone;

/*! @brief 正则表达式(是否身份证)
 */
-(BOOL)isValidateIdentity;

/*! @brief 正则表达式(是否IP地址)
 */
-(BOOL)isIPAddress;

/*! @brief 正则表达式(是否URL)
 */
-(BOOL)isUrlString;
-(BOOL)checkUrlWithString;

/*! @brief 正则表达式(是否中文名)
 */
-(BOOL)isVaildRealName;

/*! @brief 正则表达式(是否金钱)
 */
-(BOOL)isMoneyString;

/*! @brief 判断字符串是否银行卡号
 */
- (BOOL)isBankCard;

/*! @brief 判断字符串是否银行卡号并返回属于哪个银行
 */
- (NSString *)returnBankName;

/*! @brief 判断字符串是否中文
 */
- (BOOL)isChinese;

/*! @brief 判断字符串是否社会统一信用代码
 */
-(BOOL)isCOLTDCode;
/*! @brief 判断字符串是否护照
 */
-(BOOL)isPassportNumber;
/*! @brief 判断字符串是否中国车牌号码
 */
-(BOOL)isCNCarNumber;
/*! @brief 判断字符串是否第一个是英文字母
 */
-(BOOL)isLetterFirstAlphabet;

/*! @brief 判断字符串是否全小写或者全大写
 */
-(BOOL)isAlphabet:(BOOL)Lowercased;
@end
