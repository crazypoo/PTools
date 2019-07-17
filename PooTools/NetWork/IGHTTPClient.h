//
//  IGHTTPClient.h
//  IGHTTPClient
//
//  Created by GavinHe on 16/4/19.
//  Copyright © 2016年 GavinHe. All rights reserved.
//

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdocumentation"

#import <AFNetworking/AFNetworking.h>

#import "NSError+HTTPClient.h"
#import "NSURLSessionTask+IGHTTPClient.h"

#import "IGHTTPTools.h"
#import "IGHTTPRequestBuilderManager.h"
#import "IGJSONResponseObjectParserManager.h"

#import "IGHTTPClientProfile.h"


#define HTTPClient(s,h) [IGHTTPClient sharedClient:s https:h]

@interface IGHTTPClient : AFHTTPSessionManager

+ (instancetype)sharedClient:(NSString *)serverStr https:(BOOL)https;

/**
 *  创建网络请求任务
 *
 *  @param method           请求方法：GET、POST等
 *  @param fullAPI          完整的请求链接（直接使用不会进行拼接、判断等处理）
 *  @param parameters       参数
 *  @param timeout          超时时间
 *  @param autoStart        是否自动启动任务
 *  @param builderKey       创建特殊要求的Request指定BuilderKey，参考IGHTTPRequestBuilderManager
 *  @param parserKey        对返回的JSON对象进行特殊处理的时候指定ParserKey，参考IGJSONResponseObjectParserManager
 *  @param uploadProgress   上传任务的进度回调
 *  @param downloadProgress 下载任务的进度回调
 *  @param success          任务完成的回调
 *  @param failure          任务失败的回调
 *
 *  @return 网络请求的Task
 */
- (NSURLSessionTask *)taskWithHTTPMethod:(NSString *)method
                                 fullAPI:(NSString *)fullAPI
                              parameters:(id)parameters
                                 timeout:(NSInteger)timeout
                             isAutoStart:(BOOL)autoStart
                              builderKey:(NSString*)builderKey
                               parserKey:(NSString*)parserKey
                          uploadProgress:(void (^)(NSProgress *uploadProgress)) uploadProgress
                        downloadProgress:(void (^)(NSProgress *downloadProgress)) downloadProgress
                                 success:(IGHTTPSessionTaskSuccessBlock)success
                                 failure:(IGHTTPSessionTaskFailureBlock)failure;

/**
 *  创建网络请求任务
 *
 *  @param method           请求方法：GET、POST等
 *  @param fullAPI          请求链接，会拼接在BaseURL之后（不会有效性判断处理）
 *  @param parameters       参数
 *  @param timeout          超时时间
 *  @param autoStart        是否自动启动任务，Default is YES
 *  @param builderKey       创建特殊要求的Request指定BuilderKey，参考IGHTTPRequestBuilderManager
 *  @param parserKey        对返回的JSON对象进行特殊处理的时候指定ParserKey，参考IGJSONResponseObjectParserManager
 *  @param uploadProgress   上传任务的进度回调
 *  @param downloadProgress 下载任务的进度回调
 *  @param success          任务完成的回调
 *  @param failure          任务失败的回调
 *
 *  @return 网络请求的Task
 */

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
                                 failure:(IGHTTPSessionTaskFailureBlock)failure;

#pragma mark - ⬇️⬇️⬇️⬇️⬇️ 以下为方法重载 ⬇️⬇️⬇️⬇️⬇️

- (NSURLSessionTask *)taskWithHTTPMethod:(NSString *)method
                                     api:(NSString *)api
                              parameters:(id)parameters
                                 success:(IGHTTPSessionTaskSuccessBlock)success
                                 failure:(IGHTTPSessionTaskFailureBlock)failure;

- (NSURLSessionTask *)taskWithHTTPMethod:(NSString *)method
                                     api:(NSString *)api
                              parameters:(id)parameters
                                 timeout:(NSInteger)timeout
                             isAutoStart:(BOOL)autoStart
                                 success:(IGHTTPSessionTaskSuccessBlock)success
                                 failure:(IGHTTPSessionTaskFailureBlock)failure;

- (NSURLSessionTask *)taskWithHTTPMethod:(NSString *)method
                                     api:(NSString *)api
                              parameters:(id)parameters
                              builderKey:(NSString*)builderKey
                               parserKey:(NSString*)parserKey
                                 success:(IGHTTPSessionTaskSuccessBlock)success
                                 failure:(IGHTTPSessionTaskFailureBlock)failure;

- (NSURLSessionTask *)taskWithHTTPMethod:(NSString *)method
                                     api:(NSString *)api
                              parameters:(id)parameters
                                 timeout:(NSInteger)timeout
                             isAutoStart:(BOOL)autoStart
                              builderKey:(NSString*)builderKey
                               parserKey:(NSString*)parserKey
                                 success:(IGHTTPSessionTaskSuccessBlock)success
                                 failure:(IGHTTPSessionTaskFailureBlock)failure;


#pragma mark - ----> GET

- (NSURLSessionTask *)GETApi:(NSString *)api
                  parameters:(id)parameters
                     success:(IGHTTPSessionTaskSuccessBlock)success
                     failure:(IGHTTPSessionTaskFailureBlock)failure;

- (NSURLSessionTask *)GETApi:(NSString *)api
                  parameters:(id)parameters
                 isAutoStart:(BOOL)autoStart
                     success:(IGHTTPSessionTaskSuccessBlock)success
                     failure:(IGHTTPSessionTaskFailureBlock)failure;


- (NSURLSessionTask *)GETApi:(NSString *)api
                  parameters:(id)parameters
                     timeout:(NSInteger)timeout
                     success:(IGHTTPSessionTaskSuccessBlock)success
                     failure:(IGHTTPSessionTaskFailureBlock)failure;

