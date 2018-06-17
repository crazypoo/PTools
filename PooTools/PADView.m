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

static NSString * const ADBannerCollectionViewCell = @"ADBannerCollectionViewCell";

@implementation PADView
-(instancetype)initWithFrame:(CGRect)frame adArray:(NSArray <CGAdBannerModel *> *)adArr singleADW:(CGFloat)sw singleADH:(CGFloat)sh paddingY:(CGFloat)py paddingX:(CGFloat)px placeholderImage:(NSString *)pI pageTime:(int)pT
{
    self = [super initWithFrame:frame];
    if (self) {
        viewData = adArr;
        placeholderImageString = pI;
        pageTime = pT;
        
        adCollectionView = [[UICollectionView alloc] initWithFrame:self.bounds collectionViewLayout:[CGLayout createLayoutItemW:sw itemH:sh paddingY:py paddingX:px scrollDirection:UICollectionViewScrollDirectionHorizontal]];
        adCollectionView.backgroundColor                = [UIColor whiteColor];
        adCollectionView.dataSource                     = self;
        adCollectionView.delegate                       = self;
        adCollectionView.showsHorizontalScrollIndicator = NO;
        adCollectionView.showsVerticalScrollIndicator   = NO;
        adCollectionView.pagingEnabled                  = NO;
        [adCollectionView registerClass:[CGADCollectionViewCell class] forCellWithReuseIdentifier:ADBannerCollectionViewCell];
        [self addSubview:adCollectionView];
        
        [self addTimer];
    }
    return self;
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
