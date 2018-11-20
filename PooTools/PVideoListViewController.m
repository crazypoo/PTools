//
//  PVideoListViewController.m
//  XMNaio_Client
//
//  Created by MYX on 2017/5/16.
//  Copyright © 2017年 E33QU5QCP3.com.xnmiao.customer.XMNiao-Customer. All rights reserved.
//

#import "PVideoListViewController.h"
#import "PVideoSupport.h"
#import <Masonry/Masonry.h>
#import "CGLayout.h"

@interface PVideoListViewController ()<UICollectionViewDelegate, UICollectionViewDataSource>
{
    PCloseBtn *_leftBtn;
    UIButton *_rightBtn;
    
    CGFloat customVideo_W_H;
    CGFloat customControViewHeight;
}

@property (nonatomic, weak)  UICollectionView *collectionView;

@property (nonatomic, strong)  NSMutableArray *dataArr;

@property (nonatomic, assign) PVideoViewShowType showType;

@property (nonatomic, strong) UILabel *titleLabel;

@end

static PVideoListViewController *__currentListVC = nil;

@implementation PVideoListViewController

-(instancetype)initWithVideo_H_W:(CGFloat)Video_W_H withControViewHeight:(CGFloat)controViewHeight
{
    self = [super init];
    if (self)
    {
        customVideo_W_H = Video_W_H;
        customControViewHeight = controViewHeight;
    }
    return self;
}

- (void)showAnimationWithType:(PVideoViewShowType)showType
{
    _showType = showType;
    [self setupSubViews];
    __currentListVC = self;
    UIWindow *keyWindow = [UIApplication sharedApplication].delegate.window;
    _actionView.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1.6, 1.6);
    _actionView.alpha = 0.0;
    [keyWindow addSubview:_actionView];
    
    [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.actionView.transform = CGAffineTransformIdentity;
        self.actionView.alpha = 1.0;
    } completion:^(BOOL finished) {
        
    }];
    [self setupCollectionView];
}

- (void)closeAnimation
{
    __weak typeof (self) blockSelf = self;
    [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.actionView.transform = CGAffineTransformTranslate(CGAffineTransformIdentity, 0, self.actionView.bounds.size.width);
        self.actionView.alpha = .0;
    } completion:^(BOOL finished) {
        if (self.didCloseBlock)
        {
            self.didCloseBlock();
        }
        [blockSelf closeView];
    }];
}

- (void)closeView
{
    [_collectionView removeFromSuperview];
    _collectionView = nil;
    [_actionView removeFromSuperview];
    _actionView = nil;
    [_dataArr removeAllObjects];
    _dataArr = nil;
    __currentListVC = nil;
}

- (void)setupSubViews
{
    CGFloat btnTopEdge = _showType == PVideoViewShowTypeSingle ? 20:0;
    CGFloat topBarHeight = _showType == PVideoViewShowTypeSingle ? 44 : 40;
    
    _actionView = [[UIView alloc] initWithFrame:[PVideoConfig viewFrameWithType:_showType video_W_H:customVideo_W_H withControViewHeight:customControViewHeight]];
    _actionView.backgroundColor = [UIColor clearColor];
    [PVideoConfig motionBlurView:_actionView];
    
    _titleLabel = [UILabel new];
    self.titleLabel.textColor = kThemeGraryColor;
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.titleLabel.font = [UIFont systemFontOfSize:16];
    self.titleLabel.text = @"小视频";
    [_actionView addSubview:self.titleLabel];
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.actionView);
        make.height.offset(topBarHeight);
        make.top.offset(btnTopEdge);
    }];
    
    _leftBtn = [[PCloseBtn alloc] initWithFrame:CGRectMake(0, btnTopEdge, 60, topBarHeight)];
    _leftBtn.backgroundColor = [UIColor clearColor];
    [_leftBtn addTarget:self action:@selector(closeViewAction) forControlEvents:UIControlEventTouchUpInside];
    _leftBtn.gradientColors = [PVideoConfig gradualColors];
    [_actionView addSubview:_leftBtn];
    
    _rightBtn = [[UIButton alloc] initWithFrame:CGRectMake(_actionView.frame.size.width - 60, btnTopEdge, 60, topBarHeight)];
    [_rightBtn setTitle:@"编辑" forState: UIControlStateNormal];
    [_rightBtn setTitle:@"完成" forState: UIControlStateSelected];
    [_rightBtn setTitleColor:kThemeTineColor forState:UIControlStateNormal];
    [_rightBtn setTitleColor:kThemeTineColor forState:UIControlStateSelected];
    [_rightBtn addTarget:self action:@selector(editVideosAction) forControlEvents:UIControlEventTouchUpInside];
    CAGradientLayer *gradLayer = [CAGradientLayer layer];
    gradLayer.frame = _rightBtn.bounds;
    gradLayer.colors = [PVideoConfig gradualColors];
    [_rightBtn.layer addSublayer:gradLayer];
    gradLayer.mask = _rightBtn.titleLabel.layer;
    [_actionView addSubview:_rightBtn];
}

