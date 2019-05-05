//
//  NSURLSessionTask+HTTPClient.m
//  IGWPT
//
//  Created by GavinHe on 16/1/27.
//
//

#import "NSURLSessionTask+IGHTTPClient.h"
#import <objc/runtime.h>

#define IGURLSessionTaskExtraInfos     @"IGURLSessionTaskExtraInfos"

#define IGURLSessionTaskTag            @"IGURLSessionTaskTag"

#define IGURLSessionTaskParserKey      @"IGURLSessionTaskParserKey"

#define IGURLSessionTaskSaveRespString @"IGURLSessionTaskSaveRespString"
#define IGURLSessionTaskRespString     @"IGURLSessionTaskRespString"


#define IGURLSessionTaskBatchSupport   @"IGURLSessionTaskBatchSupport"


@implementation NSURLSessionTask (IGHTTPClient)

- (NSMutableDictionary *)IGExtraInfos{
    NSMutableDictionary *tmp = objc_getAssociatedObject(self, IGURLSessionTaskExtraInfos);
    if (!tmp) {
        tmp = [NSMutableDictionary new];
        objc_setAssociatedObject(self, IGURLSessionTaskExtraInfos, tmp, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return tmp;
}

- (id)ig_extraObjectForKey:(NSString*)key{
    if (key && key.length!=0 && [self IGExtraInfos]) {
        return [self IGExtraInfos][key];
    }
    return nil;
}

- (void)ig_setExtraObject:(id)obj forKey:(NSString*)key{
    if (key && key.length!=0 && obj && [self IGExtraInfos]) {
        [[self IGExtraInfos] setObject:obj forKey:key];
    }
}

// Mark
- (NSInteger)ig_tag{
    NSNumber *tagN = [self ig_extraObjectForKey:IGURLSessionTaskTag];
    return tagN?[tagN integerValue]:0;
}

- (void)ig_setTag:(NSInteger)tag{
    [self ig_setExtraObject:@(tag) forKey:IGURLSessionTaskTag];
}

- (NSString*)ig_parserKey{
    return [self ig_extraObjectForKey:IGURLSessionTaskParserKey];
}

- (void)ig_setParserKey:(NSString*)key{
    [self ig_setExtraObject:key forKey:IGURLSessionTaskParserKey];
}

// Response String
- (BOOL)ig_saveResponseString{
    NSNumber *tmp = [self ig_extraObjectForKey:IGURLSessionTaskSaveRespString];
    return tmp?[tmp boolValue]:YES;
}

- (void)ig_setSaveResponseString:(BOOL)isSave{
    [self ig_setExtraObject:@(isSave) forKey:IGURLSessionTaskSaveRespString];
}


- (NSString*)ig_responseString{
    NSString *str = [self ig_extraObjectForKey:IGURLSessionTaskRespString];
    return str;
}

- (void)ig_setResponseString:(NSString*)string{
    [self ig_setExtraObject:string forKey:IGURLSessionTaskRespString];
}

#pragma mark - ----> Batch
- (id)ig_batchTaskSupport{
    return objc_getAssociatedObject(self, IGURLSessionTaskBatchSupport);
}

- (void)ig_setBatchTaskSupport:(id)obj{
    objc_setAssociatedObject(self, IGURLSessionTaskBatchSupport, obj, OBJC_ASSOCIATION_ASSIGN);
}
@end
