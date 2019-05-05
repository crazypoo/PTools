//
//  IGJSONResponseObjectParserManager.m
//  IGWPT
//
//  Created by GavinHe on 16/2/19.
//
//

#import "IGJSONResponseObjectParserManager.h"

@interface IGJSONResponseObjectParserManager (){
    
}
@property (nonatomic,strong) NSMutableDictionary *parserDict;

@end

@implementation IGJSONResponseObjectParserManager

+(instancetype)defaultManager
{
    static id _sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[IGJSONResponseObjectParserManager alloc] init];
        
    });
    return _sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup{
    _parserDict = [NSMutableDictionary new];
}

- (IGJSONResponseObjectParserRegistResult)registParser:(id<IGJSONResponseObjectParser>)parser forKey:(NSString*)key{
    if (!parser || ![parser respondsToSelector:@selector(parseResponseObject:error:)]) {
        return IGJSONResponseObjectParserRegistResultIsNotParser;
    }
    if (!key || ![key isKindOfClass:[NSString class]] || key.length == 0) {
        return IGJSONResponseObjectParserRegistResultWrongKey;
    }
    
    if ([[self.parserDict allKeys] containsObject:key]) {
        return IGJSONResponseObjectParserRegistResultExisted;
    }
    
    [self.parserDict setObject:parser forKey:key];
    
    return IGJSONResponseObjectParserRegistResultSuccess;
}

- (void)unregisterParserWithKey:(NSString*)key{
    if (key && [key isKindOfClass:[NSString class]]) {
        [self.parserDict removeObjectForKey:key];
    }
}

- (id<IGJSONResponseObjectParser>)parserWithKey:(NSString*)key{
    if (key && [key isKindOfClass:[NSString class]]) {
        return [self.parserDict objectForKey:key];
    }
    return nil;
}


#pragma mark - ----> Access Method

- (NSMutableDictionary *)parserDict{
    @synchronized(self){
        return _parserDict;
    }
}


@end
