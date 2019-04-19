//
//  IGBannerView.m
//  Demo
//
//  Created by 何桂强 on 14/10/30.
//  Copyright (c) 2014年 touchmob.com. All rights reserved.
//

#import "IGBannerView.h"
#import "SDWebImage/UIImageView+WebCache.h"

static const int TAG_OF_IMAGE_VIEW = 1000;
static const int TAG_OF_TITLE_VIEW = 2000;

@interface IGBannerView ()<UIGestureRecognizerDelegate,UIScrollViewDelegate>{
    UIScrollView *scrollView;
    UIPageControl *pageControl;
    UIImage *placeHolderImage;
    NSArray *items;
}

@end

@implementation IGBannerView

@synthesize autoScrolling,switchTimeInterval,delegate;
@synthesize titleColor,titleBackgroundColor,pageControlBackgroundColor;
@synthesize titleHeight,pageControlHeight,titleFont;

- (id)initWithFrame:(CGRect)frame bannerItem:(IGBannerItem *)firstItem, ... NS_REQUIRES_NIL_TERMINATION{
    self = [super initWithFrame:frame];
    if (self) {
        NSMutableArray *tmpItems = [NSMutableArray array];
        IGBannerItem *eachItem;
        va_list argumentList;
        if (firstItem) {
            [tmpItems addObject: firstItem];
            va_start(argumentList, firstItem);
            while((eachItem = va_arg(argumentList, IGBannerItem*))) {
                [tmpItems addObject: eachItem];
            }
            va_end(argumentList);
        }
        items = [NSArray arrayWithArray:tmpItems];
        [self initUI];
    }
    return self;
}
- (id)initWithFrame:(CGRect)frame bannerItems:(NSArray *)aitems bannerPlaceholderImage:(UIImage *)pI
{
    self = [super initWithFrame:frame];
    if (self) {
        items = aitems;
        if (!items || ![items isKindOfClass:[NSArray class]]) {
            items = [[NSArray alloc] init];
        }
        placeHolderImage = pI;
        [self initUI];
    }
    return self;
}

-(void)initUI{
    [self initParameters];
    [self setupViews];
}

- (void)initParameters
{
    switchTimeInterval = 5.0f;
    autoScrolling = YES;
    
    pageControlHeight = 14;
    pageControlBackgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.35];
    
    titleHeight = 20;
    titleFont = [UIFont systemFontOfSize:14];
    titleBackgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.35];
    titleColor = [UIColor whiteColor];
}

