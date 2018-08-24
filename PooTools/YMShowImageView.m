//
//  YMShowImageView.m
//  WFCoretext
//
//  Created by 阿虎 on 14/11/3.
//  Copyright (c) 2014年 tigerwf. All rights reserved.
//

#import "YMShowImageView.h"

#import "SDWebImage/UIImageView+WebCache.h"
#import "UIView+ModifyFrame.h"
#import "ALActionSheetView.h"
#import "PMacros.h"
#import <Masonry/Masonry.h>
#import "HZWaitingView.h"

#define kMinZoomScale 0.6f
#define kMaxZoomScale 2.0f

#define hIndexTitleHeight 30
#define cIndexTitleBackgroundColor [UIColor colorWithRed:0.1f green:0.1f blue:0.1f alpha:0.3f]
#define SubViewBasicsIndex 888

typedef NS_ENUM(NSInteger,MoreActionType){
    MoreActionTypeNoMore = 0,
    MoreActionTypeMoreNormal,
    MoreActionTypeOnlySave,
    MoreActionTypeOnlyDelete
};

@interface YMShowImageView ()<NSURLConnectionDataDelegate, NSURLConnectionDelegate>

@property (nonatomic, strong) UIImageView *nilViews;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) NSMutableArray *imageScrollViews;
@property (nonatomic, assign) NSInteger page;
@property (nonatomic, strong) NSString *loadingImageName;
@property (nonatomic, strong) NSMutableArray *modelArr;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *infoLabel;
@property (nonatomic, strong) UIWindow *window;
@property (nonatomic, assign) NSInteger viewClickTag;
@property (nonatomic, strong) UIButton *deleteButton;
@property (nonatomic, strong) UIButton *saveImageButton;
@property (nonatomic, strong) UIColor *showImageBackgroundColor;
@property (nonatomic, strong) UIColor *titleColor;
@property (nonatomic, strong) NSString *fontName;
@property (nonatomic, assign) MoreActionType moreType;
@property (nonatomic, strong) NSArray *actionSheetOtherBtnArr;
@property (nonatomic, strong) NSString *moreActionImageNames;
@property (nonatomic, strong) UILabel *indexLabel;
@property (nonatomic, strong) UILabel *fullViewLabel;
@property (nonatomic, assign) CGFloat navH;
@end

@implementation YMShowImageView

-(id)initWithByClick:(NSInteger)clickTag appendArray:(NSArray <PooShowImageModel*>*)appendArray titleColor:(UIColor *)tC fontName:(NSString *)fName currentPageIndicatorTintColor:(UIColor *)cpic pageIndicatorTintColor:(UIColor *)pic showImageBackgroundColor:(UIColor *)sibc showWindow:(UIWindow *)w loadingImageName:(NSString *)li deleteAble:(BOOL)canDelete saveAble:(BOOL)canSave moreActionImageName:(NSString *)main
{
    self = [super init];
    if (self)
    {
        if (canDelete == YES && canSave == YES)
        {
            self.moreType = MoreActionTypeMoreNormal;
            self.actionSheetOtherBtnArr = @[@"保存图片",@"删除图片"];
            self.saveImageArr = [[NSMutableArray alloc] init];
        }
        else if (canDelete == NO && canSave == YES)
        {
            self.moreType = MoreActionTypeOnlySave;
            self.actionSheetOtherBtnArr = @[@"保存图片"];
            self.saveImageArr = [[NSMutableArray alloc] init];
        }
        else if (canDelete == YES && canSave == NO)
        {
            self.moreType = MoreActionTypeOnlyDelete;
            self.actionSheetOtherBtnArr = @[@"删除图片"];
        }
        else
        {
            self.moreType = MoreActionTypeNoMore;
            self.actionSheetOtherBtnArr = nil;
        }
    
        self.titleColor = tC;
        self.fontName = fName;
        currentPageIndicatorTintColor = cpic;
        pageIndicatorTintColor = pic;
        self.showImageBackgroundColor = sibc;
        self.window = w;
        self.loadingImageName = li;
        self.moreActionImageNames = main;
        
        self.alpha = 0.0f;
        self.page = 0;
        
        [self configScrollViewWith:clickTag andAppendArray:appendArray];
        
        self.modelArr = [[NSMutableArray alloc] init];
        [self.modelArr addObjectsFromArray:appendArray];
        
        UITapGestureRecognizer *tapGser = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(disappear)];
        tapGser.numberOfTouchesRequired = 1;
        tapGser.numberOfTapsRequired = 1;
        [self addGestureRecognizer:tapGser];
    }
    return self;
    
}

