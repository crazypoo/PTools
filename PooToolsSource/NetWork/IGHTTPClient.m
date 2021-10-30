//
//  IGHTTPClient.m
//  IGHTTPClient
//
//  Created by GavinHe on 16/4/19.
//  Copyright © 2016年 GavinHe. All rights reserved.
//

#import "IGHTTPClient.h"
#import "IGHTTPRequestSerializer.h"
#import "IGJSONResponseSerializer.h"

static NSString * const FrameWorkServerAddress = @"123.207.91.208:80";

@implementation IGHTTPClient

+ (instancetype)sharedClient:(NSString *)serverStr https:(BOOL)https
{
    static IGHTTPClient *_sharedClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *address  = [NSString stringWithFormat:@"%@://%@",https ? @"https" : @"http", serverStr ? serverStr : FrameWorkServerAddress];
        _sharedClient = [[IGHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:address]];
    });
    
    return _sharedClient;
}

- (instancetype)initWithBaseURL:(NSURL *)url {
    self = [super initWithBaseURL:url];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup{
    self.requestSerializer  = [IGHTTPRequestSerializer serializer];
    self.responseSerializer = [IGJSONResponseSerializer serializer];
    
    self.operationQueue.maxConcurrentOperationCount = 3;
    
}

#pragma mark - 工具部分
// 生成完整的请求URL
- (NSString*)requestURLWithAPI:(NSString*)api{
    NSString *reqURLString = [[NSURL URLWithString:api
                                     relativeToURL:self.baseURL]
                              absoluteString];
    return reqURLString;
}

#pragma mark - ----> 发起请求

- (NSURLSessionTask *)taskWithHTTPMethod:(NSString *)method
                                 fullAPI:(NSString *)URLString
                              parameters:(id)parameters
                                 timeout:(NSInteger)timeout
                             isAutoStart:(BOOL)autoStart
                              builderKey:(NSString*)builderKey
                               parserKey:(NSString*)parserKey
                          uploadProgress:(void (^)(NSProgress *uploadProgress)) uploadProgress
                        downloadProgress:(void (^)(NSProgress *downloadProgress)) downloadProgress
                                 success:(IGHTTPSessionTaskSuccessBlock)success
                                 failure:(IGHTTPSessionTaskFailureBlock)failure
{
    NSError *serializationError = nil;
    // 生成请求
    NSMutableURLRequest *request = [(IGHTTPRequestSerializer*)self.requestSerializer
                                    requestWithMethod:method?method:IGHTTPRequestMethodPOST
                                    URLString:URLString
                                    parameters:parameters
                                    builderKey:builderKey
                                    error:&serializationError];
    
    // 超时设置
    [request setTimeoutInterval:MAX(timeout, IGHTTPRequestTimeoutDefault)];

#if DEBUG
    NSLog(@"\n\n‡‡‡‡‡‡‡‡‡‡‡‡‡‡‡‡‡‡‡‡‡‡‡‡‡‡‡‡‡‡‡‡‡‡‡‡‡‡‡‡‡‡‡‡‡‡‡‡‡‡‡‡‡‡‡‡‡‡‡‡‡‡‡‡‡‡‡‡‡‡‡‡‡‡‡‡‡‡‡‡‡‡‡‡\nCreate Request:\nURL: %@\nBuilderKey: %@\nParserKey: %@\nParma: \n%@\n\n\n",request.URL.absoluteString,builderKey,parserKey,parameters);
#endif


    
    if (serializationError) {
        if (failure) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wgnu"
            dispatch_async(self.completionQueue ?: dispatch_get_main_queue(), ^{
                failure(nil, serializationError);
            });
#pragma clang diagnostic pop
        }
        
        return nil;
    }
    
    IGHTTPSessionTaskSuccessBlock batchSuccess = [IGRespBlockGenerator batchTaskBindWithSuccessBlock:success];
    IGHTTPSessionTaskFailureBlock batchFailure = [IGRespBlockGenerator batchTaskBindWithFailureBlock:failure];
    
    __block NSURLSessionDataTask *dataTask = nil;
    __weak typeof(self) weakSelf = self;
    dataTask = [self dataTaskWithRequest:request
                          uploadProgress:uploadProgress
                        downloadProgress:downloadProgress
                       completionHandler:^(NSURLResponse * __unused response, id responseObject, NSError *error) {
                           if (error) {
                               if (batchFailure) {
                                   batchFailure(dataTask, error);
                               }
                           } else {
                               id obj = responseObject;
                               NSError *parserError = nil;
                               if (responseObject &&
                                   weakSelf &&
                                   weakSelf.responseSerializer &&
                                   [weakSelf.responseSerializer isKindOfClass:[IGJSONResponseSerializer class]]
                                   ) {
                                   obj = [(IGJSONResponseSerializer*)weakSelf.responseSerializer responseObjectForResponse:response data:responseObject task:dataTask error:&parserError];
                               }
                               if (parserError) {
                                   if (batchFailure) {
                                       batchFailure(dataTask, parserError);
                                   }
                               }else{
                                   if (batchSuccess) {
                                       batchSuccess(dataTask, obj);
                                   }
                               }
                           }
                       }];
    
    [dataTask ig_setParserKey:parserKey];
    
    if (autoStart) {
        [dataTask resume];
    }
    
    return dataTask;
}


