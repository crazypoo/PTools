//
//  PooNumberKeyBoard.m
//  numKeyBoard
//
//  Created by crazypoo on 14-4-3.
//  Copyright (c) 2014年 crazypoo. All rights reserved.
//

#import "PooNumberKeyBoard.h"
#import <Masonry/Masonry.h>
#import "PMacros.h"
#import "Utils.h"

#define kLineWidth 1
#define kNumFont [UIFont systemFontOfSize:27]
#define kKeyBoardH 216
#define kKeyH (self.bounds.size.height- kLineWidth*3)/4
#define kKeyW (self.bounds.size.width-2)/3

@interface PooNumberKeyBoard()
@property (nonatomic, copy) PooNumberKeyBoardBackSpace backSpaceBlock;
@property (nonatomic, copy) PooNumberKeyBoardReturnSTH returnSTHBlock;
@property (nonatomic, assign) PKeyboardType keyboardType;

@end

@implementation PooNumberKeyBoard

+(instancetype)pooNumberKeyBoardWithType:(PKeyboardType)keyboardType
{
    return [[PooNumberKeyBoard alloc] initWithType:keyboardType backSpace:nil returnSTH:nil];
}

+(instancetype)pooNumberKeyBoardWithType:(PKeyboardType)keyboardType backSpace:(PooNumberKeyBoardBackSpace)backSpaceBlock returnSTH:(PooNumberKeyBoardReturnSTH)returnSTHBlock
{
    return [[PooNumberKeyBoard alloc] initWithType:keyboardType backSpace:backSpaceBlock returnSTH:returnSTHBlock];
}

