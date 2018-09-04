//
//  CustomTextField.h
//  WWLJTextField
//
//  Created by iShareme on 15/11/4.
//  Copyright © 2015年 iShareme. All rights reserved.
//

#import <UIKit/UIKit.h>
typedef NS_ENUM(NSInteger, GTAnimationType) {
    GTAnimationTypeUpDown,
    GTAnimationTypeLeftRight,
    GTAnimationTypeBlowUp,
    GTAnimationTypeEasyInOut,
    GTAnimationTypeNone
};
@interface CustomTextField : UITextField
@property(nonatomic, strong)UIColor *normalColor;
@property(nonatomic, strong)UIColor *selectedColor;
@property(nonatomic, assign)GTAnimationType gtAnimationType;
@property (nonatomic, retain) UIColor *lineColor;
@end
