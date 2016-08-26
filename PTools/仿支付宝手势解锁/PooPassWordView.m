//
//  PooPassWordView.m
//  test
//
//  Created by 邓杰豪 on 15/4/29.
//  Copyright (c) 2015年 邓杰豪. All rights reserved.
//

#import "PooPassWordView.h"

@implementation PooPassWordView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [self setPassWordView];
        self.backgroundColor = [UIColor clearColor];
        if ([[NSUserDefaults standardUserDefaults] objectForKey:keyWord] == nil) {
            littleViewPassword = @"";
            state = ePasswordUnset;
            [self updateInfoLabel];

        }
        else
        {
            littleViewPassword = [[NSUserDefaults standardUserDefaults] objectForKey:keyWord];
            state = ePasswordExist;
            [self updateInfoLabel];

        }
        
    }
    return self;
}

-(void)setPassWordView
{
    infoLabel = [[UILabel alloc] initWithFrame:CGRectMake((self.frame.size.width-300)/2, 20, 300, 30)];
    infoLabel.backgroundColor = [UIColor clearColor];
    infoLabel.textAlignment =  NSTextAlignmentCenter;
    infoLabel.textColor = [UIColor redColor];
    [self addSubview:infoLabel];

    passwordView = [[MJPasswordView alloc] initWithFrame:CGRectMake((self.frame.size.width-280)/2, 120, kPasswordViewSideLength, kPasswordViewSideLength)];
    passwordView.backgroundColor = [UIColor clearColor];
    passwordView.delegate = self;
    [self addSubview:passwordView];
    
    worngLabel = [[UILabel alloc] initWithFrame:CGRectMake((self.frame.size.width-300)/2, infoLabel.frame.origin.y+40, 300, 30)];
    worngLabel.backgroundColor = [UIColor clearColor];
    worngLabel.textAlignment =  NSTextAlignmentCenter;
    worngLabel.textColor = [UIColor redColor];
    [self addSubview:worngLabel];
    
    count = 0;
    labelCount = 3;
    [self updateInfoLabel];

}

- (void)passwordView:(MJPasswordView*)passwordView withPassword:(NSString*)password
{
    switch (state)
    {
        case ePasswordUnset:
            littleViewPassword = password;
            state = ePasswordRepeat;
            break;
            
        case ePasswordRepeat:
            if ([password isEqualToString:littleViewPassword])
            {
                littleView.hidden = YES;
                [littleView removeFromSuperview];
                state = ePasswordExist;
                id object = [self nextResponder];
                while (![object isKindOfClass:[UIViewController class]] && object != nil)
                {
                    object = [object nextResponder];
                }
                UIViewController *uc=(UIViewController*)object;
                [uc dismissViewControllerAnimated:YES completion:nil];
            }
            break;
            
        case ePasswordExist:
            if ([password isEqualToString:littleViewPassword])
            {
                count =0;
                labelCount = 3;
                worngLabel.hidden = YES;
                id object = [self nextResponder];
                while (![object isKindOfClass:[UIViewController class]] && object != nil)
                {
                    object = [object nextResponder];
                }
                UIViewController *uc=(UIViewController*)object;
                [uc dismissViewControllerAnimated:YES completion:nil];
                
            }
            else
            {
                worngLabel.text = [NSString stringWithFormat:@"密码错误,还可以再输入%d次",--labelCount];
                CAKeyframeAnimation *anim = [CAKeyframeAnimation animationWithKeyPath:@"transform.translation.x"];
                anim.repeatCount = 1;
                anim.values = @[@-20, @20, @-20];
                [worngLabel.layer addAnimation:anim forKey:nil];
                worngLabel.hidden = NO;
                
                
                if (++count>=3) {
                    UIAlertView* view = [[UIAlertView alloc] initWithTitle:@"密码错误次数过多，请重置手势密码" message:nil delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
                    [view setTag:998];
                    [view show];
                }
                else
                {
                    UIAlertView* view = [[UIAlertView alloc] initWithTitle:@"密码错误，请重试！" message:nil delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
                    [view show];
                }
                
            }
            
            break;
            
        default:
            break;
    }
    [self updateInfoLabel];
}

- (void)updateInfoLabel
{
    NSString* infoText;
    switch (state)
    {
        case ePasswordUnset:
            infoText = @"请滑动九宫格，设置密码";
            break;
            
        case ePasswordRepeat:
        {
            infoText = @"请再次输入密码";
            littleView = [[GPLittlePassWordView alloc] initWithFrame:CGRectMake((self.frame.size.width-60)/2, infoLabel.frame.origin.y+40, 60, 60) str:littleViewPassword];
            littleView.backgroundColor = [UIColor clearColor];
            littleView.hidden = NO;
            [self addSubview:littleView];
        }
            break;
            
        case ePasswordExist:
        {
            infoText = @"请画出手势密码";
            [littleView removeFromSuperview];
            [[NSUserDefaults standardUserDefaults] setObject:littleViewPassword forKey:keyWord];
        }
            break;
            
        default:
            break;
    }
    infoLabel.text = infoText;
}

#pragma mark -------弹出框按钮
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == 998)
    {
        if (buttonIndex == 0) {
            [self.delegate alertViewTapOk];
        }
    }
    
}

@end
