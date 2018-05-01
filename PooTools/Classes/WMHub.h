//
//  WMHub.h
//  Dagongzai
//
//  Created by crazypoo on 14/11/5.
//  Copyright (c) 2014年 Pactera. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface WMHub : NSObject

//顯示 hud
+ (void)show;

//隱藏 hud
+ (void)hide;

//設定自己想要的顏色循環, 預設是 紅 -> 綠 -> 黃 -> 藍 -> loop, 起始為哪一個則為隨機, 建議設定兩個顏色以上
+ (void)setColors:(NSArray *)colors;

//設定 hud 的背景顏色, 預設為 0.65 alpha 的黑色
+ (void)setBackgroundColor:(UIColor *)backgroundColor;

//設定 hud 轉圈圈線的粗細, 預設為 2.0f, 數值大約到 10.0f 都還可以看, 到 20.0f 就不知道在幹嘛了
+ (void)setLineWidth:(CGFloat)lineWidth;

// 设定 默认
+ (void)resetDefaultSetting;

@end
