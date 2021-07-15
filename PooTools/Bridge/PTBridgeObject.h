//
//  PTBridgeObject.h
//  PTBridgeObject
//
//  Created by ken lam on 2021/7/15.
//  Copyright © 2021 crazypoo. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface PTBridgeObject : NSObject
+(BOOL)kStringIsEmpty:(NSString *)str;
+(void)gcdAfter:(double)times handle:(void(^)(void))block;
+(void)viewBorderRadius:(UIView *)someViews withRadius:(CGFloat)radius withWidth:(CGFloat)width withColor:(UIColor *)color;
@end

NS_ASSUME_NONNULL_END
