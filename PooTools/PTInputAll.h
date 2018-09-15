//
//  PTInputAll.h
//  PTools
//
//  Created by crazypoo on 14/12/24.
//  Copyright (c) 2014年 crazypoo. All rights reserved.
//

/*
 ░░░░░░░░░▄░░░░░░░░░░░░░░▄░░░░
 ░░░░░░░░▌▒█░░░░░░░░░░░▄▀▒▌░░░
 ░░░░░░░░▌▒▒█░░░░░░░░▄▀▒▒▒▐░░░
 ░░░░░░░▐▄▀▒▒▀▀▀▀▄▄▄▀▒▒▒▒▒▐░░░
 ░░░░░▄▄▀▒░▒▒▒▒▒▒▒▒▒█▒▒▄█▒▐░░░
 ░░░▄▀▒▒▒░░░▒▒▒░░░▒▒▒▀██▀▒▌░░░
 ░░▐▒▒▒▄▄▒▒▒▒░░░▒▒▒▒▒▒▒▀▄▒▒▌░░
 ░░▌░░▌█▀▒▒▒▒▒▄▀█▄▒▒▒▒▒▒▒█▒▐░░
 ░▐░░░▒▒▒▒▒▒▒▒▌██▀▒▒░░░▒▒▒▀▄▌░
 ░▌░▒▄██▄▒▒▒▒▒▒▒▒▒░░░░░░▒▒▒▒▌░
 ▀▒▀▐▄█▄█▌▄░▀▒▒░░░░░░░░░░▒▒▒▐░
 ▐▒▒▐▀▐▀▒░▄▄▒▄▒▒▒▒▒▒░▒░▒░▒▒▒▒▌
 ▐▒▒▒▀▀▄▄▒▒▒▄▒▒▒▒▒▒▒▒░▒░▒░▒▒▐░
 ░▌▒▒▒▒▒▒▀▀▀▒▒▒▒▒▒░▒░▒░▒░▒▒▒▌░
 ░▐▒▒▒▒▒▒▒▒▒▒▒▒▒▒░▒░▒░▒▒▄▒▒▐░░
 ░░▀▄▒▒▒▒▒▒▒▒▒▒▒░▒░▒░▒▄▒▒▒▒▌░░
 ░░░░▀▄▒▒▒▒▒▒▒▒▒▒▄▄▄▀▒▒▒▒▄▀░░░
 ░░░░░░▀▄▄▄▄▄▄▀▀▀▒▒▒▒▒▄▄▀░░░░░
 ░░░░░░░░░▒▒▒▒▒▒▒▒▒▒▀▀░░░░░░░░
 */

//导入次工具时，一定要在Build Settings->other links flags加入-ObjC
//lipo -create xxxxxxxx/xxxxxxxxx(真机) xxxxxxxxx/xxxxxxxxx(模拟器) -output (输出路径)
#ifndef PTools_PTInputAll_h
#define PTools_PTInputAll_h


//工具类
#import "GPKeyChain.h"//KeyChain
#import "PBugReporter.h"//BUG反馈
#import "PCarrie.h"//网络运营商检测
#import "PHealthKit.h"//HealthKit(调用此工具，需在项目TagertS->Capabilities-勾选HealthKit)
#import "PMacros.h"//宏定义
#import "PMotion.h"//运动步数，速度，状态
#import "PooActionOnCalendar.h"//添加时间到日历
#import "PooCodeView.h"//动态验证码
#import "PooPhoneBlock.h"//打电话
#import "PooSystemInfo.h"//系统信息
#import "PooUDIDInfo.h"//自定义UDID
#import "PSpeech.h"//语音识别（iOS10以上）
#import "PBiologyID.h"//生物验证
#import "Utils.h"//通用工具

//加载
#import "PooLoadingView.h"//加载小圈圈
#import "WMHub.h"//转圈加载动画

//View
#import "PGifHud.h"//GIFHUD
#import "PLaunchAdMonitor.h"//启动广告
#import "PooTagsLabel.h"//标签
#import "PooSegView.h"//SegView
#import "PStarRateView.h"//RateView
#import "SecurityStrategy.h"//进入后台模糊图层

//Button
#import "RCDraggableButton.h"//浮动按钮

//ActionSheet
#import "ALActionSheetView.h"//ActionSheet

//输入类
#import "CustomTextField.h"//UITextField改造
#import "HPGrowingTextView.h"//根据输入的文本自适应高度的TextView
#import "PooNumberKeyBoard.h"//数字键盘
#import "PooSearchBar.h"//自定义SearchBar
#import "PTextField.h"//自定义TextField
#import "PooTextView.h"//TextView加底字

//Label类
#import "PLabel.h"//Label居中、居上、居下,并且可以带中线
#import "WPAttributedStyleAction.h"//Label可点击
#import "WPHotspotLabel.h"//Label可点击
#import "WPTappableLabel.h"//Label可点击

//Category
#import "NSMutableArray+Shuffle.h"//随机数组
#import "NSMutableString+TagReplace.h"//Label可点击
#import "NSString+Encryption.h"//MD5加密
#import "NSString+Regulars.h"//正则表达式（数字英文、数字、邮箱、手机号码、固话、身份证）
#import "NSString+WPAttributedMarkup.h"//Label可点击
#import "NSURLResponse+Help.h"//Http版本检测
#import "UIButton+Block.h"//UIButton
#import "UIColor+Helper.h"//颜色
#import "UIImage+Size.h"//UIImageSize调整
#import "UILabel+FlickerNumber.h"//数字跳动
#import "UINavigationItem+Excursion.h"//导航栏按钮位置调整
#import "UIView+ModifyFrame.h"//简化xywh获取
#import "UIViewController+TopBarMessage.h"//自定义顶部弹出提醒
#endif
