//
//  PooNumberKeyBoard.m
//  numKeyBoard
//
//  Created by crazypoo on 14-4-3.
//  Copyright (c) 2014年 crazypoo. All rights reserved.
//

#import "PooNumberKeyBoard.h"
#define kLineWidth 1
#define kNumFont [UIFont systemFontOfSize:27]
#define DefaultFrame CGRectMake(0, 200, [UIScreen mainScreen].bounds.size.width, 216)

@implementation PooNumberKeyBoard

+(instancetype)pooNumberKeyBoardWithDog:(BOOL)dogpoint
{
    return [[PooNumberKeyBoard alloc] initWithFrame:DefaultFrame withDog:dogpoint];
}

- (id)initWithFrame:(CGRect)frame withDog:(BOOL)dog
{
    self = [super initWithFrame:frame];
    if (self) {
        self.haveDog = dog;
        self.bounds = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 216);
        for (int i=0; i<4; i++)
        {
            for (int j=0; j<3; j++)
            {
                UIButton *button = [self creatButtonWithX:i Y:j withDog:dog];
                [self addSubview:button];
            }
        }
        UIColor *color = [UIColor colorWithRed:188/255.0 green:192/255.0 blue:199/255.0 alpha:1];
        UIView *line1 = [[UIView alloc] initWithFrame:CGRectMake(([UIScreen mainScreen].bounds.size.width-2)/3, 0, kLineWidth, 216)];
        line1.backgroundColor = color;
        [self addSubview:line1];
        UIView *line2 = [[UIView alloc] initWithFrame:CGRectMake(([UIScreen mainScreen].bounds.size.width-2)/3*2, 0, kLineWidth, 216)];
        line2.backgroundColor = color;
        [self addSubview:line2];
        for (int i=0; i<3; i++)
        {
            UIView *line = [[UIView alloc] initWithFrame:CGRectMake(0, 54*(i+1), [UIScreen mainScreen].bounds.size.width, kLineWidth)];
            line.backgroundColor = color;
            [self addSubview:line];
        }
    }
    return self;
}

-(UIButton *)creatButtonWithX:(NSInteger) x Y:(NSInteger) y withDog:(BOOL)dog
{
    UIButton *button;
    CGFloat frameX = 0.0;
    CGFloat frameW = 0.0;
    switch (y)
    {
        case 0:
            frameX = 0.0;
            frameW = ([UIScreen mainScreen].bounds.size.width-2)/3;
            break;
        case 1:
            frameX = ([UIScreen mainScreen].bounds.size.width-2)/3;
            frameW = ([UIScreen mainScreen].bounds.size.width-2)/3;
            break;
        case 2:
            frameX = ([UIScreen mainScreen].bounds.size.width-2)/3*2;
            frameW = ([UIScreen mainScreen].bounds.size.width-2)/3;
            break;

        default:
            break;
    }
    CGFloat frameY = 54*x;
    button = [[UIButton alloc] initWithFrame:CGRectMake(frameX, frameY, frameW, 54)];
    NSInteger num = y+3*x+1;
    button.tag = num;
    [button addTarget:self action:@selector(clickButton:) forControlEvents:UIControlEventTouchUpInside];

    UIColor *colorNormal = [UIColor colorWithRed:252/255.0 green:252/255.0 blue:252/255.0 alpha:1];
    UIColor *colorHightlighted = [UIColor colorWithRed:186.0/255 green:189.0/255 blue:194.0/255 alpha:1.0];

    if (num == 10 || num == 12)
    {
        UIColor *colorTemp = colorNormal;
        colorNormal = colorHightlighted;
        colorHightlighted = colorTemp;
    }
    button.backgroundColor = colorNormal;
    CGSize imageSize = CGSizeMake(frameW, 54);
    UIGraphicsBeginImageContextWithOptions(imageSize, 0, [UIScreen mainScreen].scale);
    [colorHightlighted set];
    UIRectFill(CGRectMake(0, 0, imageSize.width, imageSize.height));
    UIImage *pressedColorImg = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    [button setImage:pressedColorImg forState:UIControlStateHighlighted];


    if (num<10)
    {
        UILabel *labelNum = [[UILabel alloc] initWithFrame:CGRectMake(0, 15, frameW, 28)];
        labelNum.text = [NSString stringWithFormat:@"%ld",(long)num];
        labelNum.textColor = [UIColor blackColor];
        labelNum.textAlignment = NSTextAlignmentCenter;
        labelNum.font = kNumFont;
        [button addSubview:labelNum];
    }
    else if (num == 11)
    {
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 15, frameW, 28)];
        label.text = @"0";
        label.textColor = [UIColor blackColor];
        label.textAlignment = NSTextAlignmentCenter;
        label.font = kNumFont;
        [button addSubview:label];
    }
    else if (num == 10)
    {
        if (dog) {
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 15, frameW, 28)];
            label.text = @".";
            label.textColor = [UIColor blackColor];
            label.textAlignment = NSTextAlignmentCenter;
            label.font = kNumFont;
            [button addSubview:label];
        }
    }
    else
    {
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 15, frameW, 28)];
        label.text = @"刪除";
        label.textColor = [UIColor blackColor];
        label.textAlignment = NSTextAlignmentCenter;
        label.font = kNumFont;
        [button addSubview:label];
    }
    return button;
}

-(void)clickButton:(UIButton *)sender
{
    if(sender.tag == 12)
    {
        [self.delegate numberKeyboardBackspace:self];
    }
    else
    {
        NSString *num = [NSString stringWithFormat:@"%ld",(long)sender.tag];
        if (sender.tag == 11)
        {
            num = @"0";
        }
        else if (sender.tag == 10)
        {
            if (self.haveDog) {
                num = @".";
            }
            else
            {
                num = @"";
            }
        }
        [self.delegate numberKeyboard:self input:num];

    }
}

@end

