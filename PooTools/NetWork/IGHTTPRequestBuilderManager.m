//
//  IGHTTPRequestBuilderManager.m
//  IGWPT
//
//  Created by GavinHe on 16/4/6.
//
//

#import "IGHTTPRequestBuilderManager.h"

@interface IGHTTPRequestBuilderManager (){
    
}
@property (nonatomic,strong) NSMutableDictionary *builderDict;
@end

@implementation IGHTTPRequestBuilderManager

+(instancetype)defaultManager
{
    static id _sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[IGHTTPRequestBuilderManager alloc] init];
        
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
    _builderDict = [NSMutableDictionary new];
}

- (IGHTTPRequestBuilderRegistResult)registBuilder:(id<IGHTTPRequestBuilder>)builder forKey:(NSString*)key{
    if (!builder || ![builder respondsToSelector:@selector(requestWithMethod:URLString:parameters:error:)]) {
        return IGHTTPRequestBuilderRegistResultIsNotBuilder;
    }
    if (!key || ![key isKindOfClass:[NSString class]] || key.length == 0) {
        return IGHTTPRequestBuilderRegistResultWrongKey;
    }
    
    if ([[self.builderDict allKeys] containsObject:key]) {
        return IGHTTPRequestBuilderRegistResultExisted;
    }
    
    [self.builderDict setObject:builder forKey:key];
    
    return IGHTTPRequestBuilderRegistResultSuccess;
}

- (void)unregisterBuilderWithKey:(NSString*)key{
    if (key && [key isKindOfClass:[NSString class]]) {
        [self.builderDict removeObjectForKey:key];
    }
}

- (id<IGHTTPRequestBuilder>)builderWithKey:(NSString*)key{
    if (key && [key isKindOfClass:[NSString class]]) {
        return [self.builderDict objectForKey:key];
    }
    return nil;
}


#pragma mark - ----> Access Method

- (NSMutableDictionary *)builderDict{
    @synchronized(self){
        return _builderDict;
    }
}



@end
