//
//  PooSegView.m
//  ddddddd
//
//  Created by 邓杰豪 on 15/8/11.
//  Copyright (c) 2015年 邓杰豪. All rights reserved.
//

#import "PooSegView.h"
#import <Masonry/Masonry.h>

#define ButtonTag 2000
#define UnderLabelTag 1000
#define VerLineTag 3000

@interface PooSegView()

@property (nonatomic, copy) PooSegViewClickBlock clickBlock;
@property (nonatomic, strong) NSArray *titlesArr;
@property (nonatomic, strong) UIButton *selectedBtn;
@property (nonatomic, strong) UIColor *titleNormalColor;
@property (nonatomic, strong) UIColor *titleSelectedColor;
@property (nonatomic, strong) UIFont *titleFont;
@property (nonatomic, assign) BOOL setLines;
@property (nonatomic, strong) UIColor *lineColor;
@property (nonatomic, assign) float linesWidth;
@property (nonatomic, strong) UIColor *selectedBackgroundColor;
@property (nonatomic, strong) UIColor *normalBackgroundColor;
@property (nonatomic, assign) PooSegShowType showViewType;

@end

@implementation PooSegView
-(id)initWithTitles:(NSArray *)titleArr titleNormalColor:(UIColor *)nColor titleSelectedColor:(UIColor *)sColor titleFont:(UIFont *)tFont setLine:(BOOL)yesORno lineColor:(UIColor *)lColor lineWidth:(float)lWidth selectedBackgroundColor:(UIColor *)sbc normalBackgroundColor:(UIColor *)nbc showType:(PooSegShowType)viewType clickBlock:(PooSegViewClickBlock)block
{
    self = [super init];
    if (self)
    {
        self.clickBlock = block;
        self.titlesArr = titleArr;
        self.titleNormalColor = nColor;
        self.titleSelectedColor = sColor;
        self.titleFont = tFont;
        self.setLines = yesORno;
        self.lineColor = lColor;
        self.linesWidth = lWidth;
        self.selectedBackgroundColor = sbc;
        self.normalBackgroundColor = nbc;
        self.showViewType = viewType;
        [self initUI];
    }
    return self;
}

-(void)initUI
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        for (int i= 0; i < self.titlesArr.count; i++)
        {
            UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
            btn.frame = CGRectMake(self.frame.size.width/self.titlesArr.count*i, 0, self.frame.size.width/self.titlesArr.count, self.frame.size.height);
            btn.tag = ButtonTag+i;
            [btn setTitleColor:self.titleNormalColor forState:UIControlStateNormal];
            [btn setTitleColor:self.titleSelectedColor forState:UIControlStateSelected];
            btn.titleLabel.font = self.titleFont;
            [btn setTitle:self.titlesArr[i] forState:UIControlStateNormal];
            [self addSubview:btn];
            [btn addTarget:self action:@selector(btnTap:) forControlEvents:UIControlEventTouchUpInside];
            if (i == 0)
            {
                [self btnTap:btn];
            }
            
            UIView *underLIneView = [[UIView alloc] initWithFrame:CGRectMake(self.frame.size.width/self.titlesArr.count*i, self.frame.size.height-2, self.frame.size.width/self.titlesArr.count, 2)];
            underLIneView.tag = UnderLabelTag+i;
            if (i == 0)
            {
                underLIneView.backgroundColor = self.titleSelectedColor;
            }
            [self addSubview:underLIneView];
            switch (self.showViewType)
            {
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
        
        if (self.setLines)
        {
            int a = 1;
            int b = [[NSString stringWithFormat:@"%ld",(unsigned long)self.titlesArr.count] intValue];
            int c = b - a;
            for (int i= c; i < self.titlesArr.count; i++) {
                UIView *line = [[UIView alloc] initWithFrame:CGRectMake(self.frame.size.width/self.titlesArr.count*i-self.linesWidth/2, 0, self.linesWidth, self.frame.size.height)];
                line.tag = VerLineTag+i;
                line.backgroundColor = self.lineColor;
                [self addSubview:line];
            }
        }
    });
}

