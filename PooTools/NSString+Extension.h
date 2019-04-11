//
//  NSString+Extension.h
//  PooTools_Example
//
//  Created by 邓杰豪 on 2019/4/11.
//  Copyright © 2019 crazypoo. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger,UTF8StringType){
    UTF8StringTypeOC = 0,
    UTF8StringTypeC
};

NS_ASSUME_NONNULL_BEGIN

@interface NSString (UTF8)
-(NSString *)stringToUTF8String:(UTF8StringType)type;
@end

NS_ASSUME_NONNULL_END
