//
//  NSError+HTTPClient.h
//  SIEWPT
//
//  Created by GavinHe on 16/1/13.
//
//

#import <Foundation/Foundation.h>

@interface NSError (HTTPClients)

+(NSError*)cannotAnalysisDataError;

+(NSError*)cannotConnectServiceError;

+(NSError*)cannotConnectNetworkError;

+(NSError*)errorWithNetworkErrorInfo:(NSString*)errorInfo;

-(BOOL)isHTTPNetworkError;
-(BOOL)isHTTPResponeError;

@end
