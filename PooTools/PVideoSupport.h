//
//  PVideoSupport.h
//  XMNaio_Client
//
//  Created by MYX on 2017/5/16.
//  Copyright © 2017年 E33QU5QCP3.com.xnmiao.customer.XMNiao-Customer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PVideoConfig.h"
@class PVideoModel;

#pragma mark ---------------> 录视频顶部状态条
@interface PStatusBar : UIView

- (instancetype)initWithFrame:(CGRect)frame
                        style:(PVideoViewShowType)style;

- (void)addCancelTarget:(id)target
               selector:(SEL)selector;

@property (nonatomic, assign) BOOL isRecoding;

@end


#pragma mark ---------------> 关闭的下箭头按钮
@interface PCloseBtn : UIButton

@property (nonatomic,strong) NSArray *gradientColors; //CGColorRef


@end

#pragma mark ---------------> 点击录制的按钮
@interface PRecordBtn : UIView

- (instancetype)initWithFrame:(CGRect)frame
                        style:(PVideoViewShowType)style;

@end


#pragma mark ---------------> 聚焦的方框
@interface PFocusView : UIView

- (void)focusing;

@end

#pragma mark ---------------> 眼睛
@interface PEyeView : UIView

@end

#pragma mark ---------------> 录视频下部的控制条
typedef NS_ENUM(NSUInteger, PRecordCancelReason) {
    PRecordCancelReasonDefault,
    PRecordCancelReasonTimeShort,
    PRecordCancelReasonUnknown,
};

@class PControllerBar;
@protocol PControllerBarDelegate <NSObject>

@optional

- (void)ctrollVideoDidStart:(PControllerBar *)controllerBar;

- (void)ctrollVideoDidEnd:(PControllerBar *)controllerBar;

- (void)ctrollVideoDidCancel:(PControllerBar *)controllerBar
                      reason:(PRecordCancelReason)reason;

- (void)ctrollVideoWillCancel:(PControllerBar *)controllerBar;

- (void)ctrollVideoDidRecordSEC:(PControllerBar *)controllerBar;

- (void)ctrollVideoDidClose:(PControllerBar *)controllerBar;

- (void)ctrollVideoOpenVideoList:(PControllerBar *)controllerBar;

@end
#pragma mark ---------------> 录视频下部的控制条
@interface PControllerBar : UIView <UIGestureRecognizerDelegate>

@property (nonatomic, assign) id<PControllerBarDelegate> delegate;

- (void)setupSubViewsWithStyle:(PVideoViewShowType)style
                    recordTime:(NSTimeInterval)recordTime;

@end
#pragma mark ---------------> Video List 控件
#pragma mark ---------------> 删除视频的圆形叉叉 
@interface PCircleCloseBtn : UIButton

@end

#pragma mark ---------------> 视频列表
@interface PVideoListCell:UICollectionViewCell

@property (nonatomic, strong) PVideoModel *videoModel;

@property (nonatomic, strong) void(^deleteVideoBlock)(PVideoModel *);

- (void)setEdit:(BOOL)canEdit;

@end

#pragma mark ---------------> 视频列表的添加 
@interface PAddNewVideoCell : UICollectionViewCell

@end
