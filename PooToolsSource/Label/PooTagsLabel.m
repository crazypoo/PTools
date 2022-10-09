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
#import <Masonry/Masonry.h>
#import <PooTools/PooTools-Swift.h>

#define BTN_Tags_Tag        784843

@implementation PooTagsLabelConfig
@end

@interface PooTagsLabel ()
@property (nonatomic,strong) PooTagsLabelConfig *curConfig;
@property (nonatomic,strong) NSArray *normalTagsArr;
@property (nonatomic,assign) BOOL showImage;
@property (nonatomic,assign) CGFloat viewW;
@property (nonatomic,strong) NSArray *selectedTagsArr;
@property (nonatomic,strong) NSArray *tagsTitleArr;

@property (nonatomic,assign) NSInteger section;
@property (nonatomic,strong) NSMutableArray <NSNumber *>*rowLastTagArr;
@property (nonatomic,strong) NSMutableArray <NSNumber *>*sectionCountArr;
@end

@implementation PooTagsLabel

-(instancetype)initWithConfig:(PooTagsLabelConfig *)config wihtSection:(NSInteger)sectionIndex
{
    if (self = [super init])
    {
        for (UIView *subView in self.subviews)
        {
            [subView removeFromSuperview];
        }
        _curConfig = config;

        switch (self.curConfig.showStatus) {
            case PooTagsLabelShowWithNormal:
            {
                self.showImage = NO;
                self.tagsTitleArr = config.titleNormal;
            }
                break;
            case PooTagsLabelShowWithImage:
            {
                self.showImage = YES;
                self.normalTagsArr = config.normalImage;
                self.selectedTagsArr = config.selectedImage;
                self.tagsTitleArr = config.titleNormal;
            }
                break;
            default:
                break;
        }

        _multiSelectedTags = [NSMutableArray array];
        if (config.selectedDefaultTags.count > 0)
        {
            [_multiSelectedTags addObjectsFromArray:config.selectedDefaultTags];
        }
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            UIImageView *bgImageView = [UIImageView new];
            bgImageView.userInteractionEnabled = YES;
            self.bgImageView = bgImageView;
            [self addSubview:bgImageView];
            
            CGRect lastBtnRect = CGRectZero;
            CGFloat hMargin = 0.0, orgin_Y = 0.0, itemContentMargin = self.curConfig.itemContentEdgs > 0 ? self.curConfig.itemContentEdgs : 10.0, topBottomSpace = (self.curConfig.topBottomSpace > 0 ? self.curConfig.topBottomSpace : 15.0);
            UIFont *font = kDEFAULT_FONT(self.curConfig.fontName ? self.curConfig.fontName:kDevLikeFont_Bold, self.curConfig.fontSize > 0 ? self.curConfig.fontSize : 12.0);
            
            self.section = 0;
            NSInteger row = 0;

            self.rowLastTagArr = [NSMutableArray array];

            NSUInteger tagCountMax = 0;
            switch (self.curConfig.showStatus) {
                case PooTagsLabelShowWithNormal:
                {
                    tagCountMax = self.tagsTitleArr.count;
                }
                    break;
                case PooTagsLabelShowWithImage:
                {
                    tagCountMax = self.normalTagsArr.count;
                }
                    break;
                default:
                {
                    tagCountMax = 0;
                }
                    break;
            }

            NSMutableArray *floatArr = [[NSMutableArray alloc] init];
            for (int i = 0; i < self.tagsTitleArr.count; i++)
            {
                if (self.curConfig.lockWidth)
                {
                    NSDecimalNumber *dNumber = [[NSDecimalNumber alloc] initWithFloat:[PTUtils oc_sizeWithString:self.tagsTitleArr[i] font:font lineSpacing:3 height:CGFLOAT_MAX width:self.curConfig.itemWidth].height];
                    [floatArr addObject:dNumber];
                }
            }

            CGFloat maxValue = 0.0f;
            if (floatArr.count > 0)
            {
                maxValue = [[floatArr valueForKeyPath:@"@max.floatValue"] floatValue];
            }
            
            for (int i = 0; i < tagCountMax; i++)
            {
                UIImage *normalImage = kImageNamed(self.normalTagsArr[i]);
                NSString *title = self.tagsTitleArr[i];
                
                CGFloat titleWidth = 0.0f;
                CGFloat titleHeight = 0.0f;
                
                switch (self.curConfig.showStatus) {
                    case PooTagsLabelShowWithNormal:
                    {
                        if (self.curConfig.lockWidth)
                        {
                            titleWidth = self.curConfig.itemWidth;
                            if (maxValue > self.curConfig.itemHeight)
                            {
                                titleHeight = maxValue;
                            }
                            else
                            {
                                titleHeight = self.curConfig.itemHeight;
                            }
                        }
                        else
                        {
                            titleWidth = [title sizeWithAttributes:@{NSFontAttributeName : font}].width + 2*itemContentMargin;
                            titleHeight = self.curConfig.itemHeight;
                        }
                    }
                        break;
                    case PooTagsLabelShowWithImage:
                    {
                        switch (self.curConfig.showSubStatus) {
                            case PooTagsLabelShowSubStatusNormal:
                            {
                                if (self.curConfig.insetsStyle == MKButtonEdgeInsetsStyleLeft || self.curConfig.insetsStyle == MKButtonEdgeInsetsStyleRight)
                                {
                                    if (self.curConfig.lockWidth)
                                    {
                                        CGFloat leftWidth = self.curConfig.itemWidth - 2*itemContentMargin + self.curConfig.tagImageSize.width;
                                        CGFloat leftHeight = [PTUtils oc_sizeWithString:self.tagsTitleArr[i] font:font lineSpacing:3 height:CGFLOAT_MAX width:leftWidth].height;
                                        titleWidth = self.curConfig.itemWidth;
                                        if (leftHeight > self.curConfig.itemHeight)
                                        {
                                            titleHeight = leftHeight;
                                        }
                                        else
                                        {
                                            titleHeight = self.curConfig.itemHeight;
                                        }
                                    }
                                    else
                                    {
                                        titleWidth = [title sizeWithAttributes:@{NSFontAttributeName : font}].width + 2*itemContentMargin + self.curConfig.tagImageSize.width + self.curConfig.imageAndTitleSpace;
                                        titleHeight = self.curConfig.itemHeight;
                                    }
                                }
                                else
                                {
                                    CGSize titleSize = [title sizeWithAttributes:@{NSFontAttributeName : font}];
                                    if (self.curConfig.lockWidth)
                                    {
                                        titleWidth = self.curConfig.itemWidth;
                                        titleHeight = self.curConfig.tagImageSize.height+maxValue+2*10;
                                    }
                                    else
                                    {
                                        if (titleSize.width > self.curConfig.tagImageSize.width)
                                        {
                                            titleWidth = titleSize.width + 2*itemContentMargin;
                                        }
                                        else
                                        {
                                            titleWidth = self.curConfig.tagImageSize.width + 2*itemContentMargin;
                                        }
                                        titleHeight = self.curConfig.itemHeight;
                                    }
                                }
                            }
                                break;
                            case PooTagsLabelShowSubStatusAllSameWidth:
                            {
                                titleWidth = self.curConfig.itemWidth;
                                titleHeight = maxValue;
                            }
                                break;
                            case PooTagsLabelShowSubStatusNoTitle:
                            {
                                titleWidth = self.curConfig.tagImageSize.width + 2*itemContentMargin;
                                titleHeight = self.curConfig.itemHeight;
                            }
                                break;
                            default:
                                break;
                        }
                    }
                        break;
                    default:
                        break;
                }

                if ((CGRectGetMaxX(lastBtnRect) + self.curConfig.itemHerMargin + titleWidth + 2 * itemContentMargin) > CGRectGetWidth(self.frame))
                {
                    lastBtnRect.origin.x = 0.0;
                    hMargin = 0.0;
                    lastBtnRect.size.width = 0.0;
                    orgin_Y += (titleHeight + self.curConfig.itemVerMargin);
                    
                    NSInteger currentRowLastTag = row - BTN_Tags_Tag;
                    [self.rowLastTagArr addObject:[NSNumber numberWithInteger:currentRowLastTag]];
                    
                    self.section += 1;
                }
                
                if (i == (self.tagsTitleArr.count - 1))
                {
                    if (![self.rowLastTagArr containsObject:[NSNumber numberWithInteger:i]])
                    {
                        [self.rowLastTagArr addObject:[NSNumber numberWithInteger:i]];
                    }
                }
                
                UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(hMargin + CGRectGetMaxX(lastBtnRect), topBottomSpace + orgin_Y, titleWidth, titleHeight)];
                lastBtnRect = btn.frame;
                hMargin = self.curConfig.itemHerMargin;
                btn.tag = BTN_Tags_Tag + i;
                row = BTN_Tags_Tag + i;
                btn.titleLabel.numberOfLines = 0;
                [self addSubview:btn];

                ///标题设置
                switch (self.curConfig.showStatus) {
                    case PooTagsLabelShowWithNormal:
                    {
                        ///标题设置
                        UIColor *normorTitleColor = config.normalTitleColor ? config.normalTitleColor : [UIColor grayColor];
                        UIColor *selectedTitleColor = config.selectedTitleColor ? config.selectedTitleColor : [UIColor greenColor];
                        [btn setTitle:title forState:UIControlStateNormal];
                        [btn setTitleColor:normorTitleColor forState:UIControlStateNormal];
                        [btn setTitleColor:selectedTitleColor forState:UIControlStateSelected];

                        btn.titleLabel.textAlignment = self.curConfig.textAlignment ? self.curConfig.textAlignment : NSTextAlignmentCenter;
                        
                        ///图片设置
                        if (config.normalBgImage)
                        {
                            [btn setBackgroundImage:[UIImage imageNamed:config.normalBgImage] forState:UIControlStateNormal];
                        }
                        if (config.selectedBgImage)
                        {
                            [btn setBackgroundImage:[UIImage imageNamed:config.selectedBgImage] forState:UIControlStateSelected];
                        }
                    }
                        break;
                    case PooTagsLabelShowWithImage:
                    {
                        switch (self.curConfig.showSubStatus) {
                            case PooTagsLabelShowSubStatusNoTitle:
                            {
                                [btn setTitleColor:kClearColor forState:UIControlStateNormal];
                                [btn setTitle:title forState:UIControlStateNormal];
                                [btn setBackgroundImage:normalImage forState:UIControlStateNormal];
                                [btn setBackgroundImage:kImageNamed(self.selectedTagsArr[i]) forState:UIControlStateSelected];
                            }
                                break;
                            default:
                            {
                                UIColor *normorTitleColor = self.curConfig.normalTitleColor ? self.curConfig.normalTitleColor : [UIColor grayColor];
                                UIColor *selectedTitleColor = self.curConfig.selectedTitleColor ? self.curConfig.selectedTitleColor : [UIColor greenColor];

                                if (self.curConfig.insetsStyle == MKButtonEdgeInsetsStyleBottom || self.curConfig.insetsStyle == MKButtonEdgeInsetsStyleTop)
                                {
                                    btn.titleLabel.textAlignment = self.curConfig.textAlignment ? self.curConfig.textAlignment : NSTextAlignmentCenter;
                                }

                                [btn setTitleColor:normorTitleColor forState:UIControlStateNormal];
                                [btn setTitleColor:selectedTitleColor forState:UIControlStateSelected];
                                [btn setTitle:title forState:UIControlStateNormal];
                                [btn setTitle:title forState:UIControlStateSelected];
                                [btn setImage:normalImage forState:UIControlStateNormal];
                                [btn setImage:kImageNamed(self.selectedTagsArr[i]) forState:UIControlStateSelected];
                                [btn layoutButtonWithEdgeInsetsStyle:self.curConfig.insetsStyle imageTitleSpace:self.curConfig.imageAndTitleSpace];
                            }
                                break;
                        }
                    }
                        break;
                    default:
                        break;
                }

                btn.backgroundColor = self.curConfig.backgroundColor ? self.curConfig.backgroundColor : kClearColor;
                btn.titleLabel.font = font;
                [btn addTarget:self action:@selector(tagBtnAction:) forControlEvents:UIControlEventTouchUpInside];
                
                CGRect frame = self.frame;
                frame.size.height = CGRectGetMaxY(btn.frame) + topBottomSpace;
                self.frame = frame;
                self.bgImageView.frame = self.bounds;
                
                ///边框
                if (self.curConfig.hasBorder)
                {
                    btn.clipsToBounds = YES;
                    btn.layer.cornerRadius = self.curConfig.cornerRadius > 0 ? self.curConfig.cornerRadius : self.curConfig.itemHeight / 2.0;
                    btn.layer.borderColor = self.curConfig.borderColor.CGColor;
                    btn.layer.borderWidth = self.curConfig.borderWidth > 0.0 ? self.curConfig.borderWidth : 0.5;
                }
                
                ///可选中
                if (self.curConfig.isCanSelected)
                {
                    //多选
                    if (self.curConfig.isMulti)
                    {
                        for (NSString *str in self.multiSelectedTags)
                        {
                            if ([title isEqualToString:str])
                            {
                                btn.selected = YES;
                            }
                        }
                    }
                    else
                    {  //单选
                        if ([title isEqualToString:self.curConfig.singleSelectedTitle])
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
                [self btnBackgroundColorAndBorderColor:btn];
            }
            if (self.tagHeightBlock) {
                self.tagHeightBlock(self, self.frame.size.height);
            }
            
//            PNSLog(@"最后一行section>>>>>%ld",(long)self.section);

            [self.rowLastTagArr addObject:[NSNumber numberWithInteger:self.normalTagsArr.count-1]];
            
//            PNSLog(@"每行最后一个的tag数组>>>>>>>%@",self.rowLastTagArr);

            self.sectionCountArr = [NSMutableArray array];
            for (int i = 0; i < self.rowLastTagArr.count; i++) {
                if (i == 0) {
                    NSInteger currentRowCount = [self.rowLastTagArr[i] integerValue]+1;
                    [self.sectionCountArr addObject:[NSNumber numberWithInteger:currentRowCount]];
                }
                else
                {
                    NSInteger currentRowCount = [self.rowLastTagArr[i] integerValue] - [self.rowLastTagArr[i-1] integerValue];
                    [self.sectionCountArr addObject:[NSNumber numberWithInteger:currentRowCount]];
                }
            }
            
            if (self.tagViewHadSectionAndSetcionLastTagAndTagInSectionCountBlock)
            {
                self.tagViewHadSectionAndSetcionLastTagAndTagInSectionCountBlock(self, self.section, self.rowLastTagArr, self.sectionCountArr);
            }
            [self setTagPosition:config.tagPosition];
        });

    }
    return self;
}

