//
//  PooPhoneBlock.h
//  OMCN
//
//  Created by crazypoo on 15-1-20.
//  Copyright (c) 2015年 doudou. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PooPhoneBlock : NSObject

typedef void (^PooCallBlock)(NSTimeInterval duration);
typedef void (^PooCancelBlock)(void);

+ (BOOL)callPhoneNumber:(NSString *)phoneNumber
                   call:(PooCallBlock)callBlock
                 cancel:(PooCancelBlock)cancelBlock;
@end