- (void)configScrollViewWith:(NSInteger)clickTag andAppendArray:(NSArray<PooShowImageModel *> *)appendArray
{
    self.viewClickTag = clickTag;
    
    self.page = self.viewClickTag - YMShowImageViewClickTagAppend;

    self.scrollView = [UIScrollView new];
    self.scrollView.backgroundColor = kClearColor;
    self.scrollView.pagingEnabled = true;
    self.scrollView.delegate = self;
    self.scrollView.showsVerticalScrollIndicator = NO;
    self.scrollView.showsHorizontalScrollIndicator = NO;
    [self addSubview:self.scrollView];
    
    self.imageScrollViews = [[NSMutableArray alloc] init];
    
    if (kDevice_Is_iPhoneX)
    {
        self.navH = HEIGHT_IPHONEXNAVBAR;
    }
    else
    {
        self.navH = HEIGHT_NAVBAR;
    }
    
    self.indexLabel = [[UILabel alloc] init];
    self.indexLabel.textAlignment = NSTextAlignmentCenter;
    self.indexLabel.textColor = [UIColor whiteColor];
    self.indexLabel.font = kDEFAULT_FONT(self.fontName, 20);
    self.indexLabel.backgroundColor = cIndexTitleBackgroundColor;
    self.indexLabel.bounds = CGRectMake(0, kScreenStatusBottom + (self.navH - kScreenStatusBottom - 30)/2, 80, hIndexTitleHeight);
    self.indexLabel.center = CGPointMake(kSCREEN_WIDTH * 0.5, hIndexTitleHeight);
    self.indexLabel.layer.cornerRadius = 15;
    self.indexLabel.clipsToBounds = YES;
    if (appendArray.count > 1) {
        _indexLabel.text = [NSString stringWithFormat:@"1/%ld", (long)appendArray.count];
        [self addSubview:self.indexLabel];
    }
    
    self.fullViewLabel = [[UILabel alloc] init];
    self.fullViewLabel.textAlignment = NSTextAlignmentCenter;
    self.fullViewLabel.textColor = [UIColor whiteColor];
    self.fullViewLabel.font = kDEFAULT_FONT(self.fontName, 20);
    self.fullViewLabel.text = @"全景";
    self.fullViewLabel.backgroundColor = cIndexTitleBackgroundColor;
    self.fullViewLabel.frame = CGRectMake(kSCREEN_WIDTH-50-20, self.indexLabel.top, 50, hIndexTitleHeight);
    self.fullViewLabel.layer.cornerRadius = 15;
    self.fullViewLabel.clipsToBounds = YES;
    [self addSubview:self.fullViewLabel];
    self.fullViewLabel.hidden = YES;
}

-(void)removeFromSuperview
{
    [super removeFromSuperview];
    self.nilViews = nil;
}

- (void)disappear
{
    if (_removeImg)
    {
        _removeImg();
    }
}

- (CGRect)zoomRectForScale:(CGFloat)newscale withCenter:(CGPoint)center andScrollView:(UIScrollView *)scrollV
{
    CGRect zoomRect = CGRectZero;
    
    zoomRect.size.height = scrollV.height / newscale;
    zoomRect.size.width = scrollV.width  / newscale;
    zoomRect.origin.x = center.x - (zoomRect.size.width  / 2.0);
    zoomRect.origin.y = center.y - (zoomRect.size.height / 2.0);
    // NSLog(@" === %f",zoomRect.origin.x);
    return zoomRect;
}

- (void)showWithFinish:(didRemoveImage)tempBlock{
    UIView *maskview = [UIView new];
    maskview.backgroundColor = self.showImageBackgroundColor;
    [self.window addSubview:maskview];
    [maskview mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.top.bottom.equalTo(self.window);
    }];
    
    [self show:maskview didFinish:^{
        [UIView animateWithDuration:0.5f animations:^{
            self.alpha = 0.0f;
            maskview.alpha = 0.0f;
        } completion:^(BOOL finished) {
            if (tempBlock)
            {
                tempBlock();
            }
            [self removeFromSuperview];
            [maskview removeFromSuperview];
            self.nilViews = nil;
            self.scrollView = nil;
            self.imageScrollViews = nil;
            
        }];
    }];
}

