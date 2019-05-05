//
//  NSString+Extension.m
//  PooTools_Example
//
//  Created by 邓杰豪 on 2019/4/11.
//  Copyright © 2019 crazypoo. All rights reserved.
//

#import "NSString+Extension.h"

@implementation NSString (UTF8)
-(NSString *)stringToUTF8String:(UTF8StringType)type
{
    switch (type) {
        case UTF8StringTypeOC:
        {
            return [NSString stringWithCString:[self UTF8String] encoding:NSUnicodeStringEncoding];
        }
            break;
        case UTF8StringTypeC:
        {
            return (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,(CFStringRef)self,NULL,NULL,kCFStringEncodingUTF8));
        }
            break;
        default:
        {
            return @"";
        }
            break;
    }
    return @"";
}
@end
