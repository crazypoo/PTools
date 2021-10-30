//
//  IGHTTPRequestSerializer.m
//  IGWPT
//
//  Created by GavinHe on 16/1/13.
//
//

#import "IGHTTPRequestSerializer.h"
#import "IGHTTPRequestBuilderManager.h"

#ifndef __OPTIMIZE__
#define IGHTTPRequestSerializerDefaultShowLog YES
#else
#define IGHTTPRequestSerializerDefaultShowLog NO
#endif

@implementation IGHTTPRequestSerializer

- (instancetype)init {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    self.showLog = IGHTTPRequestSerializerDefaultShowLog;
    
    return self;
}

- (NSMutableURLRequest *)requestWithMethod:(NSString *)method
                                 URLString:(NSString *)URLString
                                parameters:(id)parameters
                                     error:(NSError *__autoreleasing *)error{
    return [super requestWithMethod:method URLString:URLString parameters:parameters error:error];
}

- (NSMutableURLRequest *)requestWithMethod:(NSString *)method
                                 URLString:(NSString *)URLString
                                parameters:(id)parameters
                                builderKey:(NSString*)builderKey
                                     error:(NSError *__autoreleasing *)error{
    if (builderKey && builderKey.length > 0) {
        if (_showLog) NSLog(@"request builder Key: %@",builderKey);

        id<IGHTTPRequestBuilder> builder = [[IGHTTPRequestBuilderManager defaultManager] builderWithKey:builderKey];
        
        if (builder) {
            NSError *builderError;
            NSMutableURLRequest *request = [builder requestWithMethod:method URLString:URLString parameters:parameters error:error];
            if (request || builderError) {
                *error = builderError;
                return request;
            }else{
                if (_showLog) NSLog(@"builder give up");
            }
        }else{
            if (_showLog) NSLog(@"not find builder");
        }
    }

    return [self requestWithMethod:method URLString:URLString parameters:parameters error:error];
}

@end
