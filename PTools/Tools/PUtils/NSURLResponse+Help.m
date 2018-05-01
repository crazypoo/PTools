//
//  NSURLResponse+Help.m
//  PTools
//
//  Created by MYX on 2017/4/18.
//  Copyright © 2017年 crazypoo. All rights reserved.
//

#import "NSURLResponse+Help.h"
#import <dlfcn.h>

@implementation NSURLResponse (Help)
typedef CFHTTPMessageRef (*MYURLResponseGetHTTPResponse)(CFURLRef response);
- (NSString *)getHTTPVersion {
    NSURLResponse *response = self;
    NSString *version;
    // 获取CFURLResponseGetHTTPResponse的函数实现
    NSString *funName = @"CFURLResponseGetHTTPResponse";
    MYURLResponseGetHTTPResponse originURLResponseGetHTTPResponse =
    dlsym(RTLD_DEFAULT, [funName UTF8String]);
    SEL theSelector = NSSelectorFromString(@"_CFURLResponse");
    if ([response respondsToSelector:theSelector] &&
        NULL != originURLResponseGetHTTPResponse) {
        // 获取NSURLResponse的_CFURLResponse
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        CFTypeRef cfResponse = CFBridgingRetain([response performSelector:theSelector]);
#pragma clang diagnostic pop
        if (NULL != cfResponse) {
            // 将CFURLResponseRef转化为CFHTTPMessageRef
            CFHTTPMessageRef message = originURLResponseGetHTTPResponse(cfResponse);
            // 获取http协议版本
            CFStringRef cfVersion = CFHTTPMessageCopyVersion(message);
            if (NULL != cfVersion) {
                version = (__bridge NSString *)cfVersion;
                CFRelease(cfVersion);
            }
            CFRelease(cfResponse);
        }
    }
    // 获取失败的话则设置一个默认值
    if (nil == version || 0 == version.length) {
        version = @"HTTP/1.1";
    }
    return version;
}

@end
