//
//  CustomTextField.m
//  WWLJTextField
//
//  Created by iShareme on 15/11/4.
//  Copyright © 2015年 iShareme. All rights reserved.
//

#import "CustomTextField.h"

@interface CustomTextField ()

@property (nonatomic, strong)UILabel *gtPlaceholderLabel;
@property (nonatomic, strong)UILabel *gtDisplayLabel;

@end

@implementation CustomTextField
@synthesize lineColor;

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.backgroundColor = [UIColor whiteColor];
        self.font = [UIFont systemFontOfSize:14];
        self.borderStyle = UITextBorderStyleRoundedRect;
    }
    return self;
}

-(void)layoutSubviews
{
    [super layoutSubviews];

    UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(0, self.frame.size.height-2, self.frame.size.width, 2)];
    lineView.backgroundColor = lineColor;
    [self addSubview:lineView];
}

-(UILabel *)gtPlaceholderLabel
{
    return [self valueForKey:@"_placeholderLabel"];
}

-(UILabel *)gtDisplayLabel
{
    return [self valueForKey:@"_displayLabel"];
}

- (void)doAnimationWithType:(GTAnimationType)gtAnimationType and:(UILabel *)label
{
    switch (gtAnimationType) {
        case GTAnimationTypeUpDown:{
            [UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:0.1 initialSpringVelocity:10 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                
                label.transform = CGAffineTransformMakeTranslation(0, 10);
                
            } completion:nil];
        }
            break;
        case GTAnimationTypeLeftRight:{
            [UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:0.1 initialSpringVelocity:10 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                
                label.transform = CGAffineTransformMakeTranslation(10, 0);
                
            } completion:nil];
        }
            break;
        case GTAnimationTypeBlowUp:{
            [UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:0.1 initialSpringVelocity:10 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                
                label.transform = CGAffineTransformMakeScale(1.2, 1.2);
                
            } completion:nil];
        }
            break;
        case GTAnimationTypeEasyInOut:{
            [UIView animateWithDuration:0.5 animations:^{
                label.alpha = 0.4;
            }];
        }
            break;
        case GTAnimationTypeNone:{
            break;
        }
            break;
        default:
            break;
    }
}

- (void)displayLableDoAnimationWithType:(GTAnimationType)gtAnimationType
{
    [self doAnimationWithType:gtAnimationType and:self.gtDisplayLabel];
    self.gtDisplayLabel.transform = CGAffineTransformIdentity;
}

- (void)placeholderLabelDoAnimationWithType:(GTAnimationType)gtAnimationType
{
    [self doAnimationWithType:gtAnimationType and:self.gtPlaceholderLabel];
}

//复写父类的方法
-(BOOL)becomeFirstResponder
{
    if (self.normalColor == nil) {
        self.normalColor = self.gtPlaceholderLabel.textColor;
    }if (self.selectedColor == nil) {
        self.selectedColor = self.gtPlaceholderLabel.textColor;
    }
    self.gtPlaceholderLabel.textColor = self.selectedColor;
    [self placeholderLabelDoAnimationWithType:self.gtAnimationType];
    return [super becomeFirstResponder];
}

-(BOOL)resignFirstResponder
{
    switch (self.gtAnimationType) {
        case GTAnimationTypeUpDown:{
            self.gtPlaceholderLabel.transform = CGAffineTransformIdentity;
        }
            break;
        case GTAnimationTypeLeftRight:{
            self.gtPlaceholderLabel.transform = CGAffineTransformIdentity;
        }
            break;
        case GTAnimationTypeBlowUp:{
            
        }
            break;
        case GTAnimationTypeEasyInOut:{
            [UIView animateWithDuration:0.5 animations:^{
                self.gtPlaceholderLabel.alpha = 1;
            }];
        }
            break;
        case GTAnimationTypeNone:{
            break;
        }
            break;
        default:
            break;
    }
    
    self.gtPlaceholderLabel.textColor = self.normalColor;
    return [super resignFirstResponder];
}


@end