- (NSURLSessionTask *)GETApi:(NSString *)api
                  parameters:(id)parameters
                     timeout:(NSInteger)timeout
                 isAutoStart:(BOOL)autoStart
                     success:(IGHTTPSessionTaskSuccessBlock)success
                     failure:(IGHTTPSessionTaskFailureBlock)failure;


- (NSURLSessionTask *)GETApi:(NSString *)api
                  parameters:(id)parameters
                  builderKey:(NSString*)builderKey
                   parserKey:(NSString*)parserKey
                     success:(IGHTTPSessionTaskSuccessBlock)success
                     failure:(IGHTTPSessionTaskFailureBlock)failure;

- (NSURLSessionTask *)GETApi:(NSString *)api
                  parameters:(id)parameters
                     timeout:(NSInteger)timeout
                 isAutoStart:(BOOL)autoStart
                  builderKey:(NSString*)builderKey
                   parserKey:(NSString*)parserKey
                     success:(IGHTTPSessionTaskSuccessBlock)success
                     failure:(IGHTTPSessionTaskFailureBlock)failure;


#pragma mark - ------------> Parser部分

- (NSURLSessionTask *)GETApi:(NSString *)api
                  parameters:(id)parameters
                   parserKey:(NSString*)parserKey
                     success:(IGHTTPSessionTaskSuccessBlock)success
                     failure:(IGHTTPSessionTaskFailureBlock)failure;


- (NSURLSessionTask *)GETApi:(NSString *)api
                  parameters:(id)parameters
                     timeout:(NSInteger)timeout
                   parserKey:(NSString*)parserKey
                     success:(IGHTTPSessionTaskSuccessBlock)success
                     failure:(IGHTTPSessionTaskFailureBlock)failure;


#pragma mark - ------------> Builder部分

- (NSURLSessionTask *)GETApi:(NSString *)api
                  parameters:(id)parameters
                  builderKey:(NSString*)builderKey
                     success:(IGHTTPSessionTaskSuccessBlock)success
                     failure:(IGHTTPSessionTaskFailureBlock)failure;


- (NSURLSessionTask *)GETApi:(NSString *)api
                  parameters:(id)parameters
                     timeout:(NSInteger)timeout
                  builderKey:(NSString*)builderKey
                     success:(IGHTTPSessionTaskSuccessBlock)success
                     failure:(IGHTTPSessionTaskFailureBlock)failure;


#pragma mark - ----> POST

- (NSURLSessionTask *)POSTApi:(NSString *)api
                   parameters:(id)parameters
                      success:(IGHTTPSessionTaskSuccessBlock)success
                      failure:(IGHTTPSessionTaskFailureBlock)failure;

- (NSURLSessionTask *)POSTApi:(NSString *)api
                   parameters:(id)parameters
                  isAutoStart:(BOOL)autoStart
                      success:(IGHTTPSessionTaskSuccessBlock)success
                      failure:(IGHTTPSessionTaskFailureBlock)failure;


- (NSURLSessionTask *)POSTApi:(NSString *)api
                   parameters:(id)parameters
                      timeout:(NSInteger)timeout
                      success:(IGHTTPSessionTaskSuccessBlock)success
                      failure:(IGHTTPSessionTaskFailureBlock)failure;

- (NSURLSessionTask *)POSTApi:(NSString *)api
                   parameters:(id)parameters
                      timeout:(NSInteger)timeout
                  isAutoStart:(BOOL)autoStart
                      success:(IGHTTPSessionTaskSuccessBlock)success
                      failure:(IGHTTPSessionTaskFailureBlock)failure;


- (NSURLSessionTask *)POSTApi:(NSString *)api
                   parameters:(id)parameters
                   builderKey:(NSString*)builderKey
                    parserKey:(NSString*)parserKey
                      success:(IGHTTPSessionTaskSuccessBlock)success
                      failure:(IGHTTPSessionTaskFailureBlock)failure;

- (NSURLSessionTask *)POSTApi:(NSString *)api
                   parameters:(id)parameters
                      timeout:(NSInteger)timeout
                  isAutoStart:(BOOL)autoStart
                   builderKey:(NSString*)builderKey
                    parserKey:(NSString*)parserKey
                      success:(IGHTTPSessionTaskSuccessBlock)success
                      failure:(IGHTTPSessionTaskFailureBlock)failure;


#pragma mark - ------------> Parser部分

- (NSURLSessionTask *)POSTApi:(NSString *)api
                   parameters:(id)parameters
                    parserKey:(NSString*)parserKey
                      success:(IGHTTPSessionTaskSuccessBlock)success
                      failure:(IGHTTPSessionTaskFailureBlock)failure;


- (NSURLSessionTask *)POSTApi:(NSString *)api
                   parameters:(id)parameters
                      timeout:(NSInteger)timeout
                    parserKey:(NSString*)parserKey
                      success:(IGHTTPSessionTaskSuccessBlock)success
                      failure:(IGHTTPSessionTaskFailureBlock)failure;


#pragma mark - ------------> Builder部分

- (NSURLSessionTask *)POSTApi:(NSString *)api
                   parameters:(id)parameters
                   builderKey:(NSString*)builderKey
                      success:(IGHTTPSessionTaskSuccessBlock)success
                      failure:(IGHTTPSessionTaskFailureBlock)failure;


- (NSURLSessionTask *)POSTApi:(NSString *)api
                   parameters:(id)parameters
                      timeout:(NSInteger)timeout
                   builderKey:(NSString*)builderKey
                      success:(IGHTTPSessionTaskSuccessBlock)success
                      failure:(IGHTTPSessionTaskFailureBlock)failure;
@end
#pragma clang diagnostic pop
