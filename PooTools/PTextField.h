//
//  PTextField.h
//  CollTest
//
//  Created by crazypoo on 14/10/27.
//  Copyright (c) 2014年 crazypoo. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PTextField : UITextField
@property (nonatomic, strong) UIImageView *textFieldHeadImageView;
-(id)initWithFrame:(CGRect)frame
             image:(UIImage *)image;
@end
