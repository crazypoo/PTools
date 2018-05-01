//
//  PGifHud.h
//  adasdasdadadasdasdadadadad
//
//  Created by MYX on 2017/4/25.
//  Copyright © 2017年 邓杰豪. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PGifHud : UIView
//初始化
+(void)gifHUDShowIn:(id)views;
//设置图片
+ (void)setGifWithImages:(NSArray *)images;
+ (void)setGifWithImageName:(NSString *)imageName;
+ (void)setGifWithURL:(NSURL *)gifUrl;
//设置文字
+(void)setInfoLabelText:(NSString *)str;
//设置成功&&失败图片
+ (void)setSuccessHub:(NSString *)successImage;
+ (void)setFailHub:(NSString *)failImage;
//展示，移除
+ (void)showWithOverlay;
+ (void)dismiss;

@end