- (NSURLSessionTask *)taskWithHTTPMethod:(NSString *)method
                                     api:(NSString *)api
                              parameters:(id)parameters
                                 timeout:(NSInteger)timeout
                             isAutoStart:(BOOL)autoStart
                              builderKey:(NSString*)builderKey
                               parserKey:(NSString*)parserKey
                          uploadProgress:(void (^)(NSProgress *uploadProgress)) uploadProgress
                        downloadProgress:(void (^)(NSProgress *downloadProgress)) downloadProgress
                                 success:(IGHTTPSessionTaskSuccessBlock)success
                                 failure:(IGHTTPSessionTaskFailureBlock)failure{
    return [self taskWithHTTPMethod:method fullAPI:[self requestURLWithAPI:api] parameters:parameters timeout:timeout isAutoStart:autoStart builderKey:builderKey parserKey:parserKey uploadProgress:uploadProgress downloadProgress:downloadProgress success:success failure:failure];
}

#pragma mark - ⬇️⬇️⬇️⬇️⬇️ 以下为方法重载 ⬇️⬇️⬇️⬇️⬇️

- (NSURLSessionTask *)taskWithHTTPMethod:(NSString *)method
                                     api:(NSString *)api
                              parameters:(id)parameters
                                 success:(IGHTTPSessionTaskSuccessBlock)success
                                 failure:(IGHTTPSessionTaskFailureBlock)failure{
    return [self taskWithHTTPMethod:method fullAPI:[self requestURLWithAPI:api] parameters:parameters timeout:IGHTTPRequestTimeoutDefault isAutoStart:YES builderKey:nil parserKey:nil uploadProgress:nil downloadProgress:nil success:success failure:failure];
}

- (NSURLSessionTask *)taskWithHTTPMethod:(NSString *)method
                                     api:(NSString *)api
                              parameters:(id)parameters
                                 timeout:(NSInteger)timeout
                             isAutoStart:(BOOL)autoStart
                                 success:(IGHTTPSessionTaskSuccessBlock)success
                                 failure:(IGHTTPSessionTaskFailureBlock)failure{
    return [self taskWithHTTPMethod:method fullAPI:[self requestURLWithAPI:api] parameters:parameters timeout:timeout isAutoStart:autoStart builderKey:nil parserKey:nil uploadProgress:nil downloadProgress:nil success:success failure:failure];
}

- (NSURLSessionTask *)taskWithHTTPMethod:(NSString *)method
                                     api:(NSString *)api
                              parameters:(id)parameters
                              builderKey:(NSString*)builderKey
                               parserKey:(NSString*)parserKey
                                 success:(IGHTTPSessionTaskSuccessBlock)success
                                 failure:(IGHTTPSessionTaskFailureBlock)failure{
    return [self taskWithHTTPMethod:method fullAPI:[self requestURLWithAPI:api] parameters:parameters timeout:IGHTTPRequestTimeoutDefault isAutoStart:YES builderKey:builderKey parserKey:parserKey uploadProgress:nil downloadProgress:nil success:success failure:failure];
}

