//
//  PooTagsLabel.m
//  XMNiao_Shop
//
//  Created by MYX on 2017/3/16.
//  Copyright © 2017年 邓杰豪. All rights reserved.
//

#import "PooTagsLabel.h"
#import "PMacros.h"
#import "Utils.h"

#define BTN_Tags_Tag        784843

@implementation PooTagsLabelConfig
@end

@interface PooTagsLabel ()
@property (nonatomic,strong) PooTagsLabelConfig *curConfig;
@property (nonatomic,strong) NSArray *normalTagsArr;
@property (nonatomic,assign) BOOL showImage;
@property (nonatomic,assign) CGFloat viewW;
@end

@implementation PooTagsLabel

-(instancetype)initWithTagsNormalArray:(NSArray *)tagsNormalArr tagsSelectArray:(NSArray *)tagsSelectArr tagsTitleArray:(NSArray *)tagsTitleArr config:(PooTagsLabelConfig *)config wihtSection:(NSInteger)sectionIndex
{
    if (self = [super init])
    {
        for (UIView *subView in self.subviews)
        {
            [subView removeFromSuperview];
        }
        
        self.tag = sectionIndex;
        self.showImage = YES;
        self.normalTagsArr = tagsNormalArr;
        _curConfig = config;
        _multiSelectedTags = [NSMutableArray array];
        if (config.selectedDefaultTags.count)
        {
            [_multiSelectedTags addObjectsFromArray:config.selectedDefaultTags];
        }
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            UIImageView *bgImageView = [UIImageView new];
            bgImageView.userInteractionEnabled = YES;
            self.bgImageView = bgImageView;
            [self addSubview:bgImageView];
            
            CGRect lastBtnRect = CGRectZero;
            CGFloat hMargin = 0.0, orgin_Y = 0.0, itemContentMargin = config.itemContentEdgs > 0 ? config.itemContentEdgs : 10.0, topBottomSpace = (config.topBottomSpace > 0 ? config.topBottomSpace : 15.0);
            
            UIFont *font = [UIFont fontWithName:config.fontName ? config.fontName:@"HelveticaNeue-Medium" size:config.fontSize > 0 ? config.fontSize : 12.0];
            
            for (int i = 0; i < tagsNormalArr.count; i++)
            {
                UIImage *normalImage = kImageNamed(tagsNormalArr[i]);
                NSString *title = tagsTitleArr[i];
                
                CGFloat titleWidth = config.itemWidth;
                
                if ((CGRectGetMaxX(lastBtnRect) + config.itemHerMargin + titleWidth + 2 * itemContentMargin) > CGRectGetWidth(self.frame))
                {
                    lastBtnRect.origin.x = 0.0;
                    hMargin = 0.0;
                    lastBtnRect.size.width = 0.0;
                    orgin_Y += (config.itemHeight + config.itemVerMargin);
                }

                UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(hMargin + CGRectGetMaxX(lastBtnRect), topBottomSpace + orgin_Y, config.itemWidth, config.itemHeight)];
                lastBtnRect = btn.frame;
                hMargin = config.itemHerMargin;
                btn.tag = BTN_Tags_Tag + i;
                
                ///标题设置
                switch (config.showStatus) {
                    case PooTagsLabelShowWithImageStatusNoTitle:
                    {
                        [btn setTitleColor:kClearColor forState:UIControlStateNormal];
                        [btn setTitle:title forState:UIControlStateNormal];
                        [btn setBackgroundImage:normalImage forState:UIControlStateNormal];
                        [btn setBackgroundImage:kImageNamed(tagsSelectArr[i]) forState:UIControlStateSelected];
                    }
                        break;
                    default:
                    {
                        UIColor *normorTitleColor = config.normalTitleColor ? config.normalTitleColor : [UIColor grayColor];
                        UIColor *selectedTitleColor = config.selectedTitleColor ? config.selectedTitleColor : [UIColor greenColor];
                        
                        [btn setTitleColor:normorTitleColor forState:UIControlStateNormal];
                        [btn setTitleColor:selectedTitleColor forState:UIControlStateSelected];
                        [btn setTitle:title forState:UIControlStateNormal];
                        [btn setTitle:title forState:UIControlStateSelected];
                        [btn setImage:normalImage forState:UIControlStateNormal];
                        [btn setImage:kImageNamed(tagsSelectArr[i]) forState:UIControlStateSelected];
                        [btn layoutButtonWithEdgeInsetsStyle:config.insetsStyle imageTitleSpace:config.imageAndTitleSpace];
                    }
                        break;
                }
                
                btn.backgroundColor = config.backgroundColor ? config.backgroundColor : kClearColor;
                btn.titleLabel.font = font;
                [btn addTarget:self action:@selector(tagBtnAction:) forControlEvents:UIControlEventTouchUpInside];
                
                CGRect frame = self.frame;
                frame.size.height = CGRectGetMaxY(btn.frame) + topBottomSpace;
                self.frame = frame;
                self.bgImageView.frame = self.bounds;
                
                ///边框
                if (config.hasBorder)
                {
                    btn.clipsToBounds = YES;
                    btn.layer.cornerRadius = config.cornerRadius > 0 ? config.cornerRadius : config.itemHeight / 2.0;
                    btn.layer.borderColor = config.borderColor.CGColor;
                    btn.layer.borderWidth = config.borderWidth > 0.0 ? config.borderWidth : 0.5;
                }
                
                ///可选中
                if (config.isCanSelected)
                {
                    //多选
                    if (config.isMulti)
                    {
                        for (NSString *str in config.selectedDefaultTags)
                        {
                            if ([title isEqualToString:str])
                            {
                                btn.selected = YES;
                            }
                        }
                    }
                    else
                    {  //单选
                        if ([title isEqualToString:config.singleSelectedTitle])
                        {
                            btn.selected = YES;
                            self.selectedBtn = btn;
                        }
                    }
                }
                else
                {  //不可选中
                    btn.enabled = NO;
                }
                
                [self addSubview:btn];
            }
            if (self.tagHeightBlock) {
                self.tagHeightBlock(self, self.frame.size.height);
            }
        });
    }
    return self;
}

