//
//  NSURLSessionTask+HTTPClient.h
//  IGWPT
//
//  Created by GavinHe on 16/1/27.
//
//

#import <Foundation/Foundation.h>

@interface NSURLSessionTask (IGHTTPClient)

@property (nonatomic,strong,readonly) NSMutableDictionary *IGExtraInfos;

- (id)ig_extraObjectForKey:(NSString*)key;
- (void)ig_setExtraObject:(id)obj forKey:(NSString*)key;


- (NSInteger)ig_tag;
- (void)ig_setTag:(NSInteger)tag;

- (NSString*)ig_parserKey;
- (void)ig_setParserKey:(NSString*)key;

- (BOOL)ig_saveResponseString;
- (void)ig_setSaveResponseString:(BOOL)isSave;

- (NSString*)ig_responseString;
- (void)ig_setResponseString:(NSString*)string;

#pragma mark - ----> Batch
- (id)ig_batchTaskSupport;
- (void)ig_setBatchTaskSupport:(id)obj;


@end
