//
//  PooSegView.m
//  ddddddd
//
//  Created by 邓杰豪 on 15/8/11.
//  Copyright (c) 2015年 邓杰豪. All rights reserved.
//

#import "PooSegView.h"

@interface PooSegView()
{
    NSArray *titlesArr;
    UIButton *selectedBtn;
    UIColor *titleNormalColor;
    UIColor *titleSelectedColor;
    UIFont *titleFont;
    BOOL setLines;
    UIColor *lineColor;
    float linesWidth;
    
    UIColor *selectedBackgroundColor;
    UIColor *normalBackgroundColor;
    
    PooSegShowType showViewType;
}
@property (nonatomic, copy) PooSegViewClickBlock clickBlock;

@end

@implementation PooSegView
-(id)initWithFrame:(CGRect)frame titles:(NSArray *)titleArr titleNormalColor:(UIColor *)nColor titleSelectedColor:(UIColor *)sColor titleFont:(UIFont *)tFont setLine:(BOOL)yesORno lineColor:(UIColor *)lColor lineWidth:(float)lWidth selectedBackgroundColor:(UIColor *)sbc normalBackgroundColor:(UIColor *)nbc showType:(PooSegShowType)viewType clickBlock:(PooSegViewClickBlock)block
{
    self = [super initWithFrame:frame];
    if (self) {
        
        self.clickBlock = block;
        
        titlesArr = titleArr;
        titleNormalColor = nColor;
        titleSelectedColor = sColor;
        titleFont = tFont;
        setLines = yesORno;
        lineColor = lColor;
        linesWidth = lWidth;
        selectedBackgroundColor = sbc;
        normalBackgroundColor = nbc;
        showViewType = viewType;
        [self initUI];
    }
    return self;
}

-(void)initUI
{
    for (int i= 0; i < titlesArr.count; i++) {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        btn.frame = CGRectMake(self.frame.size.width/titlesArr.count*i, 0, self.frame.size.width/titlesArr.count, self.frame.size.height);
        btn.tag = i;
        [btn setTitleColor:titleNormalColor forState:UIControlStateNormal];
        [btn setTitleColor:titleSelectedColor forState:UIControlStateSelected];
        btn.titleLabel.font = titleFont;
        [btn setTitle:titlesArr[i] forState:UIControlStateNormal];
        [self addSubview:btn];
        [btn addTarget:self action:@selector(btnTap:) forControlEvents:UIControlEventTouchUpInside];
        if (i == 0) {
            [self btnTap:btn];
        }
        
        UIView *underLIneView = [[UIView alloc] initWithFrame:CGRectMake(self.frame.size.width/titlesArr.count*i, self.frame.size.height-2, self.frame.size.width/titlesArr.count, 2)];
        underLIneView.tag = 1000+i;
        if (i == 0) {
            underLIneView.backgroundColor = titleSelectedColor;
        }
        [self addSubview:underLIneView];
        switch (showViewType) {
            case PooSegShowTypeUnderLine:
            {
                underLIneView.hidden = NO;
            }
                break;
            default:
            {
                underLIneView.hidden = YES;
            }
                break;
        }

    }
    if (setLines) {
        int a = 1;
        int b = [[NSString stringWithFormat:@"%ld",(unsigned long)titlesArr.count] intValue];
        int c = b - a;
        for (int i= c; i < titlesArr.count; i++) {
            UIView *line = [[UIView alloc] initWithFrame:CGRectMake(self.frame.size.width/titlesArr.count*i-linesWidth/2, 0, linesWidth, self.frame.size.height)];
            line.backgroundColor = lineColor;
            [self addSubview:line];
        }
    }
}

-(void)btnTap:(UIButton *)sender
{
    if (selectedBtn == sender) {
        return;
    }
    if (normalBackgroundColor) {
        
        switch (showViewType) {
            case PooSegShowTypeUnderLine:
            {
                UIView *underLineV = [self viewWithTag:1000+sender.tag];
                underLineV.backgroundColor = normalBackgroundColor;
            }
                break;
            default:
            {
                [selectedBtn setBackgroundColor:normalBackgroundColor];
            }
                break;
        }
    }
    else
    {
        switch (showViewType) {
            case PooSegShowTypeUnderLine:
            {
                UIView *underLineV = [self viewWithTag:1000+sender.tag];
                underLineV.backgroundColor = [UIColor clearColor];
            }
                break;
            default:
            {
                [selectedBtn setBackgroundColor:[UIColor clearColor]];
            }
                break;
        }
    }
    selectedBtn.selected = NO;
    sender.selected = YES;
    selectedBtn = sender;
    if (selectedBackgroundColor) {
        switch (showViewType) {
            case PooSegShowTypeUnderLine:
            {
                UIView *underLineV = [self viewWithTag:1000+sender.tag];
                underLineV.backgroundColor = selectedBackgroundColor;
            }
                break;
            default:
            {
                [selectedBtn setBackgroundColor:selectedBackgroundColor];
            }
                break;
        }
    }
    else
    {
        switch (showViewType) {
            case PooSegShowTypeUnderLine:
            {
                UIView *underLineV = [self viewWithTag:1000+sender.tag];
                underLineV.backgroundColor = [UIColor clearColor];
            }
                break;
            default:
            {
                [selectedBtn setBackgroundColor:[UIColor clearColor]];
            }
                break;
        }
    }
    
    for (int i= 0; i < titlesArr.count; i++) {
        UIView *underLineV = [self viewWithTag:1000+i];
        if (sender.selected) {
            if (underLineV.tag == 1000+sender.tag) {
                underLineV.backgroundColor = selectedBackgroundColor;
            }
            else
            {
                underLineV.backgroundColor = [UIColor clearColor];
            }
        }
    }
    
    if (self.clickBlock) {
        self.clickBlock(self, sender.tag);
    }
}
@end