- (void)show:(UIView *)bgView didFinish:(didRemoveImage)tempBlock
{
    [bgView addSubview:self];
    [self.scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.top.bottom.equalTo(bgView);
    }];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.scrollView.contentSize = CGSizeMake(self.width * self.modelArr.count, 0);
        
        float W = self.width;
        
        for (int i = 0; i < self.modelArr.count; i ++)
        {
            PooShowImageModel *model = self.modelArr[i];
            
            PShowImageSingleView *imageScroll = [[PShowImageSingleView alloc] initWithFrame:CGRectMake(self.width*i, 0, self.width, self.height)];
            imageScroll.isFullWidthForLandScape = NO;
            [imageScroll setImageWithModel:model placeholderImage:kImageNamed(self.loadingImageName)];
            imageScroll.tag = SubViewBasicsIndex+i;
            [self.scrollView addSubview:imageScroll];
            [self.imageScrollViews addObject:imageScroll];
        }
        [self.scrollView setContentOffset:CGPointMake(W * (self.viewClickTag - YMShowImageViewClickTagAppend), 0) animated:YES];
        
        self.fullViewLabel.hidden = [self fullImageHidden];
        
        PooShowImageModel *model = self.modelArr[0];
        
        self.titleLabel = [UILabel new];
        self.titleLabel.textAlignment = NSTextAlignmentLeft;
        self.titleLabel.textColor     = self.titleColor;
        self.titleLabel.numberOfLines = 0;
        self.titleLabel.lineBreakMode = NSLineBreakByCharWrapping;
        self.titleLabel.font = kDEFAULT_FONT(self.fontName, 16);
        self.titleLabel.text          = model.imageTitle;
        self.titleLabel.hidden        = self.titleLabel.text.length == 0;
        [self addSubview:self.titleLabel];
        [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self).offset(10);
            make.bottom.equalTo(self).offset(-40);
            make.height.offset(40);
            make.right.equalTo(self).offset(-110);
        }];
        
        self.infoLabel = [UILabel new];
        self.infoLabel.textAlignment = NSTextAlignmentLeft;
        self.infoLabel.textColor     = self.titleColor;
        self.infoLabel.numberOfLines = 0;
        self.infoLabel.lineBreakMode = NSLineBreakByCharWrapping;
        self.infoLabel.font = kDEFAULT_FONT(self.fontName, 16);
        self.infoLabel.text          = model.imageInfo;
        self.infoLabel.hidden        = self.infoLabel.text.length == 0;
        [self addSubview:self.infoLabel];
        [self.infoLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.height.right.equalTo(self.titleLabel);
            make.bottom.equalTo(self);
        }];
        
        switch (self.moreType)
        {
            case MoreActionTypeNoMore:
                break;
            default:
            {
                self.deleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
                self.deleteButton.showsTouchWhenHighlighted = YES;
                [self.deleteButton setImage:kImageNamed(self.moreActionImageNames) forState:UIControlStateNormal];
                [self.deleteButton addTarget:self action:@selector(removeCurrImage) forControlEvents:UIControlEventTouchUpInside];
                [self addSubview:self.deleteButton];
                [self.deleteButton mas_makeConstraints:^(MASConstraintMaker *make) {
                    make.width.height.offset(44);
                    make.right.bottom.equalTo(self).offset(-10);
                }];
            }
                break;
        }
    });
    
    _removeImg = tempBlock;
    
    [UIView animateWithDuration:.4f animations:^(){
        
        self.alpha = 1.0f;
        
    } completion:^(BOOL finished) {
        
    }];
}

