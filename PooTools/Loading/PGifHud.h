//
//  PGifHud.h
//  adasdasdadadasdasdadadadad
//
//  Created by MYX on 2017/4/25.
//  Copyright © 2017年 邓杰豪. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PGifHud : UIView

/*! @brief 设置Gif图片(初始化)
 */
+(void)gifHUDShowIn:(id)views;

/*! @brief 设置Gif图片(图片数组)
 */
+ (void)setGifWithImages:(NSArray *)images;

/*! @brief 设置Gif图片(本地)
 */
+ (void)setGifWithImageName:(NSString *)imageName;

/*! @brief 设置Gif图片(在线)
 */
+ (void)setGifWithURL:(NSURL *)gifUrl;

/*! @brief 设置文字
 */
+(void)setInfoLabelText:(NSString *)str;

/*! @brief 设置成功图片
 */
+ (void)setSuccessHub:(NSString *)successImage;

/*! @brief 设置失败图片
 */
+ (void)setFailHub:(NSString *)failImage;

/*! @brief 展示
 */
+ (void)showWithOverlay;

/*! @brief 移除
 */
+ (void)dismiss;

@end

