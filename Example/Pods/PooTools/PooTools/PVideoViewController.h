//
//  PVideoViewController.h
//  XMNaio_Client
//
//  Created by MYX on 2017/5/16.
//  Copyright © 2017年 E33QU5QCP3.com.xnmiao.customer.XMNiao-Customer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PVideoConfig.h"
#import <UIKit/UIKit.h>

@protocol PVideoViewControllerDelegate;

@interface PVideoViewController : UIView

@property (nonatomic, assign) id<PVideoViewControllerDelegate> delegate;

@property (nonatomic, strong, readonly) UIView *view;

@property (nonatomic, strong, readonly) UIView *actionView;

@property (nonatomic, assign) BOOL savePhotoAlbum;

- (void)startAnimationWithType:(PVideoViewShowType)showType;

//- (void)endAniamtion;

/*! @brief 自定义初始化小视频控件
 * @param recordTime 录取时间 (默认20秒)
 * @param video_W_H 视频长宽比例 (默认4:3)
 * @param videoWidthPX 视频默认宽的分辨率  高 = kzVideoWidthPX / kzVideo_w_h (默认200)
 * @param controViewHeight 控制条高度小屏幕时 (默认120)
 */
-(instancetype)initWithRecordTime:(NSTimeInterval)recordTime
                        video_W_H:(CGFloat)video_W_H
                 withVideoWidthPX:(CGFloat)videoWidthPX
             withControViewHeight:(CGFloat)controViewHeight;
@end

@protocol PVideoViewControllerDelegate <NSObject>

@required
- (void)videoViewController:(PVideoViewController *)videoController
             didRecordVideo:(PVideoModel *)videoModel;

@optional
- (void)videoViewControllerDidCancel:(PVideoViewController *)videoController;

@end

