//
//  IGHTTPRequestBuilder.h
//  IGWPT
//
//  Created by GavinHe on 16/4/6.
//
//

#import <Foundation/Foundation.h>

@protocol IGHTTPRequestBuilder <NSObject>
@required

- (NSMutableURLRequest *)requestWithMethod:(NSString *)method
                                 URLString:(NSString *)URLString
                                parameters:(id)parameters
                                     error:(NSError *__autoreleasing *)error;
@end
