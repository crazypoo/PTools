//
//  PooTagsLabel.m
//  XMNiao_Shop
//
//  Created by MYX on 2017/3/16.
//  Copyright © 2017年 邓杰豪. All rights reserved.
//

#import "PooTagsLabel.h"
#import "PMacros.h"

#define BTN_Tags_Tag        784843

@implementation PooTagsLabelConfig
@end

@interface PooTagsLabel ()
@property (nonatomic,strong) PooTagsLabelConfig *curConfig;

@end

@implementation PooTagsLabel

-(instancetype)initWithFrame:(CGRect)frame tagsNormalArray:(NSArray *)tagsNormalArr tagsSelectArray:(NSArray *)tagsSelectArr tagsTitleArray:(NSArray *)tagsTitleArr config:(PooTagsLabelConfig *)config wihtSection:(NSInteger)sectionIndex
{
    if (self = [super initWithFrame:frame]) {
        
        for (UIView *subView in self.subviews) {
            [subView removeFromSuperview];
        }
        
        self.tag = sectionIndex;
        
        
        _curConfig = config;
        _multiSelectedTags = [NSMutableArray array];
        if (config.selectedDefaultTags.count) {
            [_multiSelectedTags addObjectsFromArray:config.selectedDefaultTags];
        }
        
        UIImageView *bgImageView = [UIImageView new];
        bgImageView.userInteractionEnabled = YES;
        self.bgImageView = bgImageView;
        [self addSubview:bgImageView];
        
        CGRect lastBtnRect = CGRectZero;
        CGFloat hMargin = 0.0, orgin_Y = 0.0, itemContentMargin = config.itemContentEdgs > 0 ? config.itemContentEdgs : 10.0, topBottomSpace = (config.topBottomSpace > 0 ? config.topBottomSpace : 15.0);
        
        UIFont *font = [UIFont systemFontOfSize:config.fontSize > 0 ? config.fontSize : 12.0];
        
        for (int i = 0; i < tagsNormalArr.count; i++) {
            UIImage *normalImage = kImageNamed(tagsNormalArr[i]);
            NSString *title = tagsTitleArr[i];
            
            CGFloat titleWidth = normalImage.size.width;
            
            if ((CGRectGetMaxX(lastBtnRect) + config.itemHerMargin + titleWidth + 2 * itemContentMargin) > CGRectGetWidth(self.frame)) {
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
                    [btn setTitleColor:[UIColor clearColor] forState:UIControlStateNormal];
                    [btn setTitle:title forState:UIControlStateNormal];
                    [btn setBackgroundImage:normalImage forState:UIControlStateNormal];
                    [btn setBackgroundImage:kImageNamed(tagsSelectArr[i]) forState:UIControlStateSelected];
                }
                    break;
                default:
                {
                    btn.titleLabel.font = config.btnFont;
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
            
            btn.backgroundColor = config.backgroundColor ? config.backgroundColor : [UIColor clearColor];
            btn.titleLabel.font = font;
            [btn addTarget:self action:@selector(tagBtnAction:) forControlEvents:UIControlEventTouchUpInside];
            
            CGRect frame = self.frame;
            frame.size.height = CGRectGetMaxY(btn.frame) + topBottomSpace;
            self.frame = frame;
            self.bgImageView.frame = self.bounds;
            
            ///边框
            if (config.hasBorder) {
                btn.clipsToBounds = YES;
                CGFloat radius;
                if (config.cornerRadius == 0) {
                    radius = config.itemHeight / 2.0;
                }
                else
                {
                    radius = config.cornerRadius;
                }
                btn.layer.cornerRadius = radius;
                btn.layer.borderColor = config.borderColor.CGColor;
                btn.layer.borderWidth = config.borderWidth > 0.0 ? config.borderWidth : 0.5;
            }
            
            ///可选中
            if (config.isCanSelected) {
                //多选
                if (config.isMulti) {
                    
                    for (NSString *str in config.selectedDefaultTags) {
                        if ([title isEqualToString:str]) {
                            btn.selected = YES;
                        }
                    }
                    
                }else{  //单选
                    if ([title isEqualToString:config.singleSelectedTitle]) {
                        btn.selected = YES;
                        self.selectedBtn = btn;
                    }
                }
                
            }else{  //不可选中
                btn.enabled = NO;
            }
            
            [self addSubview:btn];
        }        
    }
    return self;
}

-(instancetype)initWithFrame:(CGRect)frame tagsArray:(NSArray *)tagsArr config:(PooTagsLabelConfig *)config wihtSection:(NSInteger)sectionIndex
{
    
    if (self = [super initWithFrame:frame]) {
        
        for (UIView *subView in self.subviews) {
            [subView removeFromSuperview];
        }
        
        self.tag = sectionIndex;
        
        
        _curConfig = config;
        _multiSelectedTags = [NSMutableArray array];
        if (config.selectedDefaultTags.count) {
            [_multiSelectedTags addObjectsFromArray:config.selectedDefaultTags];
        }
        
        UIImageView *bgImageView = [UIImageView new];
        bgImageView.userInteractionEnabled = YES;
        self.bgImageView = bgImageView;
        [self addSubview:bgImageView];
        
        CGRect lastBtnRect = CGRectZero;
        CGFloat hMargin = 0.0, orgin_Y = 0.0, itemContentMargin = config.itemContentEdgs > 0 ? config.itemContentEdgs : 10.0, topBottomSpace = (config.topBottomSpace > 0 ? config.topBottomSpace : 15.0);
        
        UIFont *font = [UIFont systemFontOfSize:config.fontSize > 0 ? config.fontSize : 12.0];
        
        for (int i = 0; i < tagsArr.count; i++) {
            NSString *title = tagsArr[i];
            CGFloat titleWidth = [title sizeWithAttributes:@{NSFontAttributeName : font}].width;
            
            if ((CGRectGetMaxX(lastBtnRect) + config.itemHerMargin + titleWidth + 2 * itemContentMargin) > CGRectGetWidth(self.frame)) {
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
            if (config.normalBgImage) {
                [btn setBackgroundImage:[UIImage imageNamed:config.normalBgImage] forState:UIControlStateNormal];
            }
            if (config.selectedBgImage) {
                [btn setBackgroundImage:[UIImage imageNamed:config.selectedBgImage] forState:UIControlStateSelected];
            }
            
            btn.backgroundColor = config.backgroundColor ? config.backgroundColor : [UIColor clearColor];
            btn.titleLabel.font = font;
            [btn addTarget:self action:@selector(tagBtnAction:) forControlEvents:UIControlEventTouchUpInside];
            
            CGRect frame = self.frame;
            frame.size.height = CGRectGetMaxY(btn.frame) + topBottomSpace;
            self.frame = frame;
            self.bgImageView.frame = self.bounds;
            
            ///边框
            if (config.hasBorder) {
                btn.clipsToBounds = YES;
                btn.layer.cornerRadius = config.itemHeight / 2.0;
                btn.layer.borderColor = config.borderColor.CGColor;
                btn.layer.borderWidth = config.borderWidth > 0.0 ? config.borderWidth : 0.5;
            }
            
            ///可选中
            if (config.isCanSelected) {
                //多选
                if (config.isMulti) {
                    
                    for (NSString *str in config.selectedDefaultTags) {
                        if ([title isEqualToString:str]) {
                            btn.selected = YES;
                        }
                    }
                    
                }else{  //单选
                    if ([title isEqualToString:config.singleSelectedTitle]) {
                        btn.selected = YES;
                        self.selectedBtn = btn;
                    }
                }
                
            }else{  //不可选中
                btn.enabled = NO;
            }
            
            [self addSubview:btn];
        }
        
        
    }
    return self;
}

- (CGFloat)heighttagsArray:(NSArray *)tagsArr config:(PooTagsLabelConfig *)config{
    
    CGFloat defaultHeight = config.itemHeight + 2*config.topBottomSpace, tagViewHeight = defaultHeight,  titleWidth = 0.0;
    
    if (tagsArr.count == 0) {
        return 0.0;
    }
    
    NSInteger row = 1;
    UIFont *font = [UIFont systemFontOfSize:config.fontSize > 0 ? config.fontSize : 12.0];
    CGFloat itemContentMargin = config.itemContentEdgs > 0 ? config.itemContentEdgs : 10.0;
    
    for (int i = 0; i < tagsArr.count; i++) {
        NSString *title = tagsArr[i];
        
        CGFloat singleWidth = [title sizeWithAttributes:@{NSFontAttributeName : font}].width + config.itemHerMargin + 2 * itemContentMargin;
        titleWidth += singleWidth;
        
        if ((titleWidth - config.itemHerMargin) > CGRectGetWidth(self.frame)) {
            titleWidth = singleWidth;
            row += 1;
            
            tagViewHeight = defaultHeight + (row -1) * (config.itemVerMargin + config.itemHeight);
        }
    }
    
    return tagViewHeight;
    
}

- (void)tagBtnAction:(UIButton *)sender{
    
    ///可选中
    if (_curConfig.isCanSelected) {
        //多选
        if (_curConfig.isMulti) {
            
            //可以取消选中
            if (_curConfig.isCanCancelSelected){
                sender.selected = !sender.selected;
                if (sender.selected == YES) {
                    if (![_multiSelectedTags containsObject:sender.currentTitle]) {
                        [_multiSelectedTags addObject:sender.currentTitle];
                    }
                }else{
                    if ([_multiSelectedTags containsObject:sender.currentTitle]) {
                        [_multiSelectedTags removeObject:sender.currentTitle];
                    }
                }
                
            }else{
                sender.selected = YES;
                
                if (![_multiSelectedTags containsObject:sender.currentTitle]) {
                    [_multiSelectedTags addObject:sender.currentTitle];
                }
            }
            
            
        }else{  //单选
            //可以取消选中
            if (_curConfig.isCanCancelSelected) {
                if (self.selectedBtn == sender) {
                    sender.selected = !sender.selected;
                    if (sender.selected == YES) {
                        self.selectedBtn = sender;
                    }else{
                        self.selectedBtn = nil;
                    }
                }else{
                    self.selectedBtn.selected = NO;
                    sender.selected = YES;
                    self.selectedBtn = sender;
                }
                
            }else{
                //不可以取消选中
                self.selectedBtn.selected = NO;
                sender.selected = YES;
                self.selectedBtn = sender;
            }
            
        }
    }
    
    //点击回调
    NSInteger index = sender.tag - BTN_Tags_Tag;
    if (self.tagBtnClickedBlock) {
        self.tagBtnClickedBlock(self, sender, index);
    }
}

@end

