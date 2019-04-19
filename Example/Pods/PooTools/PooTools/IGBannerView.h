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
@property (nonatomic, assign) BOOL autoScrolling; // default is YES;
@property (nonatomic) NSTimeInterval switchTimeInterval; // default for 5s;

@property (nonatomic, unsafe_unretained) id<IGBannerViewDelegate> delegate;

/* 标题栏属性 */
@property (nonatomic, strong) UIColor *titleColor; // default is white
@property (nonatomic, strong) UIColor *titleBackgroundColor; // default is black(alpha is 35%)
@property (nonatomic, strong) UIFont *titleFont; // default is system(14)
@property (nonatomic, assign) float titleHeight; // default is 20
/* Page Control属性 */
@property (nonatomic, assign) float pageControlHeight; // default is 14;
@property (nonatomic, strong) UIColor *pageControlBackgroundColor; // default is black(alpha is 35%)

- (id)initWithFrame:(CGRect)frame bannerItem:(IGBannerItem *)items, ... NS_REQUIRES_NIL_TERMINATION;
- (id)initWithFrame:(CGRect)frame bannerItems:(NSArray *)items bannerPlaceholderImage:(UIImage *)pI;

@property (nonatomic,strong) BannerViewDidTapBlock bannerTapBlock;

@end

@protocol IGBannerViewDelegate <NSObject>
@optional
-(void)bannerView:(IGBannerView*)bannerView didSelectItem:(IGBannerItem*)item;

@end