-(void)setTagPosition:(PooTagPosition)position
{
    for (int j = 0; j < (self.section+1); j++) {
        CGFloat totalW = 0.0;
        CGFloat currentSectionTotalW = 0.0f;
        if (self.curConfig.lockWidth)
        {
            totalW = self.curConfig.itemWidth*[self.sectionCountArr[j] integerValue]+self.curConfig.itemHerMargin*([self.sectionCountArr[j] integerValue]-1);
            currentSectionTotalW = totalW;
        }
        else
        {
            for (int i = ((j == 0) ? 0 : ([self.rowLastTagArr[j-1] intValue]+1)); i < ([self.rowLastTagArr[j] intValue]+1); i++) {
                UIButton *currentBtn = [self viewWithTag:i+BTN_Tags_Tag];//当前

                totalW += CGRectGetWidth(currentBtn.frame);
            }
            currentSectionTotalW = totalW+self.curConfig.itemHerMargin*([self.sectionCountArr[j] integerValue]+1);
        }
//        PNSLog(@"当行(%d)总w:%f",j,totalW);
        
        CGFloat xxxxxxxxx;
        switch (position) {
            case PooTagPositionCenter:
            {
                if ((self.frame.size.width - currentSectionTotalW) < 0)
                {
                    xxxxxxxxx = 0;
                }
                else
                {
                    if (self.curConfig.titleNormal.count == 1)
                    {
                        xxxxxxxxx = (self.frame.size.width - self.curConfig.itemWidth)/2;
                    }
                    else
                    {
                        if (j == self.section)
                        {
                            if (self.section == 0)
                            {
                                xxxxxxxxx = (self.frame.size.width - (self.curConfig.itemWidth*[self.sectionCountArr[0] integerValue]+self.curConfig.itemHerMargin*([self.sectionCountArr[0] integerValue]-1)))/2;
                            }
                            else
                            {
                                xxxxxxxxx = (self.frame.size.width - (self.curConfig.itemWidth*[self.sectionCountArr[j-1] integerValue]+self.curConfig.itemHerMargin*([self.sectionCountArr[j-1] integerValue]-1)))/2;
                            }
                        }
                        else
                        {
                            xxxxxxxxx = (self.frame.size.width - currentSectionTotalW)/2;
                        }
                    }
                }
            }
                break;
            case PooTagPositionLeft:
            {
                xxxxxxxxx = self.curConfig.itemHerMargin;
            }
                break;
            case PooTagPositionRight:
            {
                xxxxxxxxx = self.frame.size.width - currentSectionTotalW + self.curConfig.itemHerMargin;
            }
                break;
            default:
            {
                xxxxxxxxx = self.curConfig.itemHerMargin;
            }
                break;
        }
        
        for (int i = ((j == 0) ? 0 : ([self.rowLastTagArr[j-1] intValue]+1)); i < [self.rowLastTagArr[j] intValue]+1; i++) {
                UIButton *currentBtn = [self viewWithTag:i+BTN_Tags_Tag];//当前
                UIButton *lastBtn = [self viewWithTag:i-1+BTN_Tags_Tag];//上一个
            if (i == ((j == 0) ? 0 : ([self.rowLastTagArr[j-1] intValue]+1)))
            {
                currentBtn.frame = CGRectMake(xxxxxxxxx, currentBtn.frame.origin.y, currentBtn.frame.size.width, currentBtn.frame.size.height);
            }
            else
            {
                currentBtn.frame = CGRectMake(lastBtn.frame.origin.x+lastBtn.frame.size.width+self.curConfig.itemHerMargin, currentBtn.frame.origin.y, currentBtn.frame.size.width, currentBtn.frame.size.height);
            }
        }

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
                [self btnBackgroundColorAndBorderColor:self.selectedBtn];
                sender.selected = YES;
                self.selectedBtn = sender;
            }
        }
    }
    
    [self btnBackgroundColorAndBorderColor:sender];
    
    //点击回调
    NSInteger index = sender.tag - BTN_Tags_Tag;
    if (self.tagBtnClickedBlock)
    {
        self.tagBtnClickedBlock(self, sender, index);
    }
}

