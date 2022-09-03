//
//  DOMaskView.h
//  Diou
//
//  Created by ken lam on 2021/6/22.
//  Copyright © 2021 DO. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PTMaskView : UIView
-(instancetype)initWithFrame:(CGRect)frame;
@property(nonatomic, assign)BOOL masked; // canvas是否拦截事件, 默认 YES.
@end

NS_ASSUME_NONNULL_END
