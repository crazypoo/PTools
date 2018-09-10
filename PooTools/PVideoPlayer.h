//
//  PVideoPlayer.h
//  XMNaio_Client
//
//  Created by MYX on 2017/5/16.
//  Copyright © 2017年 E33QU5QCP3.com.xnmiao.customer.XMNiao-Customer. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PVideoPlayer : UIView

- (instancetype)initWithFrame:(CGRect)frame
                     videoUrl:(NSURL *)videoUrl;

@property (nonatomic, strong, readonly) NSURL *videoUrl;

@property (nonatomic,assign) BOOL autoReplay; // 默认 YES

- (void)play;

- (void)stop;

@end