-(void)btnBackgroundColorAndBorderColor:(UIButton *)sender
{
    if (self.curConfig.hasBorder) {
        if (sender.selected)
        {
            UIColor *borderC = self.curConfig.borderColorSelected ? self.curConfig.borderColorSelected : [UIColor grayColor];
            sender.layer.borderColor = borderC.CGColor;
        }
        else
        {
            UIColor *borderC = self.curConfig.borderColor ? self.curConfig.borderColor : [UIColor grayColor];
            sender.layer.borderColor = borderC.CGColor;
        }
    }
    
    if (sender.selected)
    {
        sender.backgroundColor = self.curConfig.backgroundSelectedColor ? self.curConfig.backgroundSelectedColor : kClearColor;
    }
    else
    {
        sender.backgroundColor = self.curConfig.backgroundColor ? self.curConfig.backgroundColor : kClearColor;
    }
}

-(void)clearTag
{
    for (int i = 0; i < self.tagsTitleArr.count; i++)
    {
        UIButton *btn = [self viewWithTag:BTN_Tags_Tag + i];
        btn.selected = NO;
        btn.backgroundColor = self.curConfig.backgroundColor ? self.curConfig.backgroundColor : kClearColor;
        
        if (self.curConfig.hasBorder) {
            UIColor *borderC = self.curConfig.borderColor ? self.curConfig.borderColor : [UIColor grayColor];
            btn.layer.borderColor = borderC.CGColor;
        }
    }
}

