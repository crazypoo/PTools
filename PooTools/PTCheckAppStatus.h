//
//  PTCheckAppStatus.h
//  CloudGateWorker
//
//  Created by 邓杰豪 on 2019/3/27.
//  Copyright © 2019年 邓杰豪. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface PTCheckAppStatus : NSObject
@property (nonatomic,strong)UILabel *fpsLabel;
@property (nonatomic,assign)BOOL closed;
+ (PTCheckAppStatus *)sharedInstance;
- (void)open;
- (void)openWithHandler:(void (^)(NSInteger fpsValue))handler;
- (void)close;
@end

NS_ASSUME_NONNULL_END
