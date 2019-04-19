//
//  NSError+HTTPClient.m
//  IG
//
//  Created by GavinHe on 16/1/13.
//
//

#import "NSError+HTTPClient.h"
#import "IGHTTPTools.h"

@implementation NSError (HTTPClients)

+(NSError*)cannotAnalysisDataError{
    return [NSError errorWithErrorInfo:@"服务器数据异常"];
}

+(NSError*)cannotConnectServiceError{
    return [NSError errorWithErrorInfo:@"无法连接到服务器"];
}

+(NSError*)cannotConnectNetworkError{
    return [NSError errorWithErrorInfo:@"当前网络连接不可用"];
}

+(NSError*)errorWithNetworkErrorInfo:(NSString*)errorInfo{
    return [NSError errorWithErrorInfo:errorInfo];
}

+(NSError*)errorWithErrorInfo:(NSString*)errorInfo{
    return [[NSError alloc] initWithDomain:(NSString*)IGHTTPNetWorkErrorDomain
                                      code:IGHTTPNetworkErrorCode
                                  userInfo:@{
                                             NSLocalizedDescriptionKey:errorInfo
                                             }];
}

-(BOOL)isHTTPResponeError{
    if ([IGHTTPResponseSerializationErrorDomain isEqualToString:self.domain]) {
        return YES;
    }
    return NO;
}
-(BOOL)isHTTPNetworkError{
    if ([IGHTTPNetWorkErrorDomain isEqualToString:self.domain]) {
        return YES;
    }
    return NO;
}

@end
