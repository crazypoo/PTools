//
//  IGHTTPSetting.m
//  IGWPT
//
//  Created by GavinHe on 16/1/13.
//
//

#import "IGHTTPTools.h"

#import "NSError+HTTPClient.h"
#import "NSURLSessionTask+IGHTTPClient.h"

#import "IGBatchTask.h"

#import "IGJSONModel.h"

@implementation IGHTTPTools

#pragma mark - 工具

+(NSString*)errorInfoWithResponseCode:(IGHTTPResponseCode)code{
    return @"";
}

#pragma mark - ----> 网络图片
- (NSString*)thumbnailImageURLWithImageURL:(NSString*)imageURL{
    if (imageURL && [imageURL isKindOfClass:[NSString class]] && imageURL.length > 4) {
        NSString *extension = [imageURL pathExtension] ;
        if (extension && extension.length > 0) {
            NSString *lowExtension = [extension lowercaseString];
            if ([lowExtension isEqualToString:@"jpg"] ||
                [lowExtension isEqualToString:@"png"]) {
                return [[imageURL stringByDeletingPathExtension] stringByAppendingFormat:@"thumbnail.%@",extension];
            }
        }
    }
    return nil;
}

#pragma mark - ----> 参数组装
+(NSMutableDictionary*)translateArrayInDictionaryParameter:(NSDictionary*)parma{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    if (parma) {
        [parma enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            if ([obj isKindOfClass:[NSArray class]]) {
                NSDictionary *arrayDict = [IGHTTPTools translateArrayParameter:obj byKey:key];
                [dict setValuesForKeysWithDictionary:arrayDict];
            }else{
                [dict setValue:obj forKey:key];
            }
        }];
    }
    return dict;
}

+(NSMutableDictionary*)translateArrayParameter:(NSArray<NSDictionary*>*)arr byKey:(NSString*)key{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    if (key && key.length > 0 &&
        arr && arr.count > 0) {
        for (int i = 0 ; i < arr.count ;  i++) {
            NSDictionary *value = arr[i];
            if (value && [value isKindOfClass:[NSDictionary class]]) {
                NSString *hKey = [NSString stringWithFormat:@"%@[%d]",key,i];
                [value enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull ekey, id  _Nonnull obj, BOOL * _Nonnull stop) {
                    NSString *mKey = [NSString stringWithFormat:@"%@/%@",hKey,ekey];
                    if ([obj isKindOfClass:[NSArray class]]) {
                        NSDictionary *subDict = [IGHTTPTools translateArrayParameter:obj byKey:mKey];
                        [dict setValuesForKeysWithDictionary:subDict];
                    }else{
                        [dict setObject:obj forKey:mKey];
                    }
                }];
            }
        }
    }
    
    return dict;
}



@end

@implementation IGHTTPTools (IGHTTPSessionTaskBlockHelper)

#pragma mark - ----> 输出

+ (void)logFailureWithTask:(NSURLSessionTask*)task error:(NSString*)error{
#if DEBUG
    NSLog(@"\n\nrequest network fail:\nURL: %@\nerror: %@",task?[task.originalRequest.URL absoluteString]:@"No Found Task",error);
#endif
}

+ (void)logSuccessWithTask:(NSURLSessionTask*)task{

#if DEBUG
    NSString *respString = IGHTTPToolShowRespObjectInBlock && task && [task ig_responseString] ? [task ig_responseString] : @"";
    NSLog(@"\n••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••\nrequest network success: \nURL: %@\nresponseString: \n%@\n\n\n",task ?[task.originalRequest.URL absoluteString]:@"No Found",IGHTTPToolShowRespObjectInBlock?respString:@"No Need");
#endif
}

#pragma mark - 失败时调用的block
+ (IGHTTPSessionTaskFailureBlock)defaultTaskFailureBlock{
    return ^(NSURLSessionTask *task, NSError *error){
        [IGHTTPTools logFailureWithTask:task error:error.localizedDescription];
    };
}

+ (IGHTTPSessionTaskFailureBlock)taskFailureBlockWithVoidBlock:(RespVoidBlock)bBlock{
    return ^(NSURLSessionTask *task, NSError *error){
        [IGHTTPTools logFailureWithTask:task error:error.localizedDescription];
        if (bBlock) bBlock();
    };
}

+ (IGHTTPSessionTaskFailureBlock)taskFailureBlockWithStringBlock:(RespStringBlock)bBlock{
    return ^(NSURLSessionTask *task, NSError *error){
        [IGHTTPTools logFailureWithTask:task error:error.localizedDescription];
        if (bBlock) bBlock(nil,error);
    };
}

+ (IGHTTPSessionTaskFailureBlock)taskFailureBlockWithBoolBlock:(RespBoolBlock)bBlock{
    return ^(NSURLSessionTask *task, NSError *error){
        [IGHTTPTools logFailureWithTask:task error:error.localizedDescription];
        if (bBlock) bBlock(NO,error);
    };
}

+ (IGHTTPSessionTaskFailureBlock)taskFailureBlockWithModelBlock:(RespModelBlock)bBlock{
    return ^(NSURLSessionTask *task, NSError *error){
        [IGHTTPTools logFailureWithTask:task error:error.localizedDescription];
        if (bBlock) bBlock(nil,error);
    };
}

+ (IGHTTPSessionTaskFailureBlock)taskFailureBlockWithArrayBlock:(RespArrayBlock)bBlock{
    return ^(NSURLSessionTask *task, NSError *error){
        [IGHTTPTools logFailureWithTask:task error:error.localizedDescription];
        if (bBlock) bBlock(nil,error);
    };
}