static NSString *cellId = @"Cell";
static NSString *addCellId = @"AddCell";
static NSString *footerId = @"footer";

- (void)setupCollectionView
{
    CGFloat btnTopEdge = _showType == PVideoViewShowTypeSingle ? 20:0;

    self.dataArr = [NSMutableArray arrayWithArray:[PVideoUtil getSortVideoList]];
    CGFloat itemWidth = (_actionView.frame.size.width - 40)/3;

    UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:[CGLayout createLayoutItemW:itemWidth itemH:itemWidth/customVideo_W_H sectionInset:UIEdgeInsetsMake(10, 8, 10, 8) minimumLineSpacing:8 minimumInteritemSpacing:0 scrollDirection:UICollectionViewScrollDirectionVertical]];
    collectionView.delegate = self;
    collectionView.dataSource = self;
    [collectionView registerClass:[PVideoListCell class] forCellWithReuseIdentifier:cellId];
    [collectionView registerClass:[PAddNewVideoCell class] forCellWithReuseIdentifier:addCellId];
    [collectionView registerClass:[UICollectionReusableView class] forSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:footerId];
    collectionView.backgroundColor = [UIColor clearColor];
    [self.actionView addSubview:collectionView];
    self.collectionView = collectionView;
    [collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.actionView);
        make.top.equalTo(self.titleLabel.mas_bottom);
        make.bottom.equalTo(self.actionView.mas_bottom).offset(-btnTopEdge);
    }];
}

#pragma mark ---------------> Actions
- (void)closeViewAction
{
    [self closeAnimation];
}

- (void)editVideosAction
{
    _rightBtn.selected = !_rightBtn.selected;
    [_collectionView reloadData];
}

#pragma mark ---------------> UICollectionViewDataSource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (_rightBtn.selected)
    {
        return self.dataArr.count;
    }
    else
    {
        return self.dataArr.count+1;
    }
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.item == self.dataArr.count)
    {
        PAddNewVideoCell *addCell = [collectionView dequeueReusableCellWithReuseIdentifier:addCellId forIndexPath:indexPath];
        return addCell;
    }
    
    PVideoListCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellId forIndexPath:indexPath];
    PVideoModel *model = self.dataArr[indexPath.item];
    cell.videoModel = model;
    [cell setEdit:_rightBtn.selected];
    __weak typeof(self) blockSelf = self;
    __weak typeof(collectionView) blockCollection = collectionView;
    cell.deleteVideoBlock = ^(PVideoModel *cellModel){
        
        NSInteger index = [blockSelf.dataArr indexOfObject:cellModel];
        NSIndexPath *cellIndexPath = [NSIndexPath indexPathForItem:index inSection:0];
        [blockSelf.dataArr removeObject:cellModel];
        [blockCollection deleteItemsAtIndexPaths:@[cellIndexPath]];
        [PVideoUtil deleteVideo:cellModel.videoAbsolutePath];
        
    };
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    if ([kind isEqualToString:UICollectionElementKindSectionFooter])
    {
        
        UICollectionReusableView *footerView = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:footerId forIndexPath:indexPath];
        if (footerView.subviews.count < 1)
        {
            PVideoModel *lastVideo = _dataArr.lastObject;
            NSTimeInterval time = [[NSDate date] timeIntervalSinceDate:lastVideo.recordTime];
            if (time < 0)
            {
                time = 0;
            }
            NSInteger day = time/60/60/24 + 1;
            
            UILabel *label = [UILabel new];
            label.textColor = kThemeGraryColor;
            label.font = [UIFont systemFontOfSize:14];
            label.textAlignment = NSTextAlignmentCenter;
            label.text = [NSString stringWithFormat:@"最近 %ld 天拍摄的小视频",(long)day];
            label.alpha = 0.6;
            [footerView addSubview:label];
            [label mas_makeConstraints:^(MASConstraintMaker *make) {
                make.left.right.top.equalTo(footerView);
                make.height.offset(20);
            }];
        }
        return footerView;
    }
    return [[UICollectionReusableView alloc] init];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section
{
    return CGSizeMake(CGRectGetWidth(_actionView.frame), 20);
}

#pragma mark ---------------> UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.item == self.dataArr.count)
    {
        [self closeAnimation];
    }
    else
    {
        if (self.selectBlock)
        {
            self.selectBlock(self.dataArr[indexPath.item]);
        }
        [self closeAnimation];
    }
}

@end

