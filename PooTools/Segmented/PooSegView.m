//
//  PooSegView.m
//  ddddddd
//
//  Created by 邓杰豪 on 15/8/11.
//  Copyright (c) 2015年 邓杰豪. All rights reserved.
//

#import "PooSegView.h"
#import <Masonry/Masonry.h>
#import "PMacros.h"
#import <WZLBadge/UIView+WZLBadge.h>
#import "UIView+ModifyFrame.h"
#import "UIButton+Block.h"
#import "UIImage+Size.h"
#import "UIButton+ImageTitleSpacing.h"

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
@property (nonatomic, assign) NSInteger firstSelect;
@property (nonatomic, assign) CGFloat btnW;
@property (nonatomic, assign) CGFloat scrollerContentSizeW;
@property (nonatomic, strong) UIScrollView *scroller;
@property (nonatomic, assign) BOOL withBlock;
@property (nonatomic, strong) NSArray *selectedImageArr;
@property (nonatomic, strong) NSArray *normalImageArr;
@end

@implementation PooSegView
-(id)initWithTitles:(NSArray *)titleArr
   titleNormalColor:(UIColor *)nColor
 titleSelectedColor:(UIColor *)sColor
          titleFont:(UIFont *)tFont
            setLine:(BOOL)yesORno
          lineColor:(UIColor *)lColor
          lineWidth:(float)lWidth
selectedBackgroundColor:(UIColor *)sbc
normalBackgroundColor:(UIColor *)nbc
           showType:(PooSegShowType)viewType
   firstSelectIndex:(NSInteger)fSelect
     normalImageArr:(NSArray *)nIArr
   selectedImageArr:(NSArray *)sIArr
         clickBlock:(PooSegViewClickBlock)block
{
    self = [super init];
    if (self)
    {
//        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveNotifi:) name:kReceiveTagBadgeNofitication object:nil];

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
        self.firstSelect = (fSelect > titleArr.count) ? 0 : fSelect;
        self.withBlock = YES;
        self.selectedImageArr = sIArr;
        self.normalImageArr = nIArr;
        [self initUI];
    }
    return self;
}

-(void)initUI
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        self.scroller = [[UIScrollView alloc] initWithFrame:self.bounds];
        self.scroller.showsVerticalScrollIndicator = NO;
        self.scroller.showsHorizontalScrollIndicator = NO;
        [self addSubview:self.scroller];
        self.scroller.scrollEnabled = YES;
                
        self.btnW = 0.0f;
        self.scrollerContentSizeW = 0.0f;
        for (int i= 0; i < self.titlesArr.count; i++)
        {
            UIImage *selectedImage;
            UIImage *normalImage;
            
            CGFloat imageHeight = self.frame.size.height-10;
            CGFloat btnWNormal = [Utils sizeForString:(NSString *)self.titlesArr[i] font:self.titleFont andHeigh:self.frame.size.height andWidth:CGFLOAT_MAX].width+15+imageHeight+5;//[(NSString *)self.titlesArr[i] length] * self.titleFont.pointSize+30.f;
            UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
            btn.frame = CGRectMake(self.scrollerContentSizeW, 0, btnWNormal, self.frame.size.height);
            btn.tag = ButtonTag+i;
            if (kArrayIsEmpty(self.normalImageArr) || kArrayIsEmpty(self.selectedImageArr)) {
                PNSLog(@"没有使用图片");
            }
            else
            {
                if (self.titlesArr.count == self.normalImageArr.count && self.titlesArr.count == self.selectedImageArr.count)
                {
                    selectedImage = kImageNamed(self.selectedImageArr[i]);
                    normalImage = kImageNamed(self.normalImageArr[i]);
                    [btn setImage:[normalImage transformWidth:imageHeight height:imageHeight] forState:UIControlStateNormal];
                    [btn setImage:[selectedImage transformWidth:imageHeight height:imageHeight] forState:UIControlStateSelected];
                }
                else
                {
                    PNSLog(@"图片数量与标题数量不一致");
                }
            }
            [btn setTitleColor:self.titleNormalColor forState:UIControlStateNormal];
            [btn setTitleColor:self.titleSelectedColor forState:UIControlStateSelected];
            btn.titleLabel.font = self.titleFont;
            [btn setTitle:self.titlesArr[i] forState:UIControlStateNormal];
            [btn layoutButtonWithEdgeInsetsStyle:MKButtonEdgeInsetsStyleLeft imageTitleSpace:5];
            [self.scroller addSubview:btn];
//            [btn addTarget:self action:@selector(btnTap:) forControlEvents:UIControlEventTouchUpInside];
            [btn addActionHandler:^(UIButton *sender) {
                self.withBlock = YES;
                [self btnTap:sender];
            }];
            UIView *underLIneView = [[UIView alloc] initWithFrame:CGRectMake(self.scrollerContentSizeW, self.frame.size.height-2, btnWNormal, 2)];
            underLIneView.tag = UnderLabelTag+i;
            if (i == self.firstSelect)
            {
                [self btnTap:btn];
                underLIneView.backgroundColor = self.titleSelectedColor;
            }
            else
            {
                underLIneView.backgroundColor = kClearColor;
            }
            [self.scroller addSubview:underLIneView];
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
            
            if (self.setLines)
            {
                if (self.titlesArr.count > 1) {
                    if (i != 0) {
                        UIView *line = [[UIView alloc] initWithFrame:CGRectMake(self.scrollerContentSizeW-self.linesWidth/2, 0, self.linesWidth, self.frame.size.height)];
                        line.tag = VerLineTag+i;
                        line.backgroundColor = self.lineColor;
                        [self.scroller addSubview:line];

                    }
                }
            }
            self.btnW = btnWNormal;
            self.scrollerContentSizeW = self.scrollerContentSizeW+self.btnW;
        }
        [self setView];
    });
}