+ (IGHTTPSessionTaskFailureBlock)taskFailureBlockWithDictionaryBlock:(RespDictionaryBlock)bBlock{
    return ^(NSURLSessionTask *task, NSError *error){
        [IGHTTPTools logFailureWithTask:task error:error.localizedDescription];
        if (bBlock) bBlock(nil,error);
    };
}


#pragma mark - 成功
// 成功部分
+ (IGHTTPSessionTaskSuccessBlock)defaultTaskSuccessBlock{
    return ^(NSURLSessionTask *task, id responseObject){
        [IGHTTPTools logSuccessWithTask:task];
    };
}

+ (IGHTTPSessionTaskSuccessBlock)taskSuccessBlockWithVoidBlock:(RespVoidBlock)bBlock{
    return ^(NSURLSessionTask *task, id responseObject){
        [IGHTTPTools logSuccessWithTask:task];
        if (bBlock) bBlock();
    };
}

+ (IGHTTPSessionTaskSuccessBlock)taskSuccessBlockWithStringBlock:(RespStringBlock)bBlock{
    return ^(NSURLSessionTask *task, id responseObject){
        [IGHTTPTools logSuccessWithTask:task];
        if (responseObject && [responseObject isKindOfClass:[NSString class]]) {
            if (bBlock) bBlock(responseObject,nil);
        }else{
            if (bBlock) bBlock(nil, [NSError cannotAnalysisDataError]);
        }
    };
}

+ (IGHTTPSessionTaskSuccessBlock)taskSuccessBlockWithBoolBlock:(RespBoolBlock)bBlock{
    return ^(NSURLSessionTask *task, id responseObject){
        [IGHTTPTools logSuccessWithTask:task];
        if (bBlock) bBlock(YES,nil);
    };
}

+ (IGHTTPSessionTaskSuccessBlock)taskSuccessBlockWithModelBlock:(RespModelBlock)bBlock targetClass:(Class)tClass{
    return ^(NSURLSessionTask *task, id responseObject){
        [IGHTTPTools logSuccessWithTask:task];
        if (responseObject && [responseObject isKindOfClass:[NSDictionary class]]) {
            id model = nil;
            if (tClass) {
                model = [MTLJSONAdapter modelOfClass:tClass fromJSONDictionary:responseObject error:nil];
            }
            if (bBlock) bBlock(model,model?nil:[NSError cannotAnalysisDataError]);
        }else{
            if (bBlock) bBlock(nil, [NSError cannotAnalysisDataError]);
        }
    };
}

+ (IGHTTPSessionTaskSuccessBlock)taskSuccessBlockWithArrayBlock:(RespArrayBlock)bBlock targetClass:(Class)tClass{
    return ^(NSURLSessionTask *task, id responseObject){
        [IGHTTPTools logSuccessWithTask:task];
        if (responseObject && [responseObject isKindOfClass:[NSArray class]]) {
            if (tClass) {
                NSMutableArray *models = (NSMutableArray*)[MTLJSONAdapter modelsOfClass:tClass
                                                                          fromJSONArray:responseObject
                                                                                  error:nil];
                
                if (bBlock) bBlock(models,models?nil:[NSError cannotAnalysisDataError]);
            }else{
                if (bBlock) bBlock(responseObject,nil);
            }
        }else{
            if (bBlock) bBlock(nil, [NSError cannotAnalysisDataError]);
        }
    };
}

+ (IGHTTPSessionTaskSuccessBlock)taskSuccessBlockWithDictionaryBlock:(RespDictionaryBlock)bBlock{
    return ^(NSURLSessionTask *task, id responseObject){
        [IGHTTPTools logSuccessWithTask:task];
        if (responseObject) {
            if ([responseObject isKindOfClass:[NSMutableDictionary class]]) {
                if (bBlock) bBlock(responseObject,nil);
            }else if ([responseObject isKindOfClass:[NSDictionary class]]) {
                if (bBlock) bBlock([responseObject mutableCopy],nil);
            }
        }else{
            if (bBlock) bBlock(nil, [NSError cannotAnalysisDataError]);
        }
    };
}
@end



@implementation IGHTTPTools (IGBatchTask)

+ (IGHTTPSessionTaskSuccessBlock)batchTaskBindWithSuccessBlock:(IGHTTPSessionTaskSuccessBlock)bBlock{
    return ^(NSURLSessionTask *task, id responseObject){
        if (bBlock) bBlock(task, responseObject);
        if (task && [task ig_batchTaskSupport]) {
            id support = [task ig_batchTaskSupport];
            if ([support conformsToProtocol:@protocol(IGBatchTaskSupport)] &&
                [support respondsToSelector:@selector(batchTaskDidFinishTask:result:)]) {
                [support batchTaskDidFinishTask:task result:YES];
            }
        }
    };
}
+ (IGHTTPSessionTaskFailureBlock)batchTaskBindWithFailureBlock:(IGHTTPSessionTaskFailureBlock)bBlock{
    return ^(NSURLSessionTask *task, NSError *error){
        if (bBlock) bBlock(task, error);
        if (task && [task ig_batchTaskSupport]) {
            id support = [task ig_batchTaskSupport];
            if ([support conformsToProtocol:@protocol(IGBatchTaskSupport)] &&
                [support respondsToSelector:@selector(batchTaskDidFinishTask:result:)]) {
                [support batchTaskDidFinishTask:task result:NO];
            }
        }
    };
}


@end
