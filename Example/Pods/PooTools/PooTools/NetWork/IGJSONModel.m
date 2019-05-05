//
//  SIEJSONModel.m
//  SIEWPT
//
//  Created by GavinHe on 16/1/13.
//
//

#import "IGJSONModel.h"

@implementation IGJSONModel

//mantel中对于无符号的类型，尚未做类型匹配，如果在model中定义无符号类型，会导致转换为字符串类型，导致crash，因此需要注意，必要的时候可以考虑重写mantel的类型匹配

- (instancetype)initWithDictionary:(NSDictionary *)dictionaryValue error:(NSError **)error {
    self = [super initWithDictionary:dictionaryValue error:error];
    return self;
}

- (id)transModelToDictionary
{
    NSError *error = nil;
    id obj = [MTLJSONAdapter JSONDictionaryFromModel:self error:&error];
    if (error) {
        NSLog(@"%@ transModelToDictionary Fail :  %@",[self class],error);
    }
    return obj;
}


#pragma mark - MTLJSONSerializing Delegate Method
/*The dictionary returned by this method specifies how your model object's properties map to the keys in the JSON representation. Properties that map to NSNull will not be present in the JSON representation
 */
+ (NSDictionary *)JSONKeyPathsByPropertyKey{
    // 获取Model所有属性的映射关系
    NSMutableDictionary *keys = [self DeafultJSONKeyPathsByPropertyKey];
    // 获取自定义的映射关系
    NSDictionary *customKeys = [self CustomJSONKeyPathsByPropertyKey];
    // 用自定义的映射关系覆盖默认的
    if (customKeys) {
        for (NSString *key in [customKeys allKeys]) {
            [keys setObject:customKeys[key] forKey:key];
        }
    }
    
    // 返回映射关系
    return keys;
}

// 需要重写
+ (NSDictionary*)CustomJSONKeyPathsByPropertyKey{
    return @{};
}

+ (NSMutableDictionary*)DeafultJSONKeyPathsByPropertyKey{
    NSMutableDictionary *tempDict = [[NSMutableDictionary alloc] init];
    
    NSSet *allPropertyKeys = [self propertyKeys];
    
    if (allPropertyKeys && allPropertyKeys.count > 0)
        [allPropertyKeys enumerateObjectsUsingBlock:^(id  _Nonnull obj, BOOL * _Nonnull stop) {
            if (obj && [obj isKindOfClass:[NSString class]]) {
                [tempDict setObject:obj forKey:obj];
            }
        }];
    
    return tempDict;
}

#pragma mark - KVC method

/**
 *  有的时候API的response会有空值，比如pubilshTime可能不是每次都有的，JSON是这样儿的：
 *  {
 *      "pubilshTime": null
 *  }
 *  Mantle在这种情况会将pubilshTime转换为nil，但如果是标量如NSInteger怎么办？KVC会直接raise NSInvalidArgumentException。
 *  所以重写kvc的setNilValueForKey方法，设置为0
 */
- (void)setNilValueForKey:(NSString *)key
{
    [self setValue:@0 forKey:key]; // For NSInteger/CGFloat/BOOL
}

/**
 *  有时候服务器会把『id』作为key，而objc里的id是保留字，所以如果处理服务器有返回id字段的数据时重写这个方法或者在JSONKeyPathsByPropertyKey代理里设好id的映射字段
 *
 */
-(void)setId:(id)aid{
}

@end
