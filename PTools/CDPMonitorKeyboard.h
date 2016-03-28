//
//  CDPMonitorKeyboard.h
//  keyboard
//
//  Created by 柴东鹏 on 15/4/26.
//  Copyright (c) 2015年 CDP. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface CDPMonitorKeyboard : NSObject

//获取其单例
+(CDPMonitorKeyboard *)defaultMonitorKeyboard;

//键盘出现时调用方法
-(void)keyboardWillShowWithController:(UIViewController *)controller andNotification:(NSNotification *)notification higherThanKeyboard:(NSInteger)valueOfTheHigher;

//键盘消失时调用方法
-(void)keyboardWillHide;

//1
////增加监听，当键盘出现或改变时收出消息
//[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
////增加监听，当键退出时收出消息
//[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];

//2
//#pragma mark 键盘监听方法设置
////当键盘出现时调用
//-(void)keyboardWillShow:(NSNotification *)aNotification{
//    //第一个参数写self即可，第二个写监听获得的notification，第三个写希望高于键盘的高度(只在被键盘遮挡时才启用,如控件未被遮挡,则无变化)
//    [[CDPMonitorKeyboard defaultMonitorKeyboard] keyboardWillShowWithController:self andNotification:aNotification higherThanKeyboard:0];
//    
//}
////当键退出时调用
//-(void)keyboardWillHide:(NSNotification *)aNotification{
//    [[CDPMonitorKeyboard defaultMonitorKeyboard] keyboardWillHide];
//}

//3
////dealloc中需要移除监听
//-(void)dealloc{
//    //移除监听，当键盘出现或改变时收出消息
//    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
//    
//    //移除监听，当键退出时收出消息
//    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
//}

@end
