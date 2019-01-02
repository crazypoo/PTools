//
//  IGJSONResponseSerializer.h
//  IGWPT
//
//  Created by GavinHe on 16/1/13.
//
//

#import "AFURLResponseSerialization.h"

@class NSURLSessionTask;

@interface IGJSONResponseSerializer : AFJSONResponseSerializer

@property (nonatomic,assign) BOOL showLog;

- (id)responseObjectForResponse:(NSURLResponse *)response
                           data:(NSData *)data
                           task:(NSURLSessionTask*)task
                          error:(NSError *__autoreleasing *)error;

@end
