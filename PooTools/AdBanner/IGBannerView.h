//
//  IGBannerView.h
//
//  由SGFocusImageFrame改写而来
//  依赖类库：SDWebImage
//  Created by 何桂强 on 14/10/30.
//  Copyright (c) 2014年 practer. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IGBannerItem.h"

@protocol IGBannerViewDelegate;
@class IGBannerView;

typedef void (^BannerViewDidTapBlock)(IGBannerView *bannerView, IGBannerItem *bannerItem);

@interface IGBannerView : UIView
/*! @brief 是否滑动
 * @attention 默认YES
 */
@property (nonatomic, assign) BOOL autoScrolling;
/*! @brief 滑动时间
 * @attention 默认5s
 */
@property (nonatomic) NSTimeInterval switchTimeInterval;
/*! @brief 广告代理
 */
@property (nonatomic, unsafe_unretained) id<IGBannerViewDelegate> delegate;

/*! @brief 广告标题颜色
 * @attention 默认白色
 */
@property (nonatomic, strong) UIColor *titleColor;
/*! @brief 广告标题背景颜色
 * @attention 默认黑色(alpha is 35%)
 */
@property (nonatomic, strong) UIColor *titleBackgroundColor;
/*! @brief 广告标题字体
 * @attention 默认system14
 */
@property (nonatomic, strong) UIFont *titleFont;
/*! @brief 广告标题高度
 * @attention 默认20
 */
@property (nonatomic, assign) float titleHeight;

/*! @brief 广告PageControl高度
 * @attention 默认14
 */
@property (nonatomic, assign) float pageControlHeight;
/*! @brief 广告PageControl高度
 * @attention 默认黑色(alpha is 35%)
 */
@property (nonatomic, strong) UIColor *pageControlBackgroundColor;

/*! @brief 广告初始化
 * @param frame 广告frame
 * @param items 广告item
 */
- (id)initWithFrame:(CGRect)frame bannerItem:(IGBannerItem *)items, ... NS_REQUIRES_NIL_TERMINATION;
/*! @brief 广告初始化
 * @param frame 广告frame
 * @param items 广告item
 * @param pI 广告placeholder图片
 */
- (id)initWithFrame:(CGRect)frame bannerItems:(NSArray *)items bannerPlaceholderImage:(UIImage *)pI;

/*! @brief 广告点击回调
 */
@property (nonatomic,strong) BannerViewDidTapBlock bannerTapBlock;

@end

@protocol IGBannerViewDelegate <NSObject>
@optional
-(void)bannerView:(IGBannerView*)bannerView didSelectItem:(IGBannerItem*)item;

@end
