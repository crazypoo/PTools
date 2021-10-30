//
//  UIView+LayoutSubviewsCallback.h
//  PooTools_Example
//
//  Created by 邓杰豪 on 2018/9/9.
//  Copyright © 2018年 crazypoo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface UIView (LayoutSubviewsCallback)

@property (nonatomic, copy) void(^layoutSubviewsCallback)(UIView *view);

@end