- (NSURLSessionTask *)taskWithHTTPMethod:(NSString *)method
                                     api:(NSString *)api
                              parameters:(id)parameters
                                 timeout:(NSInteger)timeout
                             isAutoStart:(BOOL)autoStart
                              builderKey:(NSString*)builderKey
                               parserKey:(NSString*)parserKey
                                 success:(IGHTTPSessionTaskSuccessBlock)success
                                 failure:(IGHTTPSessionTaskFailureBlock)failure{
    return [self taskWithHTTPMethod:method fullAPI:[self requestURLWithAPI:api] parameters:parameters timeout:timeout isAutoStart:autoStart builderKey:builderKey parserKey:parserKey uploadProgress:nil downloadProgress:nil success:success failure:failure];
    
}


#pragma mark - ----> GET

- (NSURLSessionTask *)GETApi:(NSString *)api
                  parameters:(id)parameters
                     success:(IGHTTPSessionTaskSuccessBlock)success
                     failure:(IGHTTPSessionTaskFailureBlock)failure{
    return [self taskWithHTTPMethod:(NSString*)IGHTTPRequestMethodGET
                                api:api
                         parameters:parameters
                            timeout:IGHTTPRequestTimeoutDefault
                        isAutoStart:YES
                         builderKey:nil
                          parserKey:nil
                            success:success
                            failure:failure];
}

- (NSURLSessionTask *)GETApi:(NSString *)api
                  parameters:(id)parameters
                 isAutoStart:(BOOL)autoStart
                     success:(IGHTTPSessionTaskSuccessBlock)success
                     failure:(IGHTTPSessionTaskFailureBlock)failure{
    return [self taskWithHTTPMethod:(NSString*)IGHTTPRequestMethodGET
                                api:api
                         parameters:parameters
                            timeout:IGHTTPRequestTimeoutDefault
                        isAutoStart:autoStart
                         builderKey:nil
                          parserKey:nil
                            success:success
                            failure:failure];
}



- (NSURLSessionTask *)GETApi:(NSString *)api
                  parameters:(id)parameters
                     timeout:(NSInteger)timeout
                     success:(IGHTTPSessionTaskSuccessBlock)success
                     failure:(IGHTTPSessionTaskFailureBlock)failure{
    return [self taskWithHTTPMethod:(NSString*)IGHTTPRequestMethodGET
                                api:api
                         parameters:parameters
                            timeout:timeout
                        isAutoStart:YES
                         builderKey:nil
                          parserKey:nil
                            success:success
                            failure:failure];
}


- (NSURLSessionTask *)GETApi:(NSString *)api
                  parameters:(id)parameters
                     timeout:(NSInteger)timeout
                 isAutoStart:(BOOL)autoStart
                     success:(IGHTTPSessionTaskSuccessBlock)success
                     failure:(IGHTTPSessionTaskFailureBlock)failure{
    return [self taskWithHTTPMethod:(NSString*)IGHTTPRequestMethodGET
                                api:api
                         parameters:parameters
                            timeout:timeout
                        isAutoStart:autoStart
                         builderKey:nil
                          parserKey:nil
                            success:success
                            failure:failure];
}



- (NSURLSessionTask *)GETApi:(NSString *)api
                  parameters:(id)parameters
                  builderKey:(NSString*)builderKey
                   parserKey:(NSString*)parserKey
                     success:(IGHTTPSessionTaskSuccessBlock)success
                     failure:(IGHTTPSessionTaskFailureBlock)failure{
    return [self taskWithHTTPMethod:(NSString*)IGHTTPRequestMethodGET
                                api:api
                         parameters:parameters
                            timeout:IGHTTPRequestTimeoutDefault
                        isAutoStart:YES
                         builderKey:builderKey
                          parserKey:parserKey
                            success:success
                            failure:failure];
}


- (NSURLSessionTask *)GETApi:(NSString *)api
                  parameters:(id)parameters
                     timeout:(NSInteger)timeout
                 isAutoStart:(BOOL)autoStart
                  builderKey:(NSString*)builderKey
                   parserKey:(NSString*)parserKey
                     success:(IGHTTPSessionTaskSuccessBlock)success
                     failure:(IGHTTPSessionTaskFailureBlock)failure{
    return [self taskWithHTTPMethod:(NSString*)IGHTTPRequestMethodGET
                                api:api
                         parameters:parameters
                            timeout:timeout
                        isAutoStart:autoStart
                         builderKey:parserKey
                          parserKey:builderKey
                            success:success
                            failure:failure];
}



#pragma mark - ------------> Parser部分