-(void)layoutSubviews
{
    [super layoutSubviews];
    
    [self.scrollView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.left.right.top.bottom.equalTo(self);
    }];
    self.scrollView.contentSize = CGSizeMake(self.width * self.modelArr.count, 0);
    for (int i = 0; i < self.modelArr.count; i ++)
    {
        PShowImageSingleView *imageScrollView = (PShowImageSingleView *)[self.scrollView viewWithTag:SubViewBasicsIndex+i];
        [imageScrollView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.left.offset(self.width*i);
            make.top.offset(0);
            make.width.offset(self.width);
            make.height.offset(self.height);
        }];
    }
    [self.scrollView setContentOffset:CGPointMake(self.width * self.page, 0) animated:YES];
    
    if (self.modelArr.count > 1) {
        [self.indexLabel mas_updateConstraints:^(MASConstraintMaker *make) {
            make.width.offset(80);
            make.height.offset(hIndexTitleHeight);
            make.top.equalTo(self).offset(kScreenStatusBottom + (self.navH - kScreenStatusBottom - hIndexTitleHeight)/2);
            make.centerX.equalTo(self.mas_centerX);
        }];
        
        [self.fullViewLabel mas_updateConstraints:^(MASConstraintMaker *make) {
            make.width.offset(50);
            make.height.offset(hIndexTitleHeight);
            make.top.equalTo(self.indexLabel);
            make.right.equalTo(self).offset(-20);
        }];
    }
}

-(BOOL)fullImageHidden
{
    PooShowImageModel *model = self.modelArr[self.page];
    if ([model.imageFullView isEqualToString:@"1"]) {
        return NO;
    }
    else
    {
        return YES;
    }
}

#pragma mark - ScorllViewDelegate
-(void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (scrollView == self.scrollView)
    {
        int page = (scrollView.contentOffset.x)/scrollView.width;
        self.page = page;
        self.indexLabel.text = [NSString stringWithFormat:@"%d/%ld", page + 1, (long)self.modelArr.count];
        
        self.fullViewLabel.hidden = [self fullImageHidden];
        
        if (scrollView == self.scrollView)
        {
            PooShowImageModel *model = self.modelArr[page];
            self.titleLabel.text = model.imageTitle;
            self.infoLabel.text = model.imageInfo;
        }
    }
}

- (CGPoint)centerOfScrollViewContent:(UIScrollView *)scrollView
{
    CGFloat offsetX = (scrollView.bounds.size.width > scrollView.contentSize.width)?
    (scrollView.bounds.size.width - scrollView.contentSize.width) * 0.5 : 0.0;
    CGFloat offsetY = (scrollView.bounds.size.height > scrollView.contentSize.height)?
    (scrollView.bounds.size.height - scrollView.contentSize.height) * 0.5 : 0.0;
    CGPoint actualCenter = CGPointMake(scrollView.contentSize.width * 0.5 + offsetX,
                                       scrollView.contentSize.height * 0.5 + offsetY);
    return actualCenter;
}

#pragma mark - ----> 保存图片
-(void)saveImage
{
    NSInteger index = self.page;
    PooShowImageModel *model = self.modelArr[index];
    if ([model.imageFullView isEqualToString:@"1"])
    {
        PShowImageSingleView *currentView = self.imageScrollViews[index];
        if (currentView.hasLoadedImage)
        {
            UIImage *fullImage = (UIImage *)currentView.sphere.firstMaterial.diffuse.contents;
            [self saveImageToPhotos:fullImage];
        }
        else
        {
            if (self.saveImageStatus)
            {
                self.saveImageStatus(NO);
            }
        }
    }
    else
    {
        PShowImageSingleView *currentView = self.imageScrollViews[index];
        if (currentView.hasLoadedImage)
        {
            [self saveImageToPhotos:currentView.imageview.image];
        }
        else
        {
            if (self.saveImageStatus)
            {
                self.saveImageStatus(NO);
            }
        }
    }
}

- (void)saveImageToPhotos:(UIImage*)savedImage
{
    UIImageWriteToSavedPhotosAlbum(savedImage, self, @selector(image:didFinishSavingWithError:contextInfo:), NULL);
    //因为需要知道该操作的完成情况，即保存成功与否，所以此处需要一个回调方法image:didFinishSavingWithError:contextInfo:
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
    BOOL saveimageAction;
    if(error != NULL)
    {
        saveimageAction = NO;
    }
    else
    {
        saveimageAction = YES;
    }
    if (self.saveImageStatus)
    {
        self.saveImageStatus(saveimageAction);
    }
}

