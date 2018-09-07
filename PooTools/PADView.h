//
//  PADView.h
//  CloudGateCustom
//
//  Created by 邓杰豪 on 16/5/18.
//  Copyright © 2018年 邓杰豪. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CGAdBannerModel.h"
#import "CGLayout.h"
#import "CGADCollectionViewCell.h"

@interface PADView : UIView <UICollectionViewDelegate,UICollectionViewDataSource>
{
    NSArray *viewData;
    NSString *placeholderImageString;
    NSTimer *timer;
    UICollectionView * adCollectionView;
    int pageTime;
}

@property (nonatomic, copy) void(^adTouchBlock)(CGAdBannerModel *touchModel);

-(instancetype)initWithAdArray:(NSArray <CGAdBannerModel *> *)adArr
                     singleADW:(CGFloat)sw
                     singleADH:(CGFloat)sh
                      paddingY:(CGFloat)py
                      paddingX:(CGFloat)px
              placeholderImage:(NSString *)pI
                      pageTime:(int)pT
                   adTitleFont:(UIFont *)adTitleFont;
@end
