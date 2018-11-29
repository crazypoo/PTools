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
#import "Utils.h"
#import <AFNetworking/AFNetworking.h>

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

-(id)initWithByClick:(NSInteger)clickTag appendArray:(NSArray <PooShowImageModel*>*)appendArray titleColor:(UIColor *)tC fontName:(NSString *)fName showImageBackgroundColor:(UIColor *)sibc showWindow:(UIWindow *)w loadingImageName:(NSString *)li deleteAble:(BOOL)canDelete saveAble:(BOOL)canSave moreActionImageName:(NSString *)main
{
    self = [super init];
    if (self)
    {
        if (canDelete == YES && canSave == YES)
        {
            self.moreType = MoreActionTypeMoreNormal;
            self.actionSheetOtherBtnArr = @[@"保存图片",@"删除图片"];
//            self.saveImageArr = [[NSMutableArray alloc] init];
        }
        else if (canDelete == NO && canSave == YES)
        {
            self.moreType = MoreActionTypeOnlySave;
            self.actionSheetOtherBtnArr = @[@"保存图片"];
//            self.saveImageArr = [[NSMutableArray alloc] init];
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
    
        self.titleColor = tC ? tC : [UIColor whiteColor];
        self.fontName = fName ? fName : @"HelveticaNeue-Light";
        self.showImageBackgroundColor = sibc ? sibc : [UIColor blackColor];
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
    self.fullViewLabel.backgroundColor = cIndexTitleBackgroundColor;
    self.fullViewLabel.frame = CGRectMake(kSCREEN_WIDTH-50-20, self.indexLabel.top, 50, hIndexTitleHeight);
    self.fullViewLabel.layer.cornerRadius = 15;
    self.fullViewLabel.clipsToBounds = YES;
    [self addSubview:self.fullViewLabel];
}

-(void)removeFromSuperview
{
    [super removeFromSuperview];
    self.nilViews = nil;
}

- (void)disappear
{
    for (int i = 0 ; i < self.modelArr.count; i++) {
        PShowImageSingleView *currentImageS = (PShowImageSingleView *)[self.scrollView viewWithTag:SubViewBasicsIndex + i];
        switch (currentImageS.showMode) {
            case PShowModeGif:
            {
                [currentImageS.imageview stopAnimating];
            }
                break;
            case PShowModeVideo:
            {
                [currentImageS.player stop];
            }
            default:
                break;
        }
    }

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
            PShowImageSingleView *imageScroll = [[PShowImageSingleView alloc] initWithFrame:CGRectMake(self.width*i, 0, self.width, self.height)];
            imageScroll.isFullWidthForLandScape = NO;
            imageScroll.tag = SubViewBasicsIndex+i;
            [self.scrollView addSubview:imageScroll];
            [self.imageScrollViews addObject:imageScroll];
        }
        [self.scrollView setContentOffset:CGPointMake(W * (self.viewClickTag - YMShowImageViewClickTagAppend), 0) animated:YES];
        
        self.fullViewLabel.text = [self fullImageHidden];
//        if ([[self fullImageHidden] isEqualToString:@""])
//        {
//            self.fullViewLabel.hidden = YES;
//        }
//        else
//        {
//            self.fullViewLabel.hidden = NO;
//        }
        
        PooShowImageModel *model = self.modelArr[0];
        PShowImageSingleView *imageScroll = (PShowImageSingleView *)[self.scrollView viewWithTag:SubViewBasicsIndex+0];
        [imageScroll setImageWithModel:model];
        imageScroll.beginLoadingImage = YES;
        
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
        imageScrollView.tag = SubViewBasicsIndex+i;
        [imageScrollView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.left.offset(self.width*i);
            make.top.offset(0);
            make.width.offset(self.width);
            make.height.offset(self.height);
        }];
    }
    [self.scrollView setContentOffset:CGPointMake(self.width * self.page, 0) animated:YES];
    PooShowImageModel *model = self.modelArr[self.page];
    PShowImageSingleView *currentImageS = (PShowImageSingleView *)[self.scrollView viewWithTag:SubViewBasicsIndex + self.page];
    [currentImageS setImageWithModel:model];
    switch (currentImageS.showMode) {
        case PShowModeGif:
        {
            [currentImageS.imageview startAnimating];
        }
            break;
        case PShowModeVideo:
        {
            currentImageS.video1STImage.hidden = NO;
            currentImageS.playBtn.hidden = NO;
            currentImageS.stopBtn.hidden = YES;
            currentImageS.videoSlider.hidden = YES;
        }
        default:
            break;
    }

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

