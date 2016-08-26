//
//  PooPassWordView.h
//  test
//
//  Created by 邓杰豪 on 15/4/29.
//  Copyright (c) 2015年 邓杰豪. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MJPasswordView.h"
#import "GPLittlePassWordView.h"

@class PooPassWordView;
@protocol PooPassWordViewDelegate <NSObject>
@optional
- (void)alertViewTapOk;
@end

static NSString *keyWord = @"passWord";
@interface PooPassWordView : UIView<MJPasswordDelegate>
{
    MJPasswordView *passwordView;
    ePasswordSate state;
    GPLittlePassWordView *littleView;
    UILabel *infoLabel;
    NSString*littleViewPassword;
    int count;
    int labelCount;
    UILabel *worngLabel;
}
@property (nonatomic, weak) id<PooPassWordViewDelegate>delegate;
@end
