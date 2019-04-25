//
//  PGetIpAddresses.h
//  MeijiaInHouse
//
//  Created by 邓杰豪 on 2017/9/28.
//  Copyright © 2017年 邓杰豪. All rights reserved.
//

#import <Foundation/Foundation.h>

#define IOS_CELLULAR    @"pdp_ip0"
#define IOS_WIFI        @"en0"
//#define IOS_VPN       @"utun0"
#define IP_ADDR_IPv4    @"ipv4"
#define IP_ADDR_IPv6    @"ipv6"

@class PTGetIpModel;

typedef void(^GetIPModel)(BOOL success,PTGetIpModel *ipModel);


@interface PTGetIpModel : NSObject
@property (nonatomic , copy) NSString              * country_id;
@property (nonatomic , copy) NSString              * county_id;
@property (nonatomic , copy) NSString              * isp;
@property (nonatomic , copy) NSString              * area;
@property (nonatomic , copy) NSString              * area_id;
@property (nonatomic , copy) NSString              * city_id;
@property (nonatomic , copy) NSString              * ip;
@property (nonatomic , copy) NSString              * city;
@property (nonatomic , copy) NSString              * region;
@property (nonatomic , copy) NSString              * county;
@property (nonatomic , copy) NSString              * region_id;
@property (nonatomic , copy) NSString              * isp_id;
@property (nonatomic , copy) NSString              * country;
@end


@interface PGetIpAddresses : NSObject
+ (NSString *)getIPAddress:(BOOL)preferIPv4;
+ (NSDictionary *)getIPAddresses;
/*! @brief 此方法是同步请求,必须配合gcd去异步请求
 */
+ (void)deviceWANIPAddress:(GetIPModel)block;
@end
