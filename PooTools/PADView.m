//
//  PADView.m
//  CloudGateCustom
//
//  Created by 邓杰豪 on 16/5/18.
//  Copyright © 2018年 邓杰豪. All rights reserved.
//

#import "PADView.h"
#import "SDWebImage/UIImageView+WebCache.h"
#import "PMacros.h"
#import <Masonry/Masonry.h>

static NSString * const ADBannerCollectionViewCell = @"ADBannerCollectionViewCell";
@interface PADView ()
@property (nonatomic,assign)CGFloat viewW;
@property (nonatomic,assign)CGFloat viewH;
@property (nonatomic,assign)CGFloat viewX;
@property (nonatomic,assign)CGFloat viewY;
@property (nonatomic,strong)UIFont *titleFont;

@end

@implementation PADView
-(instancetype)initWithAdArray:(NSArray <CGAdBannerModel *> *)adArr singleADW:(CGFloat)sw singleADH:(CGFloat)sh paddingY:(CGFloat)py paddingX:(CGFloat)px placeholderImage:(NSString *)pI pageTime:(int)pT adTitleFont:(UIFont *)adTitleFont
{
    self = [super init];
    if (self) {
        viewData = adArr;
        placeholderImageString = pI;
        pageTime = pT;
        self.viewW = sw;
        self.viewH = sh;
        self.viewX = px;
        self.viewY = py;
        self.titleFont = adTitleFont;
        
        adCollectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:[CGLayout createLayoutItemW:sw itemH:sh paddingY:py paddingX:px scrollDirection:UICollectionViewScrollDirectionHorizontal]];
        adCollectionView.backgroundColor                = [UIColor whiteColor];
        adCollectionView.dataSource                     = self;
        adCollectionView.delegate                       = self;
        adCollectionView.showsHorizontalScrollIndicator = NO;
        adCollectionView.showsVerticalScrollIndicator   = NO;
        adCollectionView.pagingEnabled                  = NO;
        [adCollectionView registerClass:[CGADCollectionViewCell class] forCellWithReuseIdentifier:ADBannerCollectionViewCell];
        [self addSubview:adCollectionView];
        [adCollectionView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.top.bottom.equalTo(self);
        }];
        
        if (pT != 0) {
            [self addTimer];
        }
    }
    return self;
}

-(void)layoutSubviews
{
    [super layoutSubviews];
    
    if (self.viewW == kSCREEN_HEIGHT)
    {
        self.viewW = kSCREEN_WIDTH;
    }
    else
    {
        self.viewW = self.viewW;
    }
    
    adCollectionView.collectionViewLayout = [CGLayout createLayoutItemW:self.viewW itemH:self.viewH paddingY:self.viewY paddingX:self.viewX scrollDirection:UICollectionViewScrollDirectionHorizontal];
    [adCollectionView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.left.right.top.bottom.equalTo(self);
    }];
}

#pragma mark ---------------> UICollectionViewDataSource
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    //#warning Incomplete method implementation -- Return the number of sections
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    //#warning Incomplete method implementation -- Return the number of items in the section
    return viewData.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    CGAdBannerModel *models = viewData[indexPath.row];

    CGADCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:ADBannerCollectionViewCell forIndexPath:indexPath];
    [cell.adImage sd_setImageWithURL:[NSURL URLWithString:models.bannerImage] placeholderImage:kImageNamed(placeholderImageString)];
    if (kStringIsEmpty(models.bannerTitle)) {
        cell.adTitle.hidden = YES;
    }
    else
    {
        cell.adTitle.hidden = NO;
        cell.adTitle.font = self.titleFont ? self.titleFont : [UIFont fontWithName:@"HelveticaNeue-Light" size:18];
        cell.adTitle.text = models.bannerTitle;
    }
    // Configure the cell
    
    return cell;
}

#pragma mark ---------------> UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    CGAdBannerModel *models = viewData[indexPath.row];
    if (self.adTouchBlock) {
        self.adTouchBlock(models);
    }
}

#pragma mark ------> NSTimer
-(void)addTimer
{
    timer = [NSTimer scheduledTimerWithTimeInterval:pageTime target:self selector:@selector(nextpage) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
}

-(void) removeTimer{
    [timer invalidate];
    timer = nil;
}

#pragma mark ------> UIScrollViewDelegate
-(void)scrollViewWillBeginDragging:(UIScrollView *)scrollView{
    [self removeTimer];
}

-(void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
    [self addTimer];
}

#pragma mark ------> 下一张
-(void)nextpage
{
    NSIndexPath *currentIndexPath = [[adCollectionView indexPathsForVisibleItems] lastObject];
    
    NSIndexPath *currentIndexPathReset = [NSIndexPath indexPathForItem:currentIndexPath.item inSection:currentIndexPath.section];
    [adCollectionView scrollToItemAtIndexPath:currentIndexPathReset atScrollPosition:UICollectionViewScrollPositionLeft animated:NO];
    
    NSInteger nextItem = currentIndexPathReset.item +1;
    NSInteger nextSection = currentIndexPathReset.section;
    if (nextItem == viewData.count) {
        nextItem = 0;
    }
    NSIndexPath *nextIndexPath = [NSIndexPath indexPathForItem:nextItem inSection:nextSection];
    
    [adCollectionView scrollToItemAtIndexPath:nextIndexPath atScrollPosition:UICollectionViewScrollPositionLeft animated:YES];
}
@end
