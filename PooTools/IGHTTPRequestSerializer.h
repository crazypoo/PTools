//
//  IGHTTPRequestSerializer.h
//  IGWPT
//
//  Created by GavinHe on 16/1/13.
//
//

#import "AFURLRequestSerialization.h"

@interface IGHTTPRequestSerializer : AFHTTPRequestSerializer

@property (nonatomic,assign) BOOL showLog;

- (NSMutableURLRequest *)requestWithMethod:(NSString *)method
                                 URLString:(NSString *)URLString
                                parameters:(id)parameters
                                builderKey:(NSString*)builderKey
                                     error:(NSError *__autoreleasing *)error;

@end