-(void)reloadTag:(PooTagsLabelConfig *)config
{
    [self clearTag];
    
    for (int i = 0; i < self.tagsTitleArr.count; i++)
    {
        NSString *title = self.showImage ? self.tagsTitleArr[i] : self.normalTagsArr[i];

        UIButton *btn = [self viewWithTag:BTN_Tags_Tag + i];
        
        [_multiSelectedTags removeAllObjects];
        [_multiSelectedTags addObjectsFromArray:config.selectedDefaultTags];
        
        btn.backgroundColor = config.backgroundColor ? config.backgroundColor : kClearColor;
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
            
            if (btn.selected) {
                if (config.hasBorder)
                {
                    UIColor *borderC = config.borderColorSelected ? config.borderColorSelected : [UIColor grayColor];
                    btn.layer.borderColor = borderC.CGColor;
                }
                btn.backgroundColor = config.backgroundSelectedColor ? config.backgroundSelectedColor : kClearColor;
            }
            else
            {
                if (self.curConfig.hasBorder)
                {
                    UIColor *borderC = config.borderColor ? config.borderColor : [UIColor grayColor];
                    btn.layer.borderColor = borderC.CGColor;
                }
                btn.backgroundColor = config.backgroundColor ? config.backgroundColor : kClearColor;
            }
        }
        else
        {  //不可选中
            btn.enabled = NO;
        }
    }
}
@end

