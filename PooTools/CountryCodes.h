//
//  CountryCodes.h
//  PooTools_Example
//
//  Created by 邓杰豪 on 2018/10/20.
//  Copyright © 2018年 crazypoo. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CountryCodeModel;

@interface CountryCodes : NSObject
+(NSMutableArray <CountryCodeModel *>*)countryCodes;
@end

@interface CountryCodeModel : NSObject
@property (nonatomic,copy) NSString *countryName;
@property (nonatomic,copy) NSString *countryCode;
@end
