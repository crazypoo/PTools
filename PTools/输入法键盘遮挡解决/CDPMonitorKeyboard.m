//
//  CDPMonitorKeyboard.m
//  keyboard
//
//  Created by 柴东鹏 on 15/4/26.
//  Copyright (c) 2015年 CDP. All rights reserved.
//

#import "CDPMonitorKeyboard.h"

@implementation CDPMonitorKeyboard{
    UIViewController *_controller;//输入view所在controller
    
}

//单例化
+(CDPMonitorKeyboard *)defaultMonitorKeyboard{
    static CDPMonitorKeyboard *monitorKeyboard= nil;
    
    @synchronized(self){
        if (!monitorKeyboard) {
            monitorKeyboard=[[self alloc] init];
        }
    }
    return monitorKeyboard;
}


//当键盘出现时调用
-(void)keyboardWillShowWithController:(UIViewController *)controller andNotification:(NSNotification *)notification higherThanKeyboard:(NSInteger)valueOfTheHigher{
    _controller=controller;
    //获取键盘的高度
    NSDictionary *userInfo = [notification userInfo];
    NSValue *aValue = [userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect keyboardRect = [aValue CGRectValue];
    NSInteger height = keyboardRect.size.height;
    
    for (UIView *view in _controller.view.subviews) {
        if (view.isFirstResponder==YES) {
            NSInteger value=_controller.view.bounds.size.height-view.frame.origin.y-view.bounds.size.height;
            if (value<height) {
                [UIView animateWithDuration:0.3 animations:^{
                    //防止超出视图最大范围
                    if (value-height-valueOfTheHigher+height<=0) {
                        _controller.view.frame=CGRectMake(0,-height,_controller.view.bounds.size.width,_controller.view.bounds.size.height);
                    }
                    else{
                        _controller.view.frame=CGRectMake(0,value-height-valueOfTheHigher,_controller.view.bounds.size.width,_controller.view.bounds.size.height);
                    }
                }];
            }
        }
    }
    
}
//当键退出时调用
-(void)keyboardWillHide{
    [UIView animateWithDuration:0.3 animations:^{
        _controller.view.frame=CGRectMake(0,0,_controller.view.bounds.size.width,_controller.view.bounds.size.height);
    }];
    
    _controller=nil;
}







@end