-(instancetype)initWithTagsArray:(NSArray *)tagsArr config:(PooTagsLabelConfig *)config wihtSection:(NSInteger)sectionIndex
{
    
    if (self = [super init])
    {
        for (UIView *subView in self.subviews)
        {
            [subView removeFromSuperview];
        }
        
        self.tag = sectionIndex;
        self.showImage = NO;
        self.normalTagsArr = tagsArr;
        _curConfig = config;
        _multiSelectedTags = [NSMutableArray array];
        if (config.selectedDefaultTags.count)
        {
            [_multiSelectedTags addObjectsFromArray:config.selectedDefaultTags];
        }
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            UIImageView *bgImageView = [UIImageView new];
            bgImageView.userInteractionEnabled = YES;
            self.bgImageView = bgImageView;
            [self addSubview:bgImageView];
            
            CGRect lastBtnRect = CGRectZero;
            CGFloat hMargin = 0.0, orgin_Y = 0.0, itemContentMargin = config.itemContentEdgs > 0 ? config.itemContentEdgs : 10.0, topBottomSpace = (config.topBottomSpace > 0 ? config.topBottomSpace : 15.0);
            
            UIFont *font = [UIFont fontWithName:config.fontName ? config.fontName:@"HelveticaNeue-Medium" size:config.fontSize > 0 ? config.fontSize : 12.0];
            
            for (int i = 0; i < tagsArr.count; i++)
            {
                NSString *title = tagsArr[i];
                CGFloat titleWidth = [title sizeWithAttributes:@{NSFontAttributeName : font}].width;
                
                if ((CGRectGetMaxX(lastBtnRect) + config.itemHerMargin + titleWidth + 2 * itemContentMargin) > CGRectGetWidth(self.frame))
                {
                    lastBtnRect.origin.x = 0.0;
                    hMargin = 0.0;
                    lastBtnRect.size.width = 0.0;
                    orgin_Y += (config.itemHeight + config.itemVerMargin);
                }
                
                UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(hMargin + CGRectGetMaxX(lastBtnRect), topBottomSpace + orgin_Y, titleWidth+2*itemContentMargin, config.itemHeight)];
                lastBtnRect = btn.frame;
                hMargin = config.itemHerMargin;
                btn.tag = BTN_Tags_Tag + i;
                
                ///标题设置
                UIColor *normorTitleColor = config.normalTitleColor ? config.normalTitleColor : [UIColor grayColor];
                UIColor *selectedTitleColor = config.selectedTitleColor ? config.selectedTitleColor : [UIColor greenColor];
                [btn setTitle:title forState:UIControlStateNormal];
                [btn setTitleColor:normorTitleColor forState:UIControlStateNormal];
                [btn setTitleColor:selectedTitleColor forState:UIControlStateSelected];
                
                ///图片设置
                if (config.normalBgImage)
                {
                    [btn setBackgroundImage:[UIImage imageNamed:config.normalBgImage] forState:UIControlStateNormal];
                }
                if (config.selectedBgImage)
                {
                    [btn setBackgroundImage:[UIImage imageNamed:config.selectedBgImage] forState:UIControlStateSelected];
                }
                
                btn.backgroundColor = config.backgroundColor ? config.backgroundColor : kClearColor;
                btn.titleLabel.font = font;
                [btn addTarget:self action:@selector(tagBtnAction:) forControlEvents:UIControlEventTouchUpInside];
                
                CGRect frame = self.frame;
                frame.size.height = CGRectGetMaxY(btn.frame) + topBottomSpace;
                self.frame = frame;
                self.bgImageView.frame = self.bounds;
                
                ///边框
                if (config.hasBorder)
                {
                    btn.clipsToBounds = YES;
                    btn.layer.cornerRadius = config.cornerRadius > 0 ? config.cornerRadius : config.itemHeight / 2.0;
                    UIColor *borderC = config.borderColor ? config.borderColor : [UIColor redColor];
                    btn.layer.borderColor = borderC.CGColor;
                    btn.layer.borderWidth = config.borderWidth > 0.0 ? config.borderWidth : 0.5;
                }
                
                ///可选中
                if (config.isCanSelected)
                {
                    //多选
                    if (config.isMulti)
                    {
                        for (NSString *str in config.selectedDefaultTags)
                        {
                            if ([title isEqualToString:str])
                            {
                                btn.selected = YES;
                            }
                        }
                    }
                    else
                    {  //单选
                        if ([title isEqualToString:config.singleSelectedTitle])
                        {
                            btn.selected = YES;
                            self.selectedBtn = btn;
                        }
                    }
                }
                else
                {  //不可选中
                    btn.enabled = NO;
                }
                [self addSubview:btn];
            }

            if (self.tagHeightBlock) {
                self.tagHeightBlock(self, self.frame.size.height);
            }
        });
    }
    return self;
}