-(void)layoutSubviews
{
    [super layoutSubviews];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.scroller.frame = self.bounds;
        self.btnW = 0.0f;
        self.scrollerContentSizeW = 0.0f;
        for (int i= 0; i < self.titlesArr.count; i++)
        {
            CGFloat btnWNormal = [(NSString *)self.titlesArr[i] length] * self.titleFont.pointSize+30.f;
            UIButton *button = (UIButton *)[self viewWithTag:ButtonTag+i];
            button.frame = CGRectMake(self.scrollerContentSizeW, 0, btnWNormal, self.frame.size.height);
            UIView *underLineV = [self viewWithTag:UnderLabelTag+i];
            underLineV.frame = CGRectMake(self.scrollerContentSizeW, self.frame.size.height-2, btnWNormal, 2);
            if (self.setLines)
            {
                if (self.titlesArr.count > 1) {
                    if (i != 0) {
                        UIView *lineV = [self viewWithTag:VerLineTag+i];
                        lineV.frame = CGRectMake(self.scrollerContentSizeW-self.linesWidth/2, 0, self.linesWidth, self.frame.size.height);
                    }
                }
            }
            self.btnW = btnWNormal;
            self.scrollerContentSizeW = self.scrollerContentSizeW+self.btnW;
        }
        [self setView];
    });
}

