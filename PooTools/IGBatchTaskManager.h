//
//  IGBatchTaskManager.h
//  IGHTTPClient
//
//  Created by GavinHe on 16/4/20.
//  Copyright © 2016年 GavinHe. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IGBatchTask.h"

@interface IGBatchTaskManager : NSObject

+(instancetype)defaultManager;

- (void)addBatchTaskToPool:(IGBatchTask*)task;

- (void)removeBatchTaskFromPool:(IGBatchTask*)task;
- (void)removeBatchTaskFromPoolWithUUID:(NSString*)uuid;

@end
