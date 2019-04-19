//
//  IGBatchTask.m
//  IGHTTPClient
//
//  Created by GavinHe on 16/4/20.
//  Copyright © 2016年 GavinHe. All rights reserved.
//

#import "IGBatchTask.h"
#import <CommonCrypto/CommonDigest.h> 

#import "NSURLSessionTask+IGHTTPClient.h"

#import "IGBatchTaskManager.h"

static NSString* IGBatchTaskLockName = @"IGBatchTaskLockName";

@interface IGBatchTask(){
    NSMutableArray *_allTasks;
    NSMutableArray *_successTasks;
    NSMutableArray *_failureTasks;
    
    NSLock *_lock;
    BOOL _stopping;
    NSInteger _index;
}
@property (nonatomic,strong,readwrite) NSString *uuid;
@property (nonatomic,assign,readwrite) BOOL running;

@end

@implementation IGBatchTask

-(instancetype)init{
    return [self initWithTasks:nil progressBlock:nil complete:nil];
}

- (instancetype)initWithTasks:(NSArray<NSURLSessionTask*>*)tasks{
    return [self initWithTasks:tasks progressBlock:nil complete:nil];
}
- (instancetype)initWithTasks:(NSArray<NSURLSessionTask*>*)tasks progressBlock:(IGBatchTaskProgressBlock)pblock complete:(IGBatchTaskCompleteBlock)cblock{
    self = [super init];
    if (self) {
        [self setup];
        [self refactorTasks:tasks];
        _progressBlock = pblock;
        _completeBlock = cblock;
    }
    return self;
}


- (void)setup{
    [self buildUUID];
    
    _allTasks     = [NSMutableArray new];
    _successTasks = [NSMutableArray new];
    _failureTasks = [NSMutableArray new];

    _index        = 0;
    _stopping     = NO;

    _lock         = [[NSLock alloc] init];
    _lock.name    = IGBatchTaskLockName;

}

- (void)buildUUID{
    NSString *seed = [NSString stringWithFormat:@"%f%d",[[NSDate date] timeIntervalSince1970]*1000,arc4random() % 10000];
    
    // 防止和其他扩展冲突，单纯copy代码到此
    const char *cStr = [seed UTF8String];
    unsigned char result[16];
    CC_MD5( cStr, (int)strlen(cStr), result );
    _uuid = [NSString stringWithFormat:
            @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
            result[0], result[1], result[2], result[3],
            result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11],
            result[12], result[13], result[14], result[15]
            ];    
}

- (void)refactorTasks:(NSArray*)tasks{
    if (tasks) {
        [_allTasks removeAllObjects];
        [_successTasks removeAllObjects];
        [_failureTasks removeAllObjects];
        
        for (NSURLSessionTask *task in tasks) {
            // 元素类型判定
            NSAssert([task isKindOfClass:[NSURLSessionTask class]], @"啊啊啊啊");
            if (![task isKindOfClass:[NSURLSessionTask class]]) {
                continue;
            }
            
            [task ig_setBatchTaskSupport:self];
            [_allTasks addObject:task];
        }
        
        _index    = 0;
        _stopping = NO;
        _running = NO;
    }
}

#pragma mark - ----> Support
- (void)batchTaskDidFinishTask:(NSURLSessionTask*)task result:(BOOL)success{
    [_lock lock];
    [self saveCompleteTask:task toContainer:success?_successTasks:_failureTasks];
    
    // 判定是否未最后一个
    NSInteger nextIndex = _index+1;
    if (nextIndex  >= _allTasks.count) {
        if (_completeBlock) {
            _completeBlock(self,_successTasks,_failureTasks);
        }
        _stopping = NO;
        _running  = NO;
        [[IGBatchTaskManager defaultManager] removeBatchTaskFromPool:self];
    }else{
        if (_progressBlock) {
            _progressBlock([self completeTaskCount], [self taskCount]);
        }
        [self next];
    }
    
    [_lock unlock];
}

#pragma mark - ----> Getter and Setter
-(NSArray *)tasks{
    return _allTasks;
}

-(BOOL)running{
    @synchronized(self){
        return _running;
    }
}

- (NSInteger)taskCount{
    return  _allTasks.count;
}

- (NSInteger)completeTaskCount{
    return  _successTasks.count+_failureTasks.count;
}

#pragma mark - ----> 流程控制
- (void)run{
    [_lock lock];
    
    if (!_running) {
        if (_stopping) {
            _stopping = NO;
            [self next];
            _running  = YES;
        }else{
            NSURLSessionTask *task = [_allTasks firstObject];
            if (task) {
                [task resume];
                _running = YES;
                [[IGBatchTaskManager defaultManager] addBatchTaskToPool:self];
            }else{
                if (_completeBlock) {
                    _completeBlock(self,@[],@[]);
                }
            }
        }
    }else{
        NSLog(@"BatchTask[%@] is running",_uuid);
    }
    
    [_lock unlock];

}

- (void)stop{
    [_lock lock];
    if (_running) {
        _stopping = YES;
    }
    [_lock unlock];
}

#pragma mark - ----> 功能
- (void)saveCompleteTask:(NSURLSessionTask*)task toContainer:(NSMutableArray*)array{
    [array addObject:task];
}

- (void)next{
    if (_stopping) {
        return;
    }
    NSInteger nextIndex = _index+1;
    if (nextIndex  < _allTasks.count) {
        _index = nextIndex;
        NSURLSessionTask *task = _allTasks[_index];
        [task resume];
    }
    
}


@end
