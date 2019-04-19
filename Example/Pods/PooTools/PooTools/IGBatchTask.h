//
//  IGBatchTask.h
//  IGHTTPClient
//
//  Created by GavinHe on 16/4/20.
//  Copyright © 2016年 GavinHe. All rights reserved.
//

#import <Foundation/Foundation.h>

@class IGBatchTask;
@class NSURLSessionTask;

typedef void(^IGBatchTaskProgressBlock)(NSInteger finish, NSInteger total);
typedef void(^IGBatchTaskCompleteBlock)(IGBatchTask *batchTask, NSArray *successTasks, NSArray *failureTasks);

@protocol IGBatchTaskSupport <NSObject>

@required
- (void)batchTaskDidFinishTask:(NSURLSessionTask*)task result:(BOOL)success;
@end

@interface IGBatchTask : NSObject<IGBatchTaskSupport>

@property (nonatomic,assign) NSInteger tag;
@property (nonatomic,strong) NSString  *name;

@property (nonatomic,strong,readonly) NSString *uuid;

@property (nonatomic,strong,readonly) NSArray  *tasks;

@property (nonatomic,assign,readonly) BOOL running;

@property (nonatomic,copy) IGBatchTaskProgressBlock progressBlock;
@property (nonatomic,copy) IGBatchTaskCompleteBlock completeBlock;

- (instancetype)initWithTasks:(NSArray<NSURLSessionTask*>*)tasks;
- (instancetype)initWithTasks:(NSArray<NSURLSessionTask*>*)tasks progressBlock:(IGBatchTaskProgressBlock)pblock complete:(IGBatchTaskCompleteBlock)cblock;

- (void)run;
- (void)stop;

@end
