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

/*! @brief 拨打电话
 * @param phoneNumber 电话号码
 * @param callBlock 回调通话时长
 * @param cancelBlock 回调通话取消
 */
+ (BOOL)callPhoneNumber:(NSString *)phoneNumber
                   call:(PooCallBlock)callBlock
                 cancel:(PooCancelBlock)cancelBlock;
@end
