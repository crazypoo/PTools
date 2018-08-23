//
//  HZWaitingView.h
//  HZPhotoBrowser
//
//  Created by huangzhenyu on 15-2-6.
//  Copyright (c) 2015年 huangzhenyu. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
    HZWaitingViewModeLoopDiagram, // 环形
    HZWaitingViewModePieDiagram // 饼型
} HZWaitingViewMode;

@interface HZWaitingView : UIView

@property (nonatomic, assign) CGFloat progress;
@property (nonatomic, assign) int mode;

@end
