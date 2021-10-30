//
//  NSString+MoneyString.m
//  LandloardTool
//
//  Created by 邓杰豪 on 2019/2/26.
//  Copyright © 2019年 邓杰豪. All rights reserved.
//

#import "NSString+MoneyString.h"

@implementation NSString (MoneyString)

-(NSString *)stringToMoneyString
{
    return [NSString stringWithFormat:@"%.2f",[self floatValue]];
}
@end