-(NSString *)fullImageHidden
{
    PooShowImageModel *model = self.modelArr[self.page];
    switch (model.imageShowType)
    {
        case PooShowImageModelTypeFullView:
        {
            return @"全景";
        }
            break;
        case PooShowImageModelTypeGIF:
        {
            return @"GIF";
        }
        case PooShowImageModelTypeVideo:
        {
            return @"视频";
        }
        default:
        {
            return @"普通";
        }
            break;
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
        
        self.fullViewLabel.text = [self fullImageHidden];
//        if ([[self fullImageHidden] isEqualToString:@""])
//        {
//            self.fullViewLabel.hidden = YES;
//        }
//        else
//        {
//            self.fullViewLabel.hidden = NO;
//        }
        
        PooShowImageModel *model = self.modelArr[page];
        self.titleLabel.text = model.imageTitle;
        self.infoLabel.text = model.imageInfo;
    
        for (int i = 0 ; i < self.modelArr.count; i++) {
            PShowImageSingleView *currentImageS = (PShowImageSingleView *)[self.scrollView viewWithTag:SubViewBasicsIndex + i];
            if (i == page) {
                switch (currentImageS.showMode) {
                    case PShowModeGif:
                        {
                            [currentImageS.imageview startAnimating];
                        }
                        break;
                    case PShowModeVideo:
                    {
                        currentImageS.video1STImage.hidden = NO;
                        currentImageS.playBtn.hidden = NO;
                        currentImageS.stopBtn.hidden = YES;
                        currentImageS.videoSlider.hidden = YES;
                    }
                    default:
                        break;
                }
            }
            else
            {
                switch (currentImageS.showMode) {
                    case PShowModeGif:
                    {
                        [currentImageS.imageview stopAnimating];
                    }
                        break;
                    case PShowModeVideo:
                    {
                        [currentImageS.player stop];
                    }
                    default:
                        break;
                }
            }
        }

        PShowImageSingleView *current = (PShowImageSingleView *)[self.scrollView viewWithTag:SubViewBasicsIndex + page];
        if (current.beginLoadingImage) return;
        [current setImageWithModel:model];
        current.beginLoadingImage = YES;
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
    if (model.imageShowType == PooShowImageModelTypeFullView)
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
            switch (currentView.showMode) {
                case PShowModeVideo:
                {
                    [self playerDownload:model.imageUrl withViews:currentView];
                }
                    break;
                default:
                {
                    [self saveImageToPhotos:currentView.imageview.image];
                }
                    break;
            }
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

- (void)playerDownload:(NSString *)url withViews:(PShowImageSingleView *)currentViews
{
    HZWaitingView *waitingView = [[HZWaitingView alloc] init];
    waitingView.mode = HZWaitingViewModeLoopDiagram;
    [currentViews.player.view addSubview:waitingView];
    [waitingView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.offset(currentViews.width * 0.5);
        make.height.offset(currentViews.height * 0.5);
        make.centerX.centerY.equalTo(currentViews.player.view);
    }];

    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    NSString  *fullPath = [NSString stringWithFormat:@"%@/%@", documentsDirectory, [NSString stringWithFormat:@"%@.mp4",[Utils getYMDHHS]]];
    NSURL *urlNew = [NSURL URLWithString:url];
    NSURLRequest *request = [NSURLRequest requestWithURL:urlNew];
    NSURLSessionDownloadTask *task =
    [manager downloadTaskWithRequest:request
                            progress:^(NSProgress * _Nonnull downloadProgress) {
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    waitingView.progress = downloadProgress.fractionCompleted;
                                });
                            }  destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
                                return [NSURL fileURLWithPath:fullPath];
                            }
                   completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
                       [waitingView removeFromSuperview];
                       [self saveVideo:fullPath];
                   }];
    [task resume];
}

