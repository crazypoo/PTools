//
//  IGJSONResponseObjectParserManager.h
//  IGWPT
//
//  Created by GavinHe on 16/2/19.
//
//

#import <Foundation/Foundation.h>
#import "IGJSONResponseObjectParser.h"

typedef NS_ENUM(NSInteger, IGJSONResponseObjectParserRegistResult) {
    IGJSONResponseObjectParserRegistResultSuccess = 0,
    IGJSONResponseObjectParserRegistResultExisted ,
    IGJSONResponseObjectParserRegistResultIsNotParser ,
    IGJSONResponseObjectParserRegistResultWrongKey
};

@interface IGJSONResponseObjectParserManager : NSObject

+(instancetype)defaultManager;

- (IGJSONResponseObjectParserRegistResult)registParser:(id<IGJSONResponseObjectParser>)parser forKey:(NSString*)key;

- (void)unregisterParserWithKey:(NSString*)key;

- (id<IGJSONResponseObjectParser>)parserWithKey:(NSString*)key;

@end