- (NSURLSessionTask *)GETApi:(NSString *)api
                  parameters:(id)parameters
                   parserKey:(NSString*)parserKey
                     success:(IGHTTPSessionTaskSuccessBlock)success
                     failure:(IGHTTPSessionTaskFailureBlock)failure{
    return [self taskWithHTTPMethod:(NSString*)IGHTTPRequestMethodGET
                                api:api
                         parameters:parameters
                            timeout:IGHTTPRequestTimeoutDefault
                        isAutoStart:YES
                         builderKey:nil
                          parserKey:parserKey
                            success:success
                            failure:failure];
}



- (NSURLSessionTask *)GETApi:(NSString *)api
                  parameters:(id)parameters
                     timeout:(NSInteger)timeout
                   parserKey:(NSString*)parserKey
                     success:(IGHTTPSessionTaskSuccessBlock)success
                     failure:(IGHTTPSessionTaskFailureBlock)failure{
    return [self taskWithHTTPMethod:(NSString*)IGHTTPRequestMethodGET
                                api:api
                         parameters:parameters
                            timeout:timeout
                        isAutoStart:YES
                         builderKey:nil
                          parserKey:parserKey
                            success:success
                            failure:failure];
}



#pragma mark - ------------> Builder部分

- (NSURLSessionTask *)GETApi:(NSString *)api
                  parameters:(id)parameters
                  builderKey:(NSString*)builderKey
                     success:(IGHTTPSessionTaskSuccessBlock)success
                     failure:(IGHTTPSessionTaskFailureBlock)failure{
    return [self taskWithHTTPMethod:(NSString*)IGHTTPRequestMethodGET
                                api:api
                         parameters:parameters
                            timeout:IGHTTPRequestTimeoutDefault
                        isAutoStart:YES
                         builderKey:builderKey
                          parserKey:nil
                            success:success
                            failure:failure];
}



- (NSURLSessionTask *)GETApi:(NSString *)api
                  parameters:(id)parameters
                     timeout:(NSInteger)timeout
                  builderKey:(NSString*)builderKey
                     success:(IGHTTPSessionTaskSuccessBlock)success
                     failure:(IGHTTPSessionTaskFailureBlock)failure{
    return [self taskWithHTTPMethod:(NSString*)IGHTTPRequestMethodGET
                                api:api
                         parameters:parameters
                            timeout:timeout
                        isAutoStart:YES
                         builderKey:builderKey
                          parserKey:nil
                            success:success
                            failure:failure];
}



#pragma mark - ----> POST

- (NSURLSessionTask *)POSTApi:(NSString *)api
                   parameters:(id)parameters
                      success:(IGHTTPSessionTaskSuccessBlock)success
                      failure:(IGHTTPSessionTaskFailureBlock)failure{
    return [self taskWithHTTPMethod:(NSString*)IGHTTPRequestMethodPOST
                                api:api
                         parameters:parameters
                            timeout:IGHTTPRequestTimeoutDefault
                        isAutoStart:YES
                         builderKey:nil
                          parserKey:nil
                            success:success
                            failure:failure];
}

- (NSURLSessionTask *)POSTApi:(NSString *)api
                   parameters:(id)parameters
                  isAutoStart:(BOOL)autoStart
                      success:(IGHTTPSessionTaskSuccessBlock)success
                      failure:(IGHTTPSessionTaskFailureBlock)failure{
    return [self taskWithHTTPMethod:(NSString*)IGHTTPRequestMethodPOST
                                api:api
                         parameters:parameters
                            timeout:IGHTTPRequestTimeoutDefault
                        isAutoStart:autoStart
                         builderKey:nil
                          parserKey:nil
                            success:success
                            failure:failure];
}



- (NSURLSessionTask *)POSTApi:(NSString *)api
                   parameters:(id)parameters
                      timeout:(NSInteger)timeout
                      success:(IGHTTPSessionTaskSuccessBlock)success
                      failure:(IGHTTPSessionTaskFailureBlock)failure{
    return [self taskWithHTTPMethod:(NSString*)IGHTTPRequestMethodPOST
                                api:api
                         parameters:parameters
                            timeout:timeout
                        isAutoStart:YES
                         builderKey:nil
                          parserKey:nil
                            success:success
                            failure:failure];
}


