//
//  GPKeyChain.h
//  Tongxunlu
//
//  Created by crazypoo on 14/7/6.
//  Copyright (c) 2014年 广州文思海辉亚信外派iOS开发小组. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GPKeyChain : NSObject

/*! @brief KeyChain保存帐号密码
 */
+ (void)saveUserName:(NSString*)userName
      userNameService:(NSString*)userNameService
             psaaword:(NSString*)pwd
      psaawordService:(NSString*)pwdService;

/*! @brief KeyChain删除帐号密码
 */
+ (void)deleteWithUserNameService:(NSString*)userNameService
                   psaawordService:(NSString*)pwdService;

/*! @brief KeyChain获取帐号
 */
+ (NSString*)getUserNameWithService:(NSString*)userNameService;

/*! @brief KeyChain获取密码
 */
+ (NSString*)getPasswordWithService:(NSString*)pwdService;
@end
