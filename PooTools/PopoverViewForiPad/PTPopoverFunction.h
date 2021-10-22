//
//  PTPopoverFunction.h
//  PooTools_Example
//
//  Created by liu on 2020/1/8.
//  Copyright © 2020 crazypoo. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^ReturnView)(id _Nonnull popoverView);

NS_ASSUME_NONNULL_BEGIN

@interface PTPopoverFunction : NSObject
+(void)initWithContentViewSize:(CGSize)cSize withContentView:(UIView *)cView withSender:(UIView *)sender withSenderFrame:(CGRect)senderFrame withArrowDirections:(UIPopoverArrowDirection)arrowDirections withPopover:(ReturnView)block;
@end

NS_ASSUME_NONNULL_END
