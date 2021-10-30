//
//  IGBannerItem.h
//  Demo
//
//  Created by 何桂强 on 14/10/30.
//  Copyright (c) 2014年 touchmob.com. All rights reserved.
//

/*
 IGBannerItem *item1 = [[IGBannerItem alloc] initWithTitle:@"title1" image:[UIImage imageNamed:@"photo1.jpg"] tag:1001];
 IGBannerItem *item2 = [[IGBannerItem alloc] initWithTitle:@"title2" image:[UIImage imageNamed:@"photo2.jpg"] tag:1002];
 IGBannerItem *item3 = [[IGBannerItem alloc] initWithTitle:@"title3" image:[UIImage imageNamed:@"photo3.jpg"] tag:1003];
 
 IGBannerView *imageFrame = [[IGBannerView alloc] initWithFrame:self.view.frame bannerItem:item1, item2, item3, nil];
*/


#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, IGBannerItemStyle) {
    IGBannerItemWithImage = 1,
    IGBannerItemWithImageURL
};

@interface IGBannerItem : NSObject

/*! @brief 广告标题
 */
@property (nonatomic, strong) NSString  *title;
/*! @brief 广告风格
 */
@property (nonatomic, assign) IGBannerItemStyle style;
/*! @brief 广告图片
 */
@property (nonatomic, strong) UIImage   *image;
/*! @brief 广告图片URL
 */
@property (nonatomic, strong) NSString  *imageUrl;
/*! @brief 广告对象
 */
@property (nonatomic, strong) NSObject  *obj;
/*! @brief 广告tag
 */
@property (nonatomic, assign) int tag;

/*! @brief 广告初始化(加载图片)-
 * @param title 标题
 * @param image 图片
 * @param tag tag
 */
- (id)initWithTitle:(NSString *)title image:(UIImage *)image tag:(int)tag;
/*! @brief 广告初始化(加载图片)+
 * @param title 标题
 * @param image 图片
 * @param tag tag
 */
+ (id)itemWithTitle:(NSString *)title image:(UIImage *)image tag:(int)tag;

/*! @brief 广告初始化(加载图片URL)-
 * @param title 标题
 * @param imageUrl 图片URL
 * @param tag tag
 */
- (id)initWithTitle:(NSString *)title imageUrl:(NSString *)imageUrl tag:(int)tag;
/*! @brief 广告初始化(加载图片URL)+
 * @param title 标题
 * @param imageUrl 图片URL
 * @param tag tag
 */
+ (id)itemWithTitle:(NSString *)title imageUrl:(NSString *)imageUrl tag:(int)tag;

@end