- (id)initWithType:(PKeyboardType)keyboardType backSpace:(PooNumberKeyBoardBackSpace)backSpaceBlock returnSTH:(PooNumberKeyBoardReturnSTH)returnSTHBlock
{
    self = [super init];
    if (self) {
        self.keyboardType = keyboardType;
        
        self.returnSTHBlock = returnSTHBlock;
        self.backSpaceBlock = backSpaceBlock;

        self.bounds = CGRectMake(0, 0, kSCREEN_WIDTH, kKeyBoardH);
        
        UIColor *colorNormal = [UIColor colorWithRed:252/255.0 green:252/255.0 blue:252/255.0 alpha:1];
        UIColor *colorHightlighted = [UIColor colorWithRed:186.0/255 green:189.0/255 blue:194.0/255 alpha:1.0];

        for (int i = 0; i<4; i++)
        {
            for (int j = 0; j<3; j++)
            {
                UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
                button.tag = j+3*i+1;
                [button addTarget:self action:@selector(clickButton:) forControlEvents:UIControlEventTouchUpInside];
                [self addSubview:button];
                [button mas_makeConstraints:^(MASConstraintMaker *make) {
                    make.height.offset(kKeyH);
                    make.width.offset(kKeyW);
                    make.top.offset(kKeyH*i+i*kLineWidth);
                    make.left.offset(kKeyW*j);
                }];
                
                UIColor *cN;
                UIColor *cH;
                if (button.tag == 10 || button.tag == 12)
                {
                    cN = colorHightlighted;
                    cH = colorNormal;
                }
                else
                {
                    cN = colorNormal;
                    cH = colorHightlighted;
                }

                button.titleLabel.font = kNumFont;
                [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
                if (button.tag < 10) {
                    [button setTitle:[NSString stringWithFormat:@"%d",j+3*i+1] forState:UIControlStateNormal];
                }
                else if (button.tag == 11)
                {
                    [button setTitle:@"0" forState:UIControlStateNormal];
                }
                else if (button.tag == 10)
                {
                    switch (self.keyboardType) {
                        case PKeyboardTypeCall:
                            {
                                [button setTitle:@"+" forState:UIControlStateNormal];
                            }
                            break;
                        case PKeyboardTypePoint:
                        {
                            [button setTitle:@"." forState:UIControlStateNormal];
                        }
                            break;
                        case PKeyboardTypeInputID:
                        {
                            [button setTitle:@"X" forState:UIControlStateNormal];
                        }
                            break;
                        default:
                        {
                            [button setTitle:@"" forState:UIControlStateNormal];
                        }
                            break;
                    }
                }
                else
                {
                    [button setTitle:@"刪除" forState:UIControlStateNormal];
                }
                [button setBackgroundImage:[Utils createImageWithColor:cN] forState:UIControlStateNormal];
                [button setBackgroundImage:[Utils createImageWithColor:cH] forState:UIControlStateHighlighted];
            }
        }
        
        UIColor *color = [UIColor colorWithRed:188/255.0 green:192/255.0 blue:199/255.0 alpha:1];
        
        for (int i = 1 ; i < 3; i++) {
            UIView *line1 = [UIView new];
            line1.backgroundColor = color;
            line1.tag = 1000+i;
            [self addSubview:line1];
            [line1 mas_makeConstraints:^(MASConstraintMaker *make) {
                make.left.equalTo(self).offset(kKeyW * i);
                make.width.offset(kLineWidth);
                make.height.offset(self.bounds.size.height);
                make.top.equalTo(self);
            }];
        }
        
        for (int i = 1; i < 4; i++)
        {
            UIView *line = [UIView new];
            line.backgroundColor = color;
            line.tag = 2000+i;
            [self addSubview:line];
            [line mas_makeConstraints:^(MASConstraintMaker *make) {
                make.left.equalTo(self);
                make.width.offset(self.bounds.size.width);
                make.height.offset(kLineWidth);
                make.top.offset(kKeyH*i+i*kLineWidth);
            }];
        }
    }
    return self;
}

-(void)layoutSubviews
{
    [super layoutSubviews];
    for (int i = 0; i<4; i++)
    {
        for (int j = 0; j<3; j++)
        {
            UIButton *button = (UIButton *)[self viewWithTag:j+3*i+1];
            [button mas_updateConstraints:^(MASConstraintMaker *make) {
                make.height.offset(kKeyH);
                make.width.offset(kKeyW);
                make.top.offset(kKeyH*i+i*kLineWidth);
                make.left.offset(kKeyW*j);
            }];
        }
    }
    for (int i = 1 ; i < 3; i++) {
        UIView *line1 = (UIView *)[self viewWithTag:1000+i];
        [line1 mas_updateConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self).offset(kKeyW * i);
            make.width.offset(kLineWidth);
            make.height.offset(self.bounds.size.height);
            make.top.equalTo(self);
        }];
    }
    
    for (int i = 1; i < 4; i++)
    {
        UIView *line = (UIView *)[self viewWithTag:2000+i];
        [line mas_updateConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self);
            make.width.offset(self.bounds.size.width);
            make.height.offset(kLineWidth);
            make.top.offset(kKeyH*i+i*kLineWidth);
        }];
    }
}

-(void)clickButton:(UIButton *)sender
{
    if(sender.tag == 12)
    {
        if ([self.delegate respondsToSelector:@selector(numberKeyboardBackspace:)]) {
            [self.delegate numberKeyboardBackspace:self];
        }
        else
        {
            if (self.backSpaceBlock) {
                self.backSpaceBlock(self);
            }
        }
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
            switch (self.keyboardType)
            {
                case PKeyboardTypeCall:
                {
                    num = @"+";
                }
                    break;
                case PKeyboardTypePoint:
                {
                    num = @".";
                }
                    break;
                case PKeyboardTypeInputID:
                {
                    num = @"X";
                }
                    break;
                default:
                {
                    num = @"";
                }
                    break;
            }
        }
        if ([self.delegate respondsToSelector:@selector(numberKeyboard:input:)]) {
            [self.delegate numberKeyboard:self input:num];
        }
        else
        {
            if (self.returnSTHBlock) {
                self.returnSTHBlock(self, num);
            }
        }
    }
}
@end

