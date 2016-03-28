//
//  GPLittlePassWordView.h
//  LittlePassWorld
//
//  Created by crazypoo on 14/7/8.
//  Copyright (c) 2014年 crazypoo. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GPLittlePassWordView : UIView
@property (nonatomic, strong) UILabel *label0;
@property (nonatomic, strong) UILabel *label1;
@property (nonatomic, strong) UILabel *label2;
@property (nonatomic, strong) UILabel *label3;
@property (nonatomic, strong) UILabel *label4;
@property (nonatomic, strong) UILabel *label5;
@property (nonatomic, strong) UILabel *label6;
@property (nonatomic, strong) UILabel *label7;
@property (nonatomic, strong) UILabel *label8;
@property (nonatomic, retain) NSString *strr;
- (id)initWithFrame:(CGRect)frame str:(NSString *)strrrrrrr;
- (void)refreshSubViews;

@end
