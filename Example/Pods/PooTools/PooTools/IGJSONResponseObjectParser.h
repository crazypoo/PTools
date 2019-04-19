//
//  IGJSONResponseObjectParser.h
//  IGWPT
//
//  Created by GavinHe on 16/2/19.
//
//

#import <Foundation/Foundation.h>

@protocol IGJSONResponseObjectParser <NSObject>

@required
/**
 *  处理从服务器返回的JSON解析得到的对象
 *
 *  @param obj   目标对象
 *  @param error Error对象的指针
 *
 *  @return 处理后的对象，如果返回值和Error都为空则代表由默认解析器处理
 */
- (id)parseResponseObject:(id)obj error:(NSError *__autoreleasing *)error;

@end