- (void)setupViews
{
    CGFloat mainWidth = self.frame.size.width, mainHeight = self.frame.size.height;
    
    scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0.f, 0.f, mainWidth, mainHeight)];
    
    CGSize size = CGSizeMake(mainWidth, pageControlHeight);
    CGRect pcFrame = CGRectMake(mainWidth *.5 - size.width *.5, mainHeight - size.height, size.width, size.height);
    pageControl = [[UIPageControl alloc] initWithFrame:pcFrame];
    pageControl.backgroundColor = pageControlBackgroundColor;
    pageControl.currentPageIndicatorTintColor = [UIColor whiteColor];
    pageControl.pageIndicatorTintColor = [UIColor lightGrayColor];
    [pageControl addTarget:self action:@selector(pageControlTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:scrollView];
    [self addSubview:pageControl];
    
    scrollView.delegate = self;
    scrollView.showsVerticalScrollIndicator = NO;
    scrollView.showsHorizontalScrollIndicator = NO;
    scrollView.pagingEnabled = YES;
    scrollView.directionalLockEnabled = YES;
    scrollView.alwaysBounceHorizontal = YES;
    
    pageControl.currentPage = 0;
    
    // single tap gesture recognizer
    UITapGestureRecognizer *tapGestureRecognize = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTapGestureRecognizer:)];
    tapGestureRecognize.delegate = self;
    [scrollView addGestureRecognizer:tapGestureRecognize];
    
    pageControl.numberOfPages = items.count;
    
    CGSize scrollViewSize = scrollView.frame.size;

    for (int i = 0; i < items.count; i++) {
        IGBannerItem *item = [items objectAtIndex:i];
        UIImageView *imageView = [[UIImageView alloc] init];
        imageView.frame = CGRectMake(i * scrollViewSize.width,
                                     0.f,
                                     scrollViewSize.width,
                                     scrollViewSize.height);
        imageView.tag = TAG_OF_IMAGE_VIEW + i;
        imageView.contentMode = UIViewContentModeScaleToFill;
        
        switch (item.style) {
            case IGBannerItemWithImage:
                imageView.image = item.image;
                if (!imageView.image && placeHolderImage) {
                    imageView.image = placeHolderImage;
                }
                break;
            case IGBannerItemWithImageURL:
                [imageView sd_setImageWithURL:[NSURL URLWithString:item.imageUrl]
                             placeholderImage:placeHolderImage];
                break;
            default:
                break;
        }
        [scrollView addSubview:imageView];

        if (item.title) {
            UILabel *label = [[UILabel alloc] init];
            label.frame =CGRectMake(imageView.frame.origin.x,
                                    scrollViewSize.height-titleHeight-pageControlHeight,
                                    imageView.frame.size.width,
                                    titleHeight);
            label.backgroundColor = titleBackgroundColor;
            label.textColor = titleColor;
            label.textAlignment = NSTextAlignmentCenter;
            label.lineBreakMode = NSLineBreakByTruncatingTail;
            label.font = titleFont;
            label.tag = TAG_OF_TITLE_VIEW + i;
            label.text = item.title;
            
            [scrollView addSubview:label];
        }
    }
    
    scrollView.contentSize = CGSizeMake(scrollViewSize.width * items.count, mainHeight);
}

-(void)layoutSelf{
    CGFloat mainWidth = self.frame.size.width, mainHeight = self.frame.size.height;
    
    scrollView.frame = self.bounds;
    
    CGSize size = CGSizeMake(mainWidth, pageControlHeight);
    CGRect pcFrame = CGRectMake(mainWidth *.5 - size.width *.5, mainHeight - size.height, size.width, size.height);
    pageControl.frame = pcFrame;
    
    CGSize scrollViewSize = scrollView.frame.size;
    for (int i = 0; i < items.count; i++) {
        UIView *aView = [scrollView viewWithTag:TAG_OF_IMAGE_VIEW + i];
        if (aView && [aView isKindOfClass:[UIImageView class]]) {
            aView.frame = CGRectMake(i * scrollViewSize.width,
                                     0.f,
                                     scrollViewSize.width,
                                     scrollViewSize.height);
        }
        
        UIView *bView = [scrollView viewWithTag:TAG_OF_TITLE_VIEW + i];
        if (bView && [bView isKindOfClass:[UILabel class]]) {
            bView.frame = CGRectMake(aView.frame.origin.x,
                                     scrollViewSize.height-titleHeight-pageControlHeight,
                                     aView.frame.size.width,
                                     titleHeight);
        }
    }
    
    scrollView.contentSize = CGSizeMake(scrollViewSize.width * items.count, mainHeight);
}

- (void)layoutSubviews
{
    [super layoutSubviews];
}

#pragma mark - Actions

- (void)pageControlTapped:(id)sender
{
    UIPageControl *pc = (UIPageControl *)sender;
    [self moveToTargetPage:pc.currentPage];
}

- (void)singleTapGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
{
    int targetPage = (int)(scrollView.contentOffset.x / scrollView.frame.size.width);
    if (targetPage > -1 && targetPage < items.count) {
        IGBannerItem *item = [items objectAtIndex:targetPage];
        //delegate
        if (delegate && [delegate respondsToSelector:@selector(bannerView:didSelectItem:)]) {
            [delegate bannerView:self didSelectItem:item];
        }
        
        if (self.bannerTapBlock) {
            self.bannerTapBlock(self, item);
        }
    }
}

#pragma mark - ScrollView MOve

- (void)moveToTargetPage:(NSInteger)targetPage
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(switchFocusImageItems) object:nil];
    CGFloat targetX = targetPage * scrollView.frame.size.width;
    [self moveToTargetPosition:targetX];
    [self performSelector:@selector(switchFocusImageItems) withObject:nil afterDelay:self.switchTimeInterval];
}

