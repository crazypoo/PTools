//
//  IGTestParser.h
//  IGHTTPClient
//
//  Created by GavinHe on 16/4/19.
//  Copyright © 2016年 GavinHe. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "IGJSONResponseObjectParser.h"


#define pkIGTestParserApp     @"pkIGTestParserApp"

#define pkIGTestParserVersion @"pkIGTestParserVersion"

typedef NS_ENUM(NSInteger, IGTestParserFlag) {
    IGTestParserFlag_App = 0,
    IGTestParserFlag_Version
};

@interface IGTestParser : NSObject<IGJSONResponseObjectParser>

@property (nonatomic,assign) IGTestParserFlag parserFlag;

- (id)parseResponseObject:(id)obj error:(NSError *__autoreleasing *)error;

@end