- (NSURLSessionTask *)POSTApi:(NSString *)api
                   parameters:(id)parameters
                      timeout:(NSInteger)timeout
                  isAutoStart:(BOOL)autoStart
                      success:(IGHTTPSessionTaskSuccessBlock)success
                      failure:(IGHTTPSessionTaskFailureBlock)failure{
    return [self taskWithHTTPMethod:(NSString*)IGHTTPRequestMethodPOST
                                api:api
                         parameters:parameters
                            timeout:timeout
                        isAutoStart:autoStart
                         builderKey:nil
                          parserKey:nil
                            success:success
                            failure:failure];
}



- (NSURLSessionTask *)POSTApi:(NSString *)api
                   parameters:(id)parameters
                   builderKey:(NSString*)builderKey
                    parserKey:(NSString*)parserKey
                      success:(IGHTTPSessionTaskSuccessBlock)success
                      failure:(IGHTTPSessionTaskFailureBlock)failure{
    return [self taskWithHTTPMethod:(NSString*)IGHTTPRequestMethodPOST
                                api:api
                         parameters:parameters
                            timeout:IGHTTPRequestTimeoutDefault
                        isAutoStart:YES
                         builderKey:builderKey
                          parserKey:parserKey
                            success:success
                            failure:failure];
}


- (NSURLSessionTask *)POSTApi:(NSString *)api
                   parameters:(id)parameters
                      timeout:(NSInteger)timeout
                  isAutoStart:(BOOL)autoStart
                   builderKey:(NSString*)builderKey
                    parserKey:(NSString*)parserKey
                      success:(IGHTTPSessionTaskSuccessBlock)success
                      failure:(IGHTTPSessionTaskFailureBlock)failure{
    return [self taskWithHTTPMethod:(NSString*)IGHTTPRequestMethodPOST
                                api:api
                         parameters:parameters
                            timeout:timeout
                        isAutoStart:autoStart
                         builderKey:parserKey
                          parserKey:builderKey
                            success:success
                            failure:failure];
}



#pragma mark - ------------> Parser部分

- (NSURLSessionTask *)POSTApi:(NSString *)api
                   parameters:(id)parameters
                    parserKey:(NSString*)parserKey
                      success:(IGHTTPSessionTaskSuccessBlock)success
                      failure:(IGHTTPSessionTaskFailureBlock)failure{
    return [self taskWithHTTPMethod:(NSString*)IGHTTPRequestMethodPOST
                                api:api
                         parameters:parameters
                            timeout:IGHTTPRequestTimeoutDefault
                        isAutoStart:YES
                         builderKey:nil
                          parserKey:parserKey
                            success:success
                            failure:failure];
}



- (NSURLSessionTask *)POSTApi:(NSString *)api
                   parameters:(id)parameters
                      timeout:(NSInteger)timeout
                    parserKey:(NSString*)parserKey
                      success:(IGHTTPSessionTaskSuccessBlock)success
                      failure:(IGHTTPSessionTaskFailureBlock)failure{
    return [self taskWithHTTPMethod:(NSString*)IGHTTPRequestMethodPOST
                                api:api
                         parameters:parameters
                            timeout:timeout
                        isAutoStart:YES
                         builderKey:nil
                          parserKey:parserKey
                            success:success
                            failure:failure];
}



#pragma mark - ------------> Builder部分

- (NSURLSessionTask *)POSTApi:(NSString *)api
                   parameters:(id)parameters
                   builderKey:(NSString*)builderKey
                      success:(IGHTTPSessionTaskSuccessBlock)success
                      failure:(IGHTTPSessionTaskFailureBlock)failure{
    return [self taskWithHTTPMethod:(NSString*)IGHTTPRequestMethodPOST
                                api:api
                         parameters:parameters
                            timeout:IGHTTPRequestTimeoutDefault
                        isAutoStart:YES
                         builderKey:builderKey
                          parserKey:nil
                            success:success
                            failure:failure];
}



- (NSURLSessionTask *)POSTApi:(NSString *)api
                   parameters:(id)parameters
                      timeout:(NSInteger)timeout
                   builderKey:(NSString*)builderKey
                      success:(IGHTTPSessionTaskSuccessBlock)success
                      failure:(IGHTTPSessionTaskFailureBlock)failure{
    return [self taskWithHTTPMethod:(NSString*)IGHTTPRequestMethodPOST
                                api:api
                         parameters:parameters
                            timeout:timeout
                        isAutoStart:YES
                         builderKey:builderKey
                          parserKey:nil
                            success:success
                            failure:failure];
}
@end