- (void)saveVideo:(NSString *)videoPath{
    
    if (videoPath) {
        NSURL *url = [NSURL URLWithString:videoPath];
        BOOL compatible = UIVideoAtPathIsCompatibleWithSavedPhotosAlbum([url path]);
        if (compatible)
        {
            //保存相册核心代码
            UISaveVideoAtPathToSavedPhotosAlbum([url path], self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
        }
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
        for (int i = 0 ; i < self.modelArr.count; i++) {
            PShowImageSingleView *imageScroll = (PShowImageSingleView *)[self.scrollView viewWithTag:SubViewBasicsIndex+i];
            [imageScroll.player stop];
            [imageScroll removeFromSuperview];
        }
        
        [UIView animateWithDuration:0.1 animations:^{
            
            NSInteger newIndex = index - 1;
            if (newIndex < 0)
            {
                newIndex = 0;
            }
            else if (newIndex == 0)
            {
                newIndex = 0;
            }
            else
            {
                newIndex = index-1;
            }
            self.page = newIndex;

            self.scrollView.contentSize = CGSizeMake(self.imageScrollViews.count*kSCREEN_WIDTH, self.scrollView.contentSize.height);
            [self.scrollView setContentOffset:CGPointMake(self.page * kSCREEN_WIDTH, 0) animated:YES];
            [self.modelArr removeObjectAtIndex:index];
            [self.imageScrollViews removeAllObjects];

            for (int i = 0 ; i < self.modelArr.count; i++)
            {
                PShowImageSingleView *imageScroll = [[PShowImageSingleView alloc] initWithFrame:CGRectMake(self.width*i, 0, self.width, self.height)];
                imageScroll.isFullWidthForLandScape = NO;
                imageScroll.tag = SubViewBasicsIndex+i;
                [self.scrollView addSubview:imageScroll];
                [self.imageScrollViews addObject:imageScroll];
            }

            if (self.modelArr.count > 1)
            {
                int textIndex = self.scrollView.contentOffset.x / self.scrollView.bounds.size.width;
                if (textIndex == 0) {
                    textIndex = 1;
                }
                self.indexLabel.text = [NSString stringWithFormat:@"%d/%ld",textIndex,(long)self.modelArr.count];
            }
            else
            {
                [self.indexLabel removeFromSuperview];
            }
            [self layoutSubviews];
        }];
        if (self.didDeleted) {
            self.didDeleted(self, index);
        }
    }
}
@end

@interface PShowImageSingleView() <UIScrollViewDelegate>
{
    NSTimer *timer;
    CGFloat videoTime;
}
@property (nonatomic, strong) HZWaitingView *waitingView;
@property (nonatomic, strong) PooShowImageModel *imageModels;
@property (nonatomic, strong) UIImage *placeHolderImage;
@property (nonatomic, strong) UIButton *reloadButton;
@property (nonatomic, strong) SCNView *sceneView;
@property (nonatomic, strong) UIImage *loadImage;
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
    if (!_scrollview)
    {
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
    if (!_imageview)
    {
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
- (void)setImageWithModel:(PooShowImageModel *)model
{
    _imageModels = model;
    
//    dispatch_async(dispatch_get_main_queue(), ^{
        HZWaitingView *waitingView = [[HZWaitingView alloc] init];
        waitingView.mode = HZWaitingViewModeLoopDiagram;
        waitingView.center = CGPointMake(self.bounds.size.width * 0.5, self.bounds.size.height * 0.5);
//        self.waitingView = waitingView;
//    });
    
    CGFloat navH = 0.0f;
    if (kDevice_Is_iPhoneX)
    {
        navH = HEIGHT_IPHONEXNAVBAR;
    }
    else
    {
        navH = HEIGHT_NAVBAR;
    }
    
    if (model.imageShowType == PooShowImageModelTypeFullView)
    {
        if (!waitingView) {
            [self addSubview:waitingView];
        }

        kWeakSelf(self);
        [[SDWebImageManager sharedManager] loadImageWithURL:[NSURL URLWithString:model.imageUrl] options:0 progress:^(NSInteger receivedSize, NSInteger expectedSize, NSURL * _Nullable targetURL) {
            dispatch_async(dispatch_get_main_queue(), ^{
                weakself.waitingView.progress = (CGFloat)receivedSize / (CGFloat)expectedSize;
            });
        } completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, SDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL) {
            [waitingView removeFromSuperview];
//            waitingView = nil;
            self.showMode = PShowModeFullView;
            self.sceneView = [SCNView new];
            [self.scrollview addSubview:self.sceneView];
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
                [button addTarget:self action:@selector(reloadImage) forControlEvents:UIControlEventTouchUpInside];
                [self addSubview:button];
                return;
            }

            self.sphere.firstMaterial.diffuse.contents = image;
            weakself.hasLoadedImage = YES;//图片加载成功
            
            SCNNode *sphereNode = [SCNNode nodeWithGeometry:self.sphere];
            sphereNode.position = SCNVector3Make(0,0,0);
            [self.sceneView.scene.rootNode addChildNode:sphereNode];
            self.scrollview.contentSize = CGSizeMake(self.width, self.height);
        }];
        
//        [self setNeedsLayout];
    }
    else
    {
        [waitingView removeFromSuperview];
        
        self.showMode = PShowModeVideo;
        
        NSURL *videoUrl;
        if([Utils contentTypeForUrlString:model.imageUrl] == ToolsUrlStringVideoTypeMP4) {
            if ([model.imageUrl rangeOfString:@"/var"].length>0)
            {
                videoUrl = [NSURL fileURLWithPath:model.imageUrl];
            }
            else
            {
                videoUrl = [NSURL URLWithString:[model.imageUrl stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
            }
            self.player = [[MPMoviePlayerController alloc] initWithContentURL:videoUrl];
            self.player.controlStyle = MPMovieControlStyleNone;
            self.player.shouldAutoplay = YES;
            self.player.repeatMode = MPMovieRepeatModeNone;
            [self.player setFullscreen:YES animated:YES];
            self.player.scalingMode = MPMovieScalingModeAspectFit;
            [_scrollview addSubview: self.player.view];
            [self.player.view mas_makeConstraints:^(MASConstraintMaker *make) {
                make.left.right.equalTo(self);
                make.height.offset(self.height-navH-80);
                make.top.equalTo(self).offset(navH);
            }];
            
            UIImage *firstImage = [Utils thumbnailImageForVideo:videoUrl atTime:1];
            self.video1STImage = [UIImageView new];
            self.video1STImage.contentMode = UIViewContentModeScaleAspectFit;
            self.video1STImage.image = firstImage;
            [self.player.view addSubview:self.video1STImage];
            [self.video1STImage mas_makeConstraints:^(MASConstraintMaker *make) {
                make.left.right.equalTo(self.player.view);
                make.centerY.equalTo(self.player.view);
            }];
            
            NSBundle *bundlePath = [NSBundle bundleWithPath:[[NSBundle bundleForClass:[self class]] pathForResource:@"PooTools" ofType:@"bundle"]];

            UIImage *playImageFile = [[UIImage imageWithContentsOfFile:[bundlePath pathForResource:@"p_play" ofType:@"png"]] imageWithRenderingMode:UIImageRenderingModeAutomatic];
            self.playBtn = [UIButton buttonWithType:UIButtonTypeCustom];
            [self.playBtn setImage:playImageFile forState:UIControlStateNormal];
            [self.playBtn addTarget:self action:@selector(playVideoAction:) forControlEvents:UIControlEventTouchUpInside];
            [self.player.view addSubview:self.playBtn];
            [self.playBtn mas_makeConstraints:^(MASConstraintMaker *make) {
                make.width.height.offset(44);
                make.centerX.centerY.equalTo(self.player.view);
            }];
            
            UIImage *pauseImageFile = [[UIImage imageWithContentsOfFile:[bundlePath pathForResource:@"p_pause" ofType:@"png"]] imageWithRenderingMode:UIImageRenderingModeAutomatic];
            self.stopBtn = [UIButton buttonWithType:UIButtonTypeCustom];
            [self.stopBtn setImage:pauseImageFile forState:UIControlStateNormal];
            [self.stopBtn addTarget:self action:@selector(stopVideoAction:) forControlEvents:UIControlEventTouchUpInside];
            [self.player.view addSubview:self.stopBtn];
            [self.stopBtn mas_makeConstraints:^(MASConstraintMaker *make) {
                make.width.height.offset(44);
                make.left.equalTo(self.player.view).offset(10);
                make.bottom.equalTo(self.player.view).offset(-10);
            }];
            self.stopBtn.hidden = YES;
            
            self.videoSlider = [UISlider new];
            [self.videoSlider addTarget:self action:@selector(playVideoSomeTime:) forControlEvents:UIControlEventTouchDragInside];
            [self.player.view addSubview:self.videoSlider];
            [self.videoSlider mas_makeConstraints:^(MASConstraintMaker *make) {
                make.left.equalTo(self.stopBtn.mas_right).offset(10);
                make.right.equalTo(self.player.view).offset(-10);
                make.height.offset(20);
                make.centerY.equalTo(self.stopBtn.mas_centerY);
            }];
            self.videoSlider.hidden = YES;
            self.hasLoadedImage = YES;
            
            [self setNeedsLayout];
        }
        else
        {
            self.imageview = [UIImageView new];
            NSString *imageURLString = model.imageUrl;
            self.imageview.contentMode = UIViewContentModeScaleAspectFit;
            
            id urlObject;
            if (imageURLString)
            {
                if ([imageURLString isKindOfClass:[NSString class]])
                {
                    urlObject = imageURLString;
                }
                else if([imageURLString isKindOfClass:[NSURL class]])
                {
                    urlObject = imageURLString;
                }
                else if([imageURLString isKindOfClass:[UIImage class]])
                {
                    
                }
            }
            
            [_scrollview addSubview:self.imageview];
            
            [self addSubview:waitingView];

            __weak __typeof(self)weakself = self;
            [[SDWebImageManager sharedManager] loadImageWithURL:urlObject options:SDWebImageRetryFailed progress:^(NSInteger receivedSize, NSInteger expectedSize, NSURL * _Nullable targetURL) {
                __strong __typeof(weakself)strongself = weakself;
                dispatch_async(dispatch_get_main_queue(), ^{
                    waitingView.progress = (CGFloat)receivedSize / expectedSize;
                    strongself.imageview.image = nil;
                });
                
            } completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, SDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL) {
                __strong __typeof(weakself)strongself = weakself;

//                dispatch_async(dispatch_get_main_queue(), ^{
                    [waitingView removeFromSuperview];
//                });
                
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
                    [button addTarget:self action:@selector(reloadImage) forControlEvents:UIControlEventTouchUpInside];
                    [self addSubview:button];
                    return;
                }

                switch ([Utils contentTypeForImageData:data]) {
                    case ToolsAboutImageTypeGIF:
                    {
                        strongself.showMode = PShowModeGif;
                        
                        CGImageSourceRef source = CGImageSourceCreateWithData((CFDataRef)data, NULL);
                        size_t frameCout = CGImageSourceGetCount(source);
                        NSMutableArray* frames = [[NSMutableArray alloc] init];
                        for (size_t i=0; i<frameCout; i++)
                        {
                            CGImageRef imageRef = CGImageSourceCreateImageAtIndex(source, i, NULL);
                            UIImage* imageName = [UIImage imageWithCGImage:imageRef];
                            [frames addObject:imageName];
                            CGImageRelease(imageRef);
                        }
                        strongself.imageview.animationImages = frames;
                        strongself.imageview.animationDuration = 2;
                        [strongself.imageview startAnimating];
                        strongself.imageview.image = image;
                        //FIX:内存释放
                        CFRelease(source);
                    }
                        break;
                    default:
                    {
                        strongself.showMode = PShowModeNormal;
                        strongself.imageview.image = image;
                    }
                        break;
                }
                [self setNeedsLayout];
                strongself.hasLoadedImage = YES;//图片加载成功
            }];
        }
    }
}

-(void)playVideoAction:(UIButton *)sender
{
    self.video1STImage.hidden = YES;
    self.stopBtn.hidden = NO;
    self.videoSlider.hidden = NO;
    sender.hidden = YES;
    [self.player play];
    
    NSDictionary *opts = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO]
                                                     forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
    AVURLAsset *urlAsset = [AVURLAsset URLAssetWithURL:[NSURL URLWithString:self.imageModels.imageUrl] options:opts];  // 初始化视频媒体文件
    videoTime = urlAsset.duration.value / urlAsset.duration.timescale;
    self.videoSlider.maximumValue = videoTime;
    self.videoSlider.minimumValue = 0.0;
    [self addTime];
}

