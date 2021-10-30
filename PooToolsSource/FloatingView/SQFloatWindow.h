//
//  SQFloatWindow.h
//  iOS10LogTool
//
//  Created by 石学谦 on 17/4/11.
//  Copyright © 2017年 shixueqian. All rights reserved.
//  github地址：https://github.com/shixueqian/iOS10LogDebugTool
//  简书介绍地址：http://www.jianshu.com/p/23011d141622
//  悬浮窗处理类

#import <UIKit/UIKit.h>

@interface SQFloatWindow : UIWindow

/**
 点击事件block
 */
@property (nonatomic,copy) void(^clickBlocks)(NSInteger i);

/**
 悬浮窗初始化
 warning: frame的长宽必须相等
 
 @param frame       frame
 @param mainBtnName 主按钮name
 @param titles      数组，子按钮的name
 @return            SQFloatWindow
 */
- (instancetype)initWithFrame:(CGRect)frame mainBtnName:(NSString*)mainBtnName titles:(NSArray *)titles;

/**
 显示悬浮窗
 */
- (void)showWindow;

/**
 隐藏悬浮窗
 */
- (void)dissmissWindow;



@end
