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

/*! @brief 正则表达式(是否电话)
 */
-(BOOL)isMobilePhoneNum;

/*! @brief 判断字符串是否银行卡号
 */
- (BOOL)isBankCard;

/*! @brief 判断字符串是否银行卡号并返回属于哪个银行
 */
- (NSString *)returnBankName;

@end