-(void)addTime
{
    timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(nextpage) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
}

-(void)nextpage
{
    if (self.videoSlider.value >= videoTime) {
        [timer invalidate];
    }
    self.videoSlider.value = self.player.currentPlaybackTime;
}

-(void)stopVideoAction:(UIButton *)sender
{
    sender.hidden = YES;
    self.playBtn.hidden = NO;
    [self.player pause];
    [timer invalidate];
}

-(void)playVideoSomeTime:(UISlider *)sender
{
    [self.player pause];
    [timer invalidate];
    [self.player setCurrentPlaybackTime:sender.value];
    [self.player play];
    [self addTime];
}

#pragma mark private methods
- (void)reloadImage
{
    [self setImageWithModel:_imageModels];
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
    if (self.imageview.image)
    {
        CGSize imageSize = self.imageview.image.size;//获得图片的size
        CGRect imageFrame = CGRectMake(0, 0, imageSize.width, imageSize.height);
        if (_isFullWidthForLandScape)
        {//图片宽度始终==屏幕宽度(新浪微博就是这种效果)
            CGFloat ratio = frame.size.width/imageFrame.size.width;
            imageFrame.size.height = imageFrame.size.height*ratio;
            imageFrame.size.width = frame.size.width;
        }
        else
        {
            if (frame.size.width<=frame.size.height)
            {
                //竖屏时候
                CGFloat ratio = frame.size.width/imageFrame.size.width;
                imageFrame.size.height = imageFrame.size.height*ratio;
                imageFrame.size.width = frame.size.width;
            }
            else
            { //横屏的时候
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
    [self.player.view mas_updateConstraints:^(MASConstraintMaker *make) {
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

#define HZWaitingViewBackgroundColor [UIColor colorWithRed:0 green:0 blue:0 alpha:0.7]
#define HZWaitingViewItemMargin 10

@implementation HZWaitingView


- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = HZWaitingViewBackgroundColor;
        self.clipsToBounds = YES;
        self.mode = HZWaitingViewModeLoopDiagram;
    }
    return self;
}

- (void)setProgress:(CGFloat)progress
{
    _progress = progress;
    [self setNeedsDisplay];
    if (progress >= 1) {
        [self removeFromSuperview];
    }
}

- (void)setFrame:(CGRect)frame
{
    //设置背景图为圆
    frame.size.width = 50;
    frame.size.height = 50;
    self.layer.cornerRadius = 25;
    [super setFrame:frame];
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
    CGFloat xCenter = rect.size.width * 0.5;
    CGFloat yCenter = rect.size.height * 0.5;
    [[UIColor whiteColor] set];
    
    switch (self.mode) {
        case HZWaitingViewModePieDiagram:
        {
            CGFloat radius = MIN(rect.size.width * 0.5, rect.size.height * 0.5) - HZWaitingViewItemMargin;
            
            CGFloat w = radius * 2 + HZWaitingViewItemMargin;
            CGFloat h = w;
            CGFloat x = (rect.size.width - w) * 0.5;
            CGFloat y = (rect.size.height - h) * 0.5;
            CGContextAddEllipseInRect(ctx, CGRectMake(x, y, w, h));
            CGContextFillPath(ctx);
            
            [HZWaitingViewBackgroundColor set];
            CGContextMoveToPoint(ctx, xCenter, yCenter);
            CGContextAddLineToPoint(ctx, xCenter, 0);
            CGFloat to = - M_PI * 0.5 + self.progress * M_PI * 2 + 0.001; // 初始值
            CGContextAddArc(ctx, xCenter, yCenter, radius, - M_PI * 0.5, to, 1);
            CGContextClosePath(ctx);
            
            CGContextFillPath(ctx);
        }
            break;
            
        default:
        {
            CGContextSetLineWidth(ctx, 4);
            CGContextSetLineCap(ctx, kCGLineCapRound);
            CGFloat to = - M_PI * 0.5 + self.progress * M_PI * 2 + 0.05; // 初始值0.05
            CGFloat radius = MIN(rect.size.width, rect.size.height) * 0.5 - HZWaitingViewItemMargin;
            CGContextAddArc(ctx, xCenter, yCenter, radius, - M_PI * 0.5, to, 0);
            CGContextStrokePath(ctx);
        }
            break;
    }
}

@end

