//
//  PooLineLabel.h
//  OMCN
//
//  Created by crazypoo on 15-1-20.
//  Copyright (c) 2015年 doudou. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PooLineLabel : UILabel

@property (assign, nonatomic) BOOL strikeThroughEnabled; // 是否画线

@property (strong, nonatomic) UIColor *strikeThroughColor; // 画线颜色

@end
