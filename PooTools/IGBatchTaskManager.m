//
//  IGBatchTaskManager.m
//  IGHTTPClient
//
//  Created by GavinHe on 16/4/20.
//  Copyright © 2016年 GavinHe. All rights reserved.
//

#import "IGBatchTaskManager.h"


static NSString* IGBatchTaskManagerLockName = @"IGBatchTaskManagerLockName";

@interface IGBatchTaskManager (){
    NSMutableDictionary *_batchTaskPool;
    NSLock *_lock;
}

@end

@implementation IGBatchTaskManager

+(instancetype)defaultManager
{
    static id _sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[IGBatchTaskManager alloc] init];
    });
    return _sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _lock      = [[NSLock alloc] init];
        _lock.name = IGBatchTaskManagerLockName;
        
        _batchTaskPool = [NSMutableDictionary new];
    }
    return self;
}

- (void)addBatchTaskToPool:(IGBatchTask*)task{
    [_lock lock];
    if (!_batchTaskPool[task.uuid]) {
        _batchTaskPool[task.uuid] = task;
    }
    [_lock unlock];
}

- (void)removeBatchTaskFromPool:(IGBatchTask*)task{
    [self removeBatchTaskFromPoolWithUUID:task.uuid];
}
- (void)removeBatchTaskFromPoolWithUUID:(NSString*)uuid{
    [_lock lock];
    if (_batchTaskPool[uuid]) {
        _batchTaskPool[uuid] = nil;
    }
    [_lock unlock];
}

@end
