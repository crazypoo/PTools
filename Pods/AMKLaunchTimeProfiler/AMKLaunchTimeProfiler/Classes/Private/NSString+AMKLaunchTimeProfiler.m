//
//  NSString+AMKLaunchTimeProfiler.m
//  AMKLaunchTimeProfiler
//
//  Created by mengxinxin on 2022/5/12.
//

#import "NSString+AMKLaunchTimeProfiler.h"
#include <CommonCrypto/CommonCrypto.h>

@implementation NSString (AMKLaunchTimeProfiler)

#pragma mark - Init Methods

#pragma mark - Getters & Setters

#pragma mark - Data & Networking

#pragma mark - Public Methods

- (NSString *)amkltp_md5String {
    NSData *data = [self dataUsingEncoding:NSUTF8StringEncoding];
    
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5(data.bytes, (CC_LONG)data.length, result);
    return [NSString stringWithFormat:@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
            result[0], result[1], result[2], result[3],
            result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11],
            result[12], result[13], result[14], result[15]
    ];
}

#pragma mark - Private Methods

#pragma mark - Notifications

#pragma mark - KVO

#pragma mark - Protocol

#pragma mark - Overrides

#pragma mark - Helper Methods

@end
