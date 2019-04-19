//
//  WMHubWindow.m
//  Dagongzai
//
//  Created by crazypoo on 14/11/5.
//  Copyright (c) 2014年 Pactera. All rights reserved.
//

#import "WMHubWindow.h"

@implementation WMHubWindow

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.windowLevel = UIWindowLevelAlert - 1;
    }
    return self;
}

@end
