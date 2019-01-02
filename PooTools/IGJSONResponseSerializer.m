//
//  IGJSONResponseSerializer.m
//  IGWPT
//
//  Created by GavinHe on 16/1/13.
//
//

#import "IGJSONResponseSerializer.h"

#import "IGJSONResponseObjectParserManager.h"
#import "NSURLSessionTask+IGHTTPClient.h"


#ifndef __OPTIMIZE__
#define IGJSONResponseSerializerDefaultShowLog YES
#else
#define IGJSONResponseSerializerDefaultShowLog NO
#endif

@implementation IGJSONResponseSerializer

- (instancetype)init {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    self.showLog = IGJSONResponseSerializerDefaultShowLog;
    
    return self;
}

+ (instancetype)serializerWithReadingOptions:(NSJSONReadingOptions)readingOptions {
    IGJSONResponseSerializer *serializer = [[self alloc] init];
    serializer.readingOptions = readingOptions;
    serializer.acceptableContentTypes = [serializer.acceptableContentTypes setByAddingObjectsFromSet:[NSSet setWithObjects:@"text/plain",@"text/html",nil]];
    return serializer;
}

- (id)responseObjectForResponse:(NSURLResponse *)response
                           data:(NSData *)data
                           task:(NSURLSessionTask*)task
                          error:(NSError *__autoreleasing *)error{
    NSString *respString = data?[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]:@"";
    if (data && _showLog) {
        
        NSLog(@"\n∆∆∆∆∆∆∆∆∆∆∆∆∆∆∆∆∆∆∆∆∆∆∆∆∆∆∆∆∆∆∆∆∆∆∆∆∆∆∆∆∆∆∆∆∆∆∆∆∆∆∆∆∆∆∆∆∆∆∆∆∆∆∆∆∆∆∆∆∆∆∆∆∆∆∆∆∆∆∆\nResponse String：\n%@\n\n\n",respString);
    }
    
    id responseObject = [super responseObjectForResponse:response data:data error:error];

    // 定制Response处理
    if (responseObject && task){
        if ([task ig_saveResponseString]) {
            [task ig_setResponseString:respString];
        }
        
        if([task ig_parserKey]) {
            NSString *pKey = [task ig_parserKey];
            if (_showLog)
                NSLog(@"task parser Key: %@",pKey);
            
            id<IGJSONResponseObjectParser> parser = [[IGJSONResponseObjectParserManager defaultManager] parserWithKey:pKey];
            if (parser) {
                NSError *parserError;
                id obj = [parser parseResponseObject:responseObject error:&parserError];
                if (obj || parserError) {
                    *error = parserError;
                    return obj;
                }else{
                    if (_showLog)
                        NSLog(@"parser give up");
                }
            }else{
                if (_showLog)
                    NSLog(@"not find parser");
            }
        }
    }

    return responseObject;
}

- (id)responseObjectForResponse:(NSURLResponse *)response
                           data:(NSData *)data
                          error:(NSError *__autoreleasing *)error
{
    [self validateResponse:(NSHTTPURLResponse *)response data:data error:error];
    
    return data;
}

@end
