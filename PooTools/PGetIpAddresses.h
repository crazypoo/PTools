//
//  PGetIpAddresses.h
//  MeijiaInHouse
//
//  Created by 邓杰豪 on 2017/9/28.
//  Copyright © 2017年 邓杰豪. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PGetIpAddresses : NSObject
+ (NSString *)getIPAddress:(BOOL)preferIPv4;
+ (NSDictionary *)getIPAddresses;
@end