#pragma mark - ----> 删除图片
- (void)removeCurrImage
{
    ALActionSheetView *actionSheetView = [ALActionSheetView showActionSheetWithTitle:@"图片操作"
                                                                   cancelButtonTitle:@"取消"
                                                              destructiveButtonTitle:nil
                                                                   otherButtonTitles:self.actionSheetOtherBtnArr
                                                                      buttonFontName:self.fontName
                                                                             handler:^(ALActionSheetView *actionSheetView, NSInteger buttonIndex)
                                          {
                                              switch (self.moreType)
                                              {
                                                  case MoreActionTypeOnlyDelete:
                                                  {
                                                      if (buttonIndex == 0)
                                                      {
                                                          [self deleteImage];
                                                      }
                                                  }
                                                      break;
                                                  case MoreActionTypeOnlySave:
                                                  {
                                                      if (buttonIndex == 0)
                                                      {
                                                          [self saveImage];
                                                      }
                                                  }
                                                      break;
                                                  case MoreActionTypeMoreNormal:
                                                  {
                                                      switch (buttonIndex)
                                                      {
                                                          case 0:
                                                          {
                                                              [self saveImage];
                                                          }
                                                              break;
                                                          case 1:
                                                          {
                                                              [self deleteImage];
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
                                          }];
    [actionSheetView show];
}

-(void)deleteImage
{
    NSInteger index = self.page;
    
    if (self.didDeleted)
    {
        self.didDeleted(self,index);
    }
    
    if (_scrollView.subviews.count == 1 && self.imageScrollViews.count == 1)
    {
        [self disappear];
    }
    else
    {
        [UIView animateWithDuration:0.1 animations:^{
            [self.scrollView.subviews[index] removeFromSuperview];
            self.scrollView.contentSize = CGSizeMake(self.scrollView.contentSize.width - kSCREEN_WIDTH, self.scrollView.contentSize.height);
            NSInteger newIndex = index - 1;
            if (newIndex < 0)
            {
                newIndex = 1;
            }
            else
            {
                newIndex = index - 1;
            }
            self.scrollView.contentOffset = CGPointMake(newIndex * self.scrollView.frame.size.width, 0);
            [self.modelArr removeObjectAtIndex:index];
            [self.imageScrollViews removeObjectAtIndex:index];
            if (self.modelArr.count > 1)
            {
                int textIndex = self.scrollView.contentOffset.x / self.scrollView.bounds.size.width;
                self.indexLabel.text = [NSString stringWithFormat:@"%d/%ld",textIndex,(long)self.modelArr.count];
            }
            else
            {
                [self.indexLabel removeFromSuperview];
            }
        }];
        [self layoutIfNeeded];
    }
}

@end

@interface PShowImageSingleView() <UIScrollViewDelegate>
@property (nonatomic, strong) HZWaitingView *waitingView;
@property (nonatomic, strong) PooShowImageModel *imageModels;
@property (nonatomic, strong) UIImage *placeHolderImage;
@property (nonatomic, strong) UIButton *reloadButton;
@property (nonatomic, strong) SCNView *sceneView;
@end

@implementation PShowImageSingleView
#pragma mark recyle
- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self addSubview:self.scrollview];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    CGFloat selfW = self.bounds.size.width;
    CGFloat selfH = self.bounds.size.height;
    _waitingView.center = CGPointMake(selfW * 0.5, selfH * 0.5);
    _scrollview.frame = self.bounds;
    CGFloat reloadBtnW = 200;
    CGFloat reloadBtnH = 40;
    _reloadButton.frame = CGRectMake((selfW - reloadBtnW)*0.5, (selfH - reloadBtnH)*0.5, reloadBtnW, reloadBtnH);
    [self adjustFrame];
}

#pragma mark getter setter
- (UIScrollView *)scrollview
{
    if (!_scrollview) {
        _scrollview = [[UIScrollView alloc] init];
        _scrollview.frame = CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height);
        _scrollview.showsVerticalScrollIndicator = NO;
        _scrollview.showsHorizontalScrollIndicator = NO;
        _scrollview.delegate = self;
        _scrollview.clipsToBounds = YES;
    }
    return _scrollview;
}

- (UIImageView *)imageview
{
    if (!_imageview) {
        _imageview = [[UIImageView alloc] init];
        _imageview.frame = CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height);
        _imageview.userInteractionEnabled = YES;
    }
    return _imageview;
}

