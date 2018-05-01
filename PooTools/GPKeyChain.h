//
//  GPKeyChain.h
//  Tongxunlu
//
//  Created by crazypoo on 14/7/6.
//  Copyright (c) 2014年 广州文思海辉亚信外派iOS开发小组. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GPKeyChain : NSObject

+ (void) saveUserName:(NSString*)userName
      userNameService:(NSString*)userNameService
             psaaword:(NSString*)pwd
      psaawordService:(NSString*)pwdService;

+ (void) deleteWithUserNameService:(NSString*)userNameService
                   psaawordService:(NSString*)pwdService;

+ (NSString*) getUserNameWithService:(NSString*)userNameService;

+ (NSString*) getPasswordWithService:(NSString*)pwdService;
@end
