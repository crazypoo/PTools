//
//  IGHTTPRequestBuilderManager.h
//  IGWPT
//
//  Created by GavinHe on 16/4/6.
//
//

#import <Foundation/Foundation.h>

#import "IGHTTPRequestBuilder.h"

typedef NS_ENUM(NSInteger, IGHTTPRequestBuilderRegistResult) {
    IGHTTPRequestBuilderRegistResultSuccess = 0,
    IGHTTPRequestBuilderRegistResultExisted ,
    IGHTTPRequestBuilderRegistResultIsNotBuilder ,
    IGHTTPRequestBuilderRegistResultWrongKey
};

@interface IGHTTPRequestBuilderManager : NSObject
+(instancetype)defaultManager;

- (IGHTTPRequestBuilderRegistResult)registBuilder:(id<IGHTTPRequestBuilder>)builder forKey:(NSString*)key;

- (void)unregisterBuilderWithKey:(NSString*)key;

- (id<IGHTTPRequestBuilder>)builderWithKey:(NSString*)key;

@end
