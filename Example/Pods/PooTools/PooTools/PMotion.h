//
//  PMotion.h
//  adasdasdadadasdasdadadadad
//
//  Created by MYX on 2017/4/21.
//  Copyright © 2017年 邓杰豪. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol PMotionDelegate <NSObject>
-(void)callBackWithStep:(NSString *)step status:(NSString *)status speed:(NSString *)speed;
@end

@interface PMotion : NSObject
/*! @brief M7处理器数据代理
 */
@property (nonatomic, weak) id<PMotionDelegate>delegate;
/*! @brief M7处理器使用单例化
 */
+(instancetype)defaultMonitor;
/*! @brief 获取M7处理器数据
 */
-(void)getMotion;
@end