-(void)setView
{
    if (self.scrollerContentSizeW < self.frame.size.width) {
        for (int i= 0; i < self.titlesArr.count; i++)
        {
            UIButton *button = (UIButton *)[self viewWithTag:ButtonTag+i];
            button.frame = CGRectMake(self.frame.size.width/self.titlesArr.count*i, 0, self.frame.size.width/self.titlesArr.count, self.frame.size.height);
            UIView *underLineV = [self viewWithTag:UnderLabelTag+i];
            underLineV.frame = CGRectMake(self.frame.size.width/self.titlesArr.count*i, self.frame.size.height-2, self.frame.size.width/self.titlesArr.count, 2);
        }
    }
    else
    {
        self.scroller.contentSize = CGSizeMake(self.scrollerContentSizeW, self.frame.size.height);
        UIButton *button = (UIButton *)[self viewWithTag:ButtonTag+self.firstSelect];
        UIButton *button1 = (UIButton *)[self viewWithTag:ButtonTag+self.firstSelect+1];
        
        [self.scroller scrollRectToVisible:CGRectMake(button.frame.origin.x+button1.frame.size.width/2, 0, button.frame.size.width, self.frame.size.height) animated:YES];
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
                underLineV.backgroundColor = kClearColor;
            }
                break;
            default:
            {
                [self.selectedBtn setBackgroundColor:kClearColor];
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
                underLineV.backgroundColor = kClearColor;
            }
                break;
            default:
            {
                [self.selectedBtn setBackgroundColor:kClearColor];
            }
                break;
        }
    }
    
    switch ((sender.tag - ButtonTag)) {
        case 0:
            {
                [self.scroller scrollRectToVisible:CGRectMake(0, 0, sender.frame.size.width, self.frame.size.height) animated:YES];
            }
            break;
        default:
        {
            UIButton *button1 = (UIButton *)[self viewWithTag:sender.tag+1];
            [self.scroller scrollRectToVisible:CGRectMake(sender.frame.origin.x+button1.frame.size.width/2, 0, sender.frame.size.width, self.frame.size.height) animated:YES];
        }
            break;
    }

    for (int i= 0; i < self.titlesArr.count; i++)
    {
        UIView *underLineV = [self viewWithTag:UnderLabelTag+i];
        if (sender.selected)
        {
            if (underLineV.tag == UnderLabelTag+(sender.tag-ButtonTag))
            {
                underLineV.backgroundColor = self.titleSelectedColor;
            }
            else
            {
                underLineV.backgroundColor = kClearColor;
            }
        }
    }
    
    if (self.withBlock)
    {
        if (self.clickBlock)
        {
            self.clickBlock(self, (sender.tag-ButtonTag));
        }
    }
}

-(void)setSegCurrentIndex:(NSInteger)index withBlock:(BOOL)block
{
    self.withBlock = block;
    self.firstSelect = index;
    UIButton *button = (UIButton *)[self viewWithTag:ButtonTag+index];
    [self btnTap:button];
}

-(void)setSegBadgeAtIndex:(NSInteger)index where:(PooSegBadgeShowType)type
{
    GCDAfter(0.1, ^{
        UIButton *btn = [self viewWithTag:ButtonTag + index];
        btn.badgeBgColor = [UIColor redColor];
        CGPoint badgePoint;
        switch (type) {
                case PooSegBadgeShowTypeTopLeft:
            {
                badgePoint = CGPointMake(-btn.width+5, -5);
            }
                break;
                case PooSegBadgeShowTypeTopMiddle:
            {
                badgePoint = CGPointMake(-(btn.width/2), 5);
            }
                break;
                case PooSegBadgeShowTypeTopRight:
            {
                badgePoint = CGPointMake(0, -5);
            }
                break;
                case PooSegBadgeShowTypeMiddleLeft:
            {
                badgePoint = CGPointMake(-btn.width+5, btn.height/2);
            }
                break;
                case PooSegBadgeShowTypeMiddleRight:
            {
                badgePoint = CGPointMake(-5, btn.height/2);
            }
                break;
                case PooSegBadgeShowTypeBottomLeft:
            {
                badgePoint = CGPointMake(-btn.width+5, btn.height-5);
            }
                break;
                case PooSegBadgeShowTypeBottomMiddle:
            {
                badgePoint = CGPointMake(-(btn.width/2), btn.height-5);
            }
                break;
                case PooSegBadgeShowTypeBottomRight:
            {
                badgePoint = CGPointMake(-5, btn.height-5);
            }
                break;
            default:
            {
                badgePoint = CGPointMake(0, 0);
            }
                break;
        }
        btn.badgeCenterOffset = badgePoint;
        [btn showBadgeWithStyle:WBadgeStyleRedDot value:1 animationType:WBadgeAnimTypeBreathe];
    });
}

-(void)removeSegBadgeAtIndex:(NSInteger)index
{
    GCDAfter(0.1, ^{
        UIButton *btn = [self viewWithTag:ButtonTag + index];
        [btn clearBadge];
    });
}

-(void)removeAllSegBadgeAtIndex
{
    GCDAfter(0.1, ^{
        for (int i = 0; i < self.titlesArr.count; i++) {
            UIButton *btn = [self viewWithTag:ButtonTag + i];
            [btn clearBadge];
        }
    });
}

@end
