//
//  MJPasswordView.h
//  MJPasswordView
//
//  Created by tenric on 13-6-29.
//  Copyright (c) 2013年 tenric. All rights reserved.
//

#import <UIKit/UIKit.h>

#define kPasswordViewSideLength 280.0
#define kCircleRadius 30.0
#define kCircleLeftTopMargin 10.0
#define kCircleBetweenMargin 40.0

#define kPathWidth 6.0

#define kMinPasswordLength 3

//密码状态
typedef enum ePasswordSate {
    ePasswordUnset,//未设置
    ePasswordRepeat,//重复输入
    ePasswordExist,//密码设置成功
    ePasswordSetNew,//设置新密码
    ePasswordClose//关闭密码锁界面
}ePasswordSate;

@class MJPasswordView;

@protocol MJPasswordDelegate <NSObject>

/** 密码输入完毕回调 */
- (void)passwordView:(MJPasswordView*)passwordView withPassword:(NSString*)password;

@end

@interface MJPasswordView : UIView

/** 代理 */
@property (nonatomic,assign) id<MJPasswordDelegate> delegate;

@property (nonatomic,assign) CGPoint previousTouchPoint;

@property (nonatomic,assign) BOOL isTracking;

@property (nonatomic,retain) NSMutableArray* circleLayers;
@property (nonatomic,retain) NSMutableArray* trackingIds;

@end