-(void)layoutSubviews
{
    [super layoutSubviews];
    
    CGRect lastBtnRect = CGRectZero;
    CGFloat hMargin = 0.0, orgin_Y = 0.0, itemContentMargin = self.curConfig.itemContentEdgs > 0 ? self.curConfig.itemContentEdgs : 10.0, topBottomSpace = (self.curConfig.topBottomSpace > 0 ? self.curConfig.topBottomSpace : 15.0);
    
    UIFont *font = [UIFont fontWithName:self.curConfig.fontName ? self.curConfig.fontName:@"HelveticaNeue-Medium" size:self.curConfig.fontSize > 0 ? self.curConfig.fontSize : 12.0];

    for (int i = 0; i < self.normalTagsArr.count; i++)
    {
        NSString *title = self.normalTagsArr[i];
        CGFloat titleWidth;
        if (self.showImage)
        {
            titleWidth = self.curConfig.itemWidth;
        }
        else
        {
            titleWidth = [title sizeWithAttributes:@{NSFontAttributeName : font}].width;
        }

        if ((CGRectGetMaxX(lastBtnRect) + self.curConfig.itemHerMargin + titleWidth + 2 * itemContentMargin) > CGRectGetWidth(self.frame))
        {
            lastBtnRect.origin.x = 0.0;
            hMargin = 0.0;
            lastBtnRect.size.width = 0.0;
            orgin_Y += (self.curConfig.itemHeight + self.curConfig.itemVerMargin);
        }
        
        UIButton *btn = [self viewWithTag:BTN_Tags_Tag + i];
        if (self.showImage) {
            btn.frame = CGRectMake(hMargin + CGRectGetMaxX(lastBtnRect), topBottomSpace + orgin_Y, self.curConfig.itemWidth, self.curConfig.itemHeight);
        }
        else
        {
            btn.frame = CGRectMake(hMargin + CGRectGetMaxX(lastBtnRect), topBottomSpace + orgin_Y, titleWidth+2*itemContentMargin, self.curConfig.itemHeight);
        }
        lastBtnRect = btn.frame;
        hMargin = self.curConfig.itemHerMargin;
        
        CGRect frame = self.frame;
        frame.size.height = CGRectGetMaxY(btn.frame) + topBottomSpace;
        self.frame = frame;
        self.bgImageView.frame = self.bounds;
    }
}

- (void)tagBtnAction:(UIButton *)sender
{
    ///可选中
    if (_curConfig.isCanSelected)
    {
        //多选
        if (_curConfig.isMulti)
        {
            //可以取消选中
            if (_curConfig.isCanCancelSelected)
            {
                sender.selected = !sender.selected;
                if (sender.selected == YES)
                {
                    if (![_multiSelectedTags containsObject:sender.currentTitle])
                    {
                        [_multiSelectedTags addObject:sender.currentTitle];
                    }
                }
                else
                {
                    if ([_multiSelectedTags containsObject:sender.currentTitle]) {
                        [_multiSelectedTags removeObject:sender.currentTitle];
                    }
                }
            }
            else
            {
                sender.selected = YES;
                
                if (![_multiSelectedTags containsObject:sender.currentTitle])
                {
                    [_multiSelectedTags addObject:sender.currentTitle];
                }
            }
        }
        else
        {  //单选
            //可以取消选中
            if (_curConfig.isCanCancelSelected)
            {
                if (self.selectedBtn == sender)
                {
                    sender.selected = !sender.selected;
                    if (sender.selected == YES)
                    {
                        self.selectedBtn = sender;
                    }
                    else
                    {
                        self.selectedBtn = nil;
                    }
                }
                else
                {
                    self.selectedBtn.selected = NO;
                    sender.selected = YES;
                    self.selectedBtn = sender;
                }
            }
            else
            {
                //不可以取消选中
                self.selectedBtn.selected = NO;
                sender.selected = YES;
                self.selectedBtn = sender;
            }
        }
    }
    
    //点击回调
    NSInteger index = sender.tag - BTN_Tags_Tag;
    if (self.tagBtnClickedBlock)
    {
        self.tagBtnClickedBlock(self, sender, index);
    }
}

@end

