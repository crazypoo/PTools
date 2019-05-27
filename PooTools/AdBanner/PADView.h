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

/*! @brief 广告初始化
 * @param adArr 广告数组
 * @param sw 每页的宽度
 * @param sh 每页的高度
 * @param py uiedge's up and bottom
 * @param px uiedge's left and right
 * @param pI Placeholder图片
 * @param pT 自动滑动时间
 * @param adTitleFont 标题字体
 * @param pageTColor pageControl未选中颜色
 * @param pageCColor pageControl选中颜色
 */
-(instancetype)initWithAdArray:(NSArray <CGAdBannerModel *> *)adArr
                     singleADW:(CGFloat)sw
                     singleADH:(CGFloat)sh
                      paddingY:(CGFloat)py
                      paddingX:(CGFloat)px
              placeholderImage:(NSString *)pI
                      pageTime:(int)pT
                   adTitleFont:(UIFont *)adTitleFont
        pageIndicatorTintColor:(UIColor *)pageTColor
 currentPageIndicatorTintColor:(UIColor *)pageCColor
                    pageEnable:(BOOL)pEnable;
@end