- (void)setProgress:(CGFloat)progress
{
    _progress = progress;
    _waitingView.progress = progress;
}

#pragma mark public methods
- (void)setImageWithModel:(PooShowImageModel *)model placeholderImage:(UIImage *)placeholder
{
    _imageModels = model;
    _placeHolderImage = placeholder;
    
    CGFloat navH = 0.0f;
    if (kDevice_Is_iPhoneX)
    {
        navH = HEIGHT_IPHONEXNAVBAR;
    }
    else
    {
        navH = HEIGHT_NAVBAR;
    }
    
    if ([model.imageFullView isEqualToString:@"1"]) {
        
        self.sceneView = [SCNView new];
        [_scrollview addSubview:self.sceneView];
        [self.sceneView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.equalTo(self);
            make.height.offset(self.height-navH-80);
            make.top.equalTo(self).offset(navH);
        }];
        
        self.sceneView.scene = [[SCNScene alloc] init];
        self.sceneView.showsStatistics = NO;
        self.sceneView.allowsCameraControl = YES;
        
        self.sphere =   [SCNSphere sphereWithRadius:20.0];
        self.sphere.firstMaterial.doubleSided = YES;
        
        kWeakSelf(self);
        [[SDWebImageManager sharedManager] loadImageWithURL:[NSURL URLWithString:model.imageUrl] options:0 progress:^(NSInteger receivedSize, NSInteger expectedSize, NSURL * _Nullable targetURL) {
            dispatch_async(dispatch_get_main_queue(), ^{
                weakself.waitingView.progress = (CGFloat)receivedSize / expectedSize;
            });
        } completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, SDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL) {
            [self.waitingView removeFromSuperview];
            GCDWithMain(^{
                self.sphere.firstMaterial.diffuse.contents = image;
                weakself.hasLoadedImage = YES;//图片加载成功
            });
        }];
        SCNNode *sphereNode = [SCNNode nodeWithGeometry:self.sphere];
        sphereNode.position = SCNVector3Make(0,0,0);
        [self.sceneView.scene.rootNode addChildNode:sphereNode];
        _scrollview.contentSize = CGSizeMake(self.width, self.height);
        
        [self setNeedsLayout];
    }
    else
    {
        self.imageview = [UIImageView new];
        NSString *imageURLString = model.imageUrl;
        self.imageview.contentMode = UIViewContentModeScaleAspectFit;
        
        id urlObject;
        if (imageURLString) {
            if ([imageURLString isKindOfClass:[NSString class]]) {
                urlObject = imageURLString;
            }else if([imageURLString isKindOfClass:[NSURL class]]){
                urlObject = imageURLString;
            }else if([imageURLString isKindOfClass:[UIImage class]]){
            }
        }
        
        [_scrollview addSubview:self.imageview];
        
        kWeakSelf(self);
        [_imageview sd_setImageWithURL:urlObject placeholderImage:placeholder options:SDWebImageRetryFailed progress:^(NSInteger receivedSize, NSInteger expectedSize, NSURL * _Nullable targetURL) {
            //在主线程做UI更新
            dispatch_async(dispatch_get_main_queue(), ^{
                weakself.waitingView.progress = (CGFloat)receivedSize / expectedSize;
            });
            
        } completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
            [weakself.waitingView removeFromSuperview];
            
            if (error) {
                //图片加载失败的处理，此处可以自定义各种操作（...）
                weakself.hasLoadedImage = NO;//图片加载失败
                UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
                weakself.reloadButton = button;
                button.layer.cornerRadius = 2;
                button.clipsToBounds = YES;
                button.titleLabel.font = [UIFont systemFontOfSize:14];
                button.backgroundColor = [UIColor colorWithRed:0.1f green:0.1f blue:0.1f alpha:0.3f];
                [button setTitle:@"图片加载失败，点击重新加载" forState:UIControlStateNormal];
                [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
                [button addTarget:weakself action:@selector(reloadImage) forControlEvents:UIControlEventTouchUpInside];
                
                [self addSubview:button];
                return;
            }
            //加载成功重新计算frame,解决长图可能显示不正确的问题
            [self setNeedsLayout];
            weakself.hasLoadedImage = YES;//图片加载成功
        }];
    }
}