- (void)switchFocusImageItems
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(switchFocusImageItems) object:nil];
    
    CGFloat targetX = scrollView.contentOffset.x + scrollView.frame.size.width;
    [self moveToTargetPosition:targetX];
    
    if (self.autoScrolling) {
        [self performSelector:@selector(switchFocusImageItems) withObject:nil afterDelay:self.switchTimeInterval];
    }
}

- (void)moveToTargetPosition:(CGFloat)targetX
{
    //NSLog(@"moveToTargetPosition : %f" , targetX);
    if (targetX >= scrollView.contentSize.width) {
        targetX = 0.0;
    }
    
    [scrollView setContentOffset:CGPointMake(targetX, 0) animated:YES] ;
    pageControl.currentPage = (int)(scrollView.contentOffset.x / scrollView.frame.size.width);
}
#pragma mark - Setter

-(void)setFrame:(CGRect)newFrame{
    [super setFrame:newFrame];
    [self layoutSelf];
}

- (void)setAutoScrolling:(BOOL)enable
{
    autoScrolling = enable;
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(switchFocusImageItems) object:nil];
    if (autoScrolling) {
        [self performSelector:@selector(switchFocusImageItems) withObject:nil afterDelay:self.switchTimeInterval];
    }
}
// title
-(void)setTitleColor:(UIColor *)color{
    titleColor = color;
    for (int i = 0; i < items.count; i++) {
        id aView = [scrollView viewWithTag:TAG_OF_TITLE_VIEW + i];
        if (aView && [aView isKindOfClass:[UILabel class]]) {
            [(UILabel*)aView setTextColor:titleColor];
        }
    }
}
-(void)setTitleBackgroundColor:(UIColor *)aColor{
    titleBackgroundColor = aColor;
    for (int i = 0; i < items.count; i++) {
        id aView = [scrollView viewWithTag:TAG_OF_TITLE_VIEW + i];
        if (aView && [aView isKindOfClass:[UILabel class]]) {
            [(UILabel*)aView setBackgroundColor:titleBackgroundColor];
        }
    }
}

-(void)setTitleFont:(UIFont *)aFont{
    titleFont = aFont;
    for (int i = 0; i < items.count; i++) {
        id aView = [scrollView viewWithTag:TAG_OF_TITLE_VIEW + i];
        if (aView && [aView isKindOfClass:[UILabel class]]) {
            [(UILabel*)aView setFont:titleFont];
        }
    }
}

-(void)setTitleHeight:(float)height{
    titleHeight = height;
    if (titleHeight < 0) {
        titleHeight = 0;
    }
    CGSize scrollViewSize = scrollView.frame.size;
    for (int i = 0; i < items.count; i++) {
        UIView *aView = [scrollView viewWithTag:TAG_OF_TITLE_VIEW + i];
        if (aView && [aView isKindOfClass:[UILabel class]]) {
            [(UILabel*)aView setFrame:CGRectMake(aView.frame.origin.x,
                                                 scrollViewSize.height-titleHeight-pageControlHeight,
                                                 scrollViewSize.width,
                                                 titleHeight)];
        }
    }
}
// pc
-(void)setPageControlHeight:(float)height{
    pageControlHeight = height;
    if (pageControlHeight < 0) {
        pageControlHeight = 0;
    }
    CGFloat mainWidth = self.frame.size.width, mainHeight = self.frame.size.height;
    CGSize size = CGSizeMake(mainWidth, pageControlHeight);
    CGRect pcFrame = CGRectMake(mainWidth *.5 - size.width *.5, mainHeight - size.height, size.width, size.height);
    pageControl.frame = pcFrame;
    self.titleHeight = titleHeight;
}

-(void)setPageControlBackgroundColor:(UIColor *)color{
    pageControlBackgroundColor = color;
    pageControl.backgroundColor = pageControlBackgroundColor;
}


#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)ascrollView
{
    pageControl.currentPage = (int)(scrollView.contentOffset.x / scrollView.frame.size.width);
}

@end
