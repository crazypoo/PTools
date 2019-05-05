//
//  IGHTTPSetting.h
//  IGWPT
//
//  Created by GavinHe on 16/1/13.
//
//

#import <Foundation/Foundation.h>

#define IG_NonNullString(str) str?str:@""
#define IG_HTTPErrorInfo(err,place) err?err.localizedDescription:place

// 预设请求方法
const static NSString* IGHTTPRequestMethodGET  = @"GET";
const static NSString* IGHTTPRequestMethodPOST = @"POST";

// 预设超时时间
const static NSInteger IGHTTPRequestTimeoutDefault    = 20;
const static NSInteger IGHTTPRequestTimeoutMinute     = 60;
const static NSInteger IGHTTPRequestTimeoutFiveMinute = 60*5;

// 预设NSError的domain
const static NSString* IGHTTPResponseSerializationErrorDomain = @"com.ig.error.serialization.response";
const static NSString* IGHTTPNetWorkErrorDomain               = @"com.ig.error.serialization.network";
// 预设NSError的Code
const static NSInteger IGHTTPResponseSerializationErrorCode = 888888;
const static NSInteger IGHTTPNetworkErrorCode               = 444444;

// 响应状态
typedef NS_ENUM(NSInteger, IGHTTPResponseStatus) {
    IGHTTPResponseStatusSuccess = 0,   //成功
    IGHTTPResponseStatusFailure = 1,   //失败
};

// 和服务器对应错误码
typedef NS_ENUM(NSInteger, IGHTTPResponseCode) {
    IGHTTPResponseCodeDefault = 0
};

// 用于返回结果的回调方法块
@class IGJSONModel;
typedef void (^RespVoidBlock)(void);
typedef void (^RespStringBlock)(NSString *info, NSError *error);
typedef void (^RespBoolBlock)(BOOL flag, NSError *error);
typedef void (^RespModelBlock)(IGJSONModel *model, NSError *error);
typedef void (^RespArrayBlock)(NSMutableArray *models, NSError *error);
typedef void (^RespDictionaryBlock)(NSMutableDictionary *infoDict, NSError *error);

@class AFHTTPRequestOperation;
@class IGUploadPartitionFileTask;
@class NSURLSessionTask;

// 网络请求Block设定
typedef void (^IGHTTPSessionTaskSuccessBlock)(NSURLSessionTask *task, id responseObject);
typedef void (^IGHTTPSessionTaskFailureBlock)(NSURLSessionTask *task, NSError *error);


#define IGRespBlockGenerator IGHTTPTools

static BOOL IGHTTPToolShowRespObjectInBlock = NO;

@interface IGHTTPTools : NSObject


#pragma mark - 工具
/**
 *  获取服务器错误代码对应的信息
 *
 *  @param code 服务器返回的错误码
 *
 *  @return 对应的描述信息
 */
+(NSString*)errorInfoWithResponseCode:(IGHTTPResponseCode)code;

#pragma mark - ----> 网络图片
/**
 *  返回目标网络图片的缩略图版的URL
 *
 *  @param imageURL 源文件URL
 *
 *  @return 缩略图URL
 */
- (NSString*)thumbnailImageURLWithImageURL:(NSString*)imageURL;

#pragma mark - ----> 参数组装
/**
 *  自动转换参数字典内的所有数组
 *
 *  @param parma 参数字典
 *
 *  @return 处理后的参数字典
 */
+(NSMutableDictionary*)translateArrayInDictionaryParameter:(NSDictionary*)parma;

/**
 *  服务器不支持直接传数组，需要转换格式
 *
 *  @param arr 原数组，内部元素必须为字典
 *  @param key 数组对应的Key
 *
 *  @return 转换后的字典
 */
+(NSMutableDictionary*)translateArrayParameter:(NSArray<NSDictionary*>*)arr byKey:(NSString*)key;

@end

@interface IGHTTPTools (IGHTTPSessionTaskBlockHelper)


// 失败部分
+ (IGHTTPSessionTaskFailureBlock)defaultTaskFailureBlock;

+ (IGHTTPSessionTaskFailureBlock)taskFailureBlockWithVoidBlock:(RespVoidBlock)bBlock;

+ (IGHTTPSessionTaskFailureBlock)taskFailureBlockWithStringBlock:(RespStringBlock)bBlock;

+ (IGHTTPSessionTaskFailureBlock)taskFailureBlockWithBoolBlock:(RespBoolBlock)bBlock;

+ (IGHTTPSessionTaskFailureBlock)taskFailureBlockWithModelBlock:(RespModelBlock)bBlock;

+ (IGHTTPSessionTaskFailureBlock)taskFailureBlockWithArrayBlock:(RespArrayBlock)bBlock;

+ (IGHTTPSessionTaskFailureBlock)taskFailureBlockWithDictionaryBlock:(RespDictionaryBlock)bBlock;


// 成功部分
/**
 *  默认的完成Block，会在控制台输出服务器返回的数据
 *  @return 用于传入HTTPClient请求的Success参数
 */
+ (IGHTTPSessionTaskSuccessBlock)defaultTaskSuccessBlock;

/**
 *  @param bBlock 网络请求完成后调用的block，Block里面应该有处理期望数据的实现
 *  @return 用于传入HTTPClient请求的Success参数
 */
+ (IGHTTPSessionTaskSuccessBlock)taskSuccessBlockWithVoidBlock:(RespVoidBlock)bBlock;

/**
 *  @param bBlock 网络请求完成后调用的block，Block里面应该有处理期望数据的实现
 *  @return 用于传入HTTPClient请求的Success参数
 */
+ (IGHTTPSessionTaskSuccessBlock)taskSuccessBlockWithStringBlock:(RespStringBlock)bBlock;

/**
 *  @param bBlock 网络请求完成后调用的block，Block里面应该有处理期望数据的实现
 *  @return 用于传入HTTPClient请求的Success参数
 */
+ (IGHTTPSessionTaskSuccessBlock)taskSuccessBlockWithBoolBlock:(RespBoolBlock)bBlock;

/**
 *  @param bBlock 网络请求完成后调用的block，Block里面应该有处理期望数据的实现
 *  @param tClass 期望从服务器获取的Model的Class
 *  @return 用于传入HTTPClient请求的Success参数
 */
+ (IGHTTPSessionTaskSuccessBlock)taskSuccessBlockWithModelBlock:(RespModelBlock)bBlock targetClass:(Class)tClass;

/**
 *  @param bBlock 网络请求完成后调用的block，Block里面应该有处理期望数据的实现
 *  @param tClass 期望从服务器获取的Model的Class
 *  @return 用于传入HTTPClient请求的Success参数
 */
+ (IGHTTPSessionTaskSuccessBlock)taskSuccessBlockWithArrayBlock:(RespArrayBlock)bBlock targetClass:(Class)tClass;

/**
 *  @param bBlock 网络请求完成后调用的block，Block里面应该有处理期望数据的实现
 *  @return 用于传入HTTPClient请求的Success参数
 */
+ (IGHTTPSessionTaskSuccessBlock)taskSuccessBlockWithDictionaryBlock:(RespDictionaryBlock)bBlock;


@end

@interface IGHTTPTools (IGBatchTask)

+ (IGHTTPSessionTaskSuccessBlock)batchTaskBindWithSuccessBlock:(IGHTTPSessionTaskSuccessBlock)bBlock;
+ (IGHTTPSessionTaskFailureBlock)batchTaskBindWithFailureBlock:(IGHTTPSessionTaskFailureBlock)bBlock;


@end
