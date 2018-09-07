//
//  PLaunchAdMonitor.h
//  adasdasdadadasdasdadadadad
//
//  Created by MYX on 2017/4/6.
//  Copyright © 2017年 邓杰豪. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

extern NSString * _Nullable PLaunchAdDetailDisplayNotification;

@interface PLaunchAdMonitor : NSObject

/*! @brief App启动广告
 * @param path 数据地址 (数组形式)
 * @param container 展示在那个父视图之上
 * @param interval 展示时间
 * @param param 广告相关数据
 * @param year 公司年份
 * @param sbFont 跳过按钮字体
 * @param comname 公司名字
 * @param cFont 公司名字字体
 * @param callback 点击广告回调
 */
+ (void)showAdAtPath:(nonnull NSArray *)path
              onView:(nonnull UIView *)container
        timeInterval:(NSTimeInterval)interval
    detailParameters:(nullable NSDictionary *)param
               years:(nullable NSString *)year
      skipButtonFont:(UIFont *)sbFont
             comName:(nullable NSString * )comname
         comNameFont:(UIFont *)cFont
            callback:(void(^_Nullable)(void))callback;

@end