#pragma mark private methods
- (void)reloadImage
{
    [self setImageWithModel:_imageModels placeholderImage:_placeHolderImage];
}

- (void)adjustFrame
{
    CGFloat navH = 0.0f;
    if (kDevice_Is_iPhoneX)
    {
        navH = HEIGHT_IPHONEXNAVBAR;
    }
    else
    {
        navH = HEIGHT_NAVBAR;
    }
    CGRect frame = self.frame;
    if (self.imageview.image) {
        CGSize imageSize = self.imageview.image.size;//获得图片的size
        CGRect imageFrame = CGRectMake(0, 0, imageSize.width, imageSize.height);
        if (_isFullWidthForLandScape) {//图片宽度始终==屏幕宽度(新浪微博就是这种效果)
            CGFloat ratio = frame.size.width/imageFrame.size.width;
            imageFrame.size.height = imageFrame.size.height*ratio;
            imageFrame.size.width = frame.size.width;
        } else{
            if (frame.size.width<=frame.size.height) {
                //竖屏时候
                CGFloat ratio = frame.size.width/imageFrame.size.width;
                imageFrame.size.height = imageFrame.size.height*ratio;
                imageFrame.size.width = frame.size.width;
            }else{ //横屏的时候
                CGFloat ratio = frame.size.height/imageFrame.size.height;
                imageFrame.size.width = imageFrame.size.width*ratio;
                imageFrame.size.height = frame.size.height;
            }
        }
        
        self.imageview.frame = imageFrame;
        self.scrollview.contentSize = self.imageview.frame.size;
        self.imageview.center = [self centerOfScrollViewContent:self.scrollview];
        
        //根据图片大小找到最大缩放等级，保证最大缩放时候，不会有黑边
        CGFloat maxScale = frame.size.height/imageFrame.size.height;
        maxScale = frame.size.width/imageFrame.size.width>maxScale?frame.size.width/imageFrame.size.width:maxScale;
        //超过了设置的最大的才算数
        maxScale = maxScale>kMaxZoomScale?maxScale:kMaxZoomScale;
        //初始化
        self.scrollview.minimumZoomScale = kMinZoomScale;
        self.scrollview.maximumZoomScale = maxScale;
        self.scrollview.zoomScale = 1.0f;
    }
    else
    {
        frame.origin = CGPointZero;
        self.imageview.frame = frame;
        self.sceneView.frame = frame;
        //重置内容大小
        self.scrollview.contentSize = self.imageview.frame.size;
    }
    self.scrollview.contentOffset = CGPointZero;
    self.zoomImageSize = self.imageview.frame.size;
    [self.sceneView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self);
        make.height.offset(self.height-navH-80);
        make.top.equalTo(self).offset(navH);
    }];
}

- (CGPoint)centerOfScrollViewContent:(UIScrollView *)scrollView
{
    CGFloat offsetX = (scrollView.bounds.size.width > scrollView.contentSize.width)?
    (scrollView.bounds.size.width - scrollView.contentSize.width) * 0.5 : 0.0;
    CGFloat offsetY = (scrollView.bounds.size.height > scrollView.contentSize.height)?
    (scrollView.bounds.size.height - scrollView.contentSize.height) * 0.5 : 0.0;
    CGPoint actualCenter = CGPointMake(scrollView.contentSize.width * 0.5 + offsetX,
                                       scrollView.contentSize.height * 0.5 + offsetY);
    return actualCenter;
}

#pragma mark UIScrollViewDelegate
- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.imageview;
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(CGFloat)scale{
    self.zoomImageSize = view.frame.size;
    self.scrollOffset = scrollView.contentOffset;
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset{
    if(self.scrollViewWillEndDragging){
        self.scrollViewWillEndDragging(velocity, scrollView.contentOffset);
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    if (self.scrollViewDidEndDecelerating) {
        self.scrollViewDidEndDecelerating();
    }
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView //这里是缩放进行时调整
{
    self.imageview.center = [self centerOfScrollViewContent:scrollView];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    self.scrollOffset = scrollView.contentOffset;
    if (self.scrollViewDidScroll) {
        self.scrollViewDidScroll(self.scrollOffset);
    }
}
@end