-(void)layoutSubviews
{
    [super layoutSubviews];
    
    for (int i= 0; i < self.titlesArr.count; i++)
    {
        UIButton *button = (UIButton *)[self viewWithTag:ButtonTag+i];
        [button mas_updateConstraints:^(MASConstraintMaker *make) {
            make.left.offset(self.frame.size.width/self.titlesArr.count*i);
            make.top.bottom.equalTo(self);
            make.width.offset(self.frame.size.width/self.titlesArr.count);
        }];
        
        UIView *underLine = (UIView *)[self viewWithTag:UnderLabelTag+i];
        [underLine mas_updateConstraints:^(MASConstraintMaker *make) {
            make.left.offset(self.frame.size.width/self.titlesArr.count*i);
            make.height.offset(2);
            make.bottom.equalTo(self);
            make.width.offset(self.frame.size.width/self.titlesArr.count);
        }];
        switch (self.showViewType)
        {
            case PooSegShowTypeUnderLine:
            {
                underLine.hidden = NO;
            }
                break;
            default:
            {
                underLine.hidden = YES;
            }
                break;
        }
    }
    
    if (self.setLines)
    {
        int a = 1;
        int b = [[NSString stringWithFormat:@"%ld",(unsigned long)self.titlesArr.count] intValue];
        int c = b - a;
        for (int i= c; i < self.titlesArr.count; i++) {
            UIView *line = (UIView *)[self viewWithTag:VerLineTag+i];
            [line mas_updateConstraints:^(MASConstraintMaker *make) {
                make.left.offset(self.frame.size.width/self.titlesArr.count*i-self.linesWidth/2);
                make.top.bottom.equalTo(self);
                make.width.offset(self.linesWidth);
            }];
        }
    }

}

-(void)btnTap:(UIButton *)sender
{
    if (self.selectedBtn == sender)
    {
        return;
    }
    if (self.normalBackgroundColor)
    {
        switch (self.showViewType)
        {
            case PooSegShowTypeUnderLine:
            {
                UIView *underLineV = [self viewWithTag:UnderLabelTag+(sender.tag-ButtonTag)];
                underLineV.backgroundColor = self.normalBackgroundColor;
            }
                break;
            default:
            {
                [self.selectedBtn setBackgroundColor:self.normalBackgroundColor];
            }
                break;
        }
    }
    else
    {
        switch (self.showViewType)
        {
            case PooSegShowTypeUnderLine:
            {
                UIView *underLineV = [self viewWithTag:UnderLabelTag+(sender.tag-ButtonTag)];
                underLineV.backgroundColor = [UIColor clearColor];
            }
                break;
            default:
            {
                [self.selectedBtn setBackgroundColor:[UIColor clearColor]];
            }
                break;
        }
    }
    self.selectedBtn.selected = NO;
    sender.selected = YES;
    self.selectedBtn = sender;
    if (self.selectedBackgroundColor)
    {
        switch (self.showViewType)
        {
            case PooSegShowTypeUnderLine:
            {
                UIView *underLineV = [self viewWithTag:UnderLabelTag+(sender.tag-ButtonTag)];
                underLineV.backgroundColor = self.selectedBackgroundColor;
            }
                break;
            default:
            {
                [self.selectedBtn setBackgroundColor:self.selectedBackgroundColor];
            }
                break;
        }
    }
    else
    {
        switch (self.showViewType)
        {
            case PooSegShowTypeUnderLine:
            {
                UIView *underLineV = [self viewWithTag:UnderLabelTag+(sender.tag-ButtonTag)];
                underLineV.backgroundColor = [UIColor clearColor];
            }
                break;
            default:
            {
                [self.selectedBtn setBackgroundColor:[UIColor clearColor]];
            }
                break;
        }
    }
    
    for (int i= 0; i < self.titlesArr.count; i++)
    {
        UIView *underLineV = [self viewWithTag:UnderLabelTag+i];
        if (sender.selected)
        {
            if (underLineV.tag == UnderLabelTag+(sender.tag-ButtonTag))
            {
                underLineV.backgroundColor = self.selectedBackgroundColor;
            }
            else
            {
                underLineV.backgroundColor = [UIColor clearColor];
            }
        }
    }
    
    if (self.clickBlock)
    {
        self.clickBlock(self, (sender.tag-ButtonTag));
    }
}
@end
