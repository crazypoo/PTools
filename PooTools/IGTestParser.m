//
//  IGTestParser.m
//  IGHTTPClient
//
//  Created by GavinHe on 16/4/19.
//  Copyright © 2016年 GavinHe. All rights reserved.
//

#import "IGTestParser.h"

@implementation IGTestParser

- (id)parseResponseObject:(id)obj error:(NSError *__autoreleasing *)error{
    if (obj && [obj isKindOfClass:[NSDictionary class]]) {
        switch (_parserFlag) {
            case IGTestParserFlag_App: {
                return obj[@"app"]?obj[@"app"]:nil;
            }
            case IGTestParserFlag_Version: {
                return obj[@"version"]?obj[@"version"]:nil;
            }
        }
        
    }
    return obj;
}

@end
