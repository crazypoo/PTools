//
//  PVideoListViewController.h
//  XMNaio_Client
//
//  Created by MYX on 2017/5/16.
//  Copyright © 2017年 E33QU5QCP3.com.xnmiao.customer.XMNiao-Customer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PVideoConfig.h"

@class PVideoModel;
/*!
 *  视频列表
 */
@interface PVideoListViewController : NSObject

@property (nonatomic, strong, readonly) UIView *actionView;

@property (nonatomic, copy) void(^selectBlock)(PVideoModel *);

@property (nonatomic, copy) void(^didCloseBlock)(void);

- (void)showAnimationWithType:(PVideoViewShowType)showType;

-(instancetype)initWithVideo_H_W:(CGFloat)Video_W_H
            withControViewHeight:(CGFloat)controViewHeight;

@end
