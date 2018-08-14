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
#import <SceneKit/SceneKit.h>
#import "PMacros.h"
#import "PooLoadingView.h"
#import <Masonry/Masonry.h>
#import "WMHub.h"

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
@property (nonatomic, strong) NSMutableArray *imageModelArr;
@property (nonatomic, assign) NSInteger viewClickTag;
@property (nonatomic, strong) UIButton *deleteButton;
@property (nonatomic, strong) UIButton *saveImageButton;
@property (nonatomic, strong) UIColor *showImageBackgroundColor;
@property (nonatomic, strong) UIColor *titleColor;
@property (nonatomic, strong) NSString *fontName;
@property (nonatomic, strong) UIPageControl *pageControl;
@property (nonatomic, assign) MoreActionType moreType;
@property (nonatomic, strong) NSArray *actionSheetOtherBtnArr;
@property (nonatomic, strong) NSString *moreActionImageNames;

@end

@implementation YMShowImageView
{
    BOOL doubleClick;    
}

-(id)initWithByClick:(NSInteger)clickTag appendArray:(NSArray <PooShowImageModel*>*)appendArray titleColor:(UIColor *)tC fontName:(NSString *)fName currentPageIndicatorTintColor:(UIColor *)cpic pageIndicatorTintColor:(UIColor *)pic showImageBackgroundColor:(UIColor *)sibc showWindow:(UIWindow *)w loadingImageName:(NSString *)li deleteAble:(BOOL)canDelete saveAble:(BOOL)canSave moreActionImageName:(NSString *)main
{
    self = [super init];
    if (self) {
        
        if (canDelete == YES && canSave == YES) {
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
        
        UIDevice *device = [UIDevice currentDevice]; //Get the device object
        [device beginGeneratingDeviceOrientationNotifications]; //Tell it to start monitoring the accelerometer for orientation
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter]; //Get the notification centre for the app
        [nc addObserver:self selector:@selector(orientationChanged:) name:UIDeviceOrientationDidChangeNotification  object:device];
        
        self.titleColor = tC;
        self.fontName = fName;
        currentPageIndicatorTintColor = cpic;
        pageIndicatorTintColor = pic;
        self.showImageBackgroundColor = sibc;
        self.window = w;
        self.loadingImageName = li;
        self.moreActionImageNames = main;
        self.imageModelArr = [NSMutableArray array];
        [self.imageModelArr addObjectsFromArray:appendArray];
        
        self.alpha = 0.0f;
        self.page = 0;
        doubleClick = YES;
        
        [self configScrollViewWith:clickTag andAppendArray:appendArray];
        
        self.modelArr = [[NSMutableArray alloc] init];
        [self.modelArr addObjectsFromArray:appendArray];
        
        UITapGestureRecognizer *tapGser = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(disappear)];
        tapGser.numberOfTouchesRequired = 1;
        tapGser.numberOfTapsRequired = 1;
        [self addGestureRecognizer:tapGser];
        
//        UITapGestureRecognizer *doubleTapGser = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(changeBig:)];
//        doubleTapGser.numberOfTapsRequired = 2;
//        [self addGestureRecognizer:doubleTapGser];
//        [tapGser requireGestureRecognizerToFail:doubleTapGser];
        
    }
    return self;

}

- (void)configScrollViewWith:(NSInteger)clickTag andAppendArray:(NSArray<PooShowImageModel *> *)appendArray
{
    self.viewClickTag = clickTag;
    
    self.scrollView = [UIScrollView new];
    self.scrollView.backgroundColor = kClearColor;
    self.scrollView.pagingEnabled = true;
    self.scrollView.delegate = self;
    [self addSubview:self.scrollView];
    
    self.pageControl = [UIPageControl new];
    self.pageControl.numberOfPages = appendArray.count;
    self.pageControl.backgroundColor = [UIColor clearColor];
    self.pageControl.pageIndicatorTintColor = pageIndicatorTintColor;
    self.pageControl.currentPageIndicatorTintColor = currentPageIndicatorTintColor;
    [self.pageControl sizeForNumberOfPages:2];
    [self addSubview:self.pageControl];
    
    self.imageScrollViews = [[NSMutableArray alloc] init];
}

-(void)removeFromSuperview
{
    [super removeFromSuperview];
    self.nilViews = nil;
}

- (void)disappear{
    if (_removeImg) {
        _removeImg();
    }
}

- (void)changeBig:(UITapGestureRecognizer *)tapGes{

    CGFloat newscale = 1.9;
    UIScrollView *currentScrollView = (UIScrollView *)[self viewWithTag:self.page + 100];
    CGRect zoomRect = [self zoomRectForScale:newscale withCenter:[tapGes locationInView:tapGes.view] andScrollView:currentScrollView];
    
    if (doubleClick == YES)  {
        
        [currentScrollView zoomToRect:zoomRect animated:YES];
        
    }else {
      
        [currentScrollView zoomToRect:currentScrollView.frame animated:YES];
    }
    doubleClick = !doubleClick;
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView{
    
    UIScrollView *aaaaa = (UIScrollView *)[self.scrollView viewWithTag:100+self.page];
    
    if (scrollView == aaaaa) {
        UIImageView *imageView = (UIImageView *)[scrollView viewWithTag:self.page + 1000];
        return imageView;
    }
    return nil;
//    UIImageView *imageView = (UIImageView *)[self viewWithTag:scrollView.tag + 900];
//    return imageView;

}

- (CGRect)zoomRectForScale:(CGFloat)newscale withCenter:(CGPoint)center andScrollView:(UIScrollView *)scrollV{
   
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
            if (tempBlock) {
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
    [self.pageControl mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(bgView);
        make.top.offset(kScreenStatusBottom+5);
        make.height.offset(20);
        make.centerX.equalTo(bgView);
    }];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSLog(@"0秒后获取frame：%@", self);
        self.scrollView.contentSize = CGSizeMake(self.width * self.imageModelArr.count, 0);
        
        float W = self.width;
        
        for (int i = 0; i < self.imageModelArr.count; i ++) {
            PooShowImageModel *model = self.imageModelArr[i];
            
            UIScrollView *imageScrollView = [UIScrollView new];
            imageScrollView.backgroundColor = self.showImageBackgroundColor;
            imageScrollView.delegate = self;
            imageScrollView.maximumZoomScale = 2;
            imageScrollView.minimumZoomScale = 1;
            imageScrollView.showsVerticalScrollIndicator = NO;
            imageScrollView.showsHorizontalScrollIndicator = NO;
            [self.scrollView addSubview:imageScrollView];
            [imageScrollView mas_makeConstraints:^(MASConstraintMaker *make) {
                make.left.offset(self.width*i);
                make.top.offset(0);
                make.width.offset(self.width);
                make.height.offset(self.height);
            }];
            
            imageScrollView.tag = 100 + i ;
            
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
                
                UILabel *fullViewLabel = [UILabel new];
                kViewBorderRadius(fullViewLabel, 5, 1, self.titleColor);
                fullViewLabel.textAlignment = NSTextAlignmentCenter;
                fullViewLabel.font = kDEFAULT_FONT(self.fontName, 18);
                fullViewLabel.textColor = self.titleColor;
                fullViewLabel.text = @"全景";
                [imageScrollView addSubview:fullViewLabel];
                [fullViewLabel mas_makeConstraints:^(MASConstraintMaker *make) {
                    make.width.offset(50);
                    make.height.offset(20);
                    make.right.equalTo(self).offset(-10);
                    make.top.equalTo(imageScrollView).offset(kScreenStatusBottom+5);
                }];
                
                SCNView *sceneView = [SCNView new];
                [imageScrollView addSubview:sceneView];
                [sceneView mas_makeConstraints:^(MASConstraintMaker *make) {
                    make.left.right.equalTo(self);
                    make.height.offset(self.height-navH-80);
                    make.top.equalTo(self).offset(navH);
                }];
                sceneView.tag = 2000 + i;

                
                sceneView.scene = [[SCNScene alloc] init];
                sceneView.showsStatistics = NO;
                sceneView.allowsCameraControl = YES;
                
                SCNSphere *sphere =   [SCNSphere sphereWithRadius:20.0];
                sphere.firstMaterial.doubleSided = YES;
                
                [[SDWebImageManager sharedManager] loadImageWithURL:[NSURL URLWithString:model.imageUrl] options:0 progress:^(NSInteger receivedSize, NSInteger expectedSize, NSURL * _Nullable targetURL) {

                } completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, SDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL) {
                    GCDWithMain(^{
                        [self.saveImageArr addObject:image];
                        sphere.firstMaterial.diffuse.contents = image;
                    });
                }];
                SCNNode *sphereNode = [SCNNode nodeWithGeometry:sphere];
                sphereNode.position = SCNVector3Make(0,0,0);
                [sceneView.scene.rootNode addChildNode:sphereNode];
                imageScrollView.contentSize = CGSizeMake(self.width, self.height);
            }
            else
            {
                self.nilViews = [UIImageView new];
                NSString *imageURLString = model.imageUrl;
                self.nilViews.contentMode = UIViewContentModeScaleAspectFill;
                __block UIImage *subImage;
                
                id urlObject;
                if (imageURLString) {
                    if ([imageURLString isKindOfClass:[NSString class]]) {
//                        [self.nilViews sd_setImageWithURL:[NSURL URLWithString:imageURLString] placeholderImage:kImageNamed(self.loadingImageName) options:SDWebImageRetryFailed];
//                        [self.saveImageArr addObject:self.nilViews.image];
                        urlObject = imageURLString;
                    }else if([imageURLString isKindOfClass:[NSURL class]]){
//                        [self.nilViews sd_setImageWithURL:(NSURL*)imageURLString placeholderImage:kImageNamed(self.loadingImageName) options:SDWebImageRetryFailed];
//                        [self.saveImageArr addObject:self.nilViews.image];
                        urlObject = imageURLString;
                    }else if([imageURLString isKindOfClass:[UIImage class]]){
//                        self.nilViews.image = (UIImage*)imageURLString;
//                        [self.saveImageArr addObject:(UIImage*)imageURLString];
                    }
                }

                [self.nilViews sd_setImageWithURL:urlObject placeholderImage:kImageNamed(self.loadingImageName) options:SDWebImageRetryFailed completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
                    subImage = image;
                    CGFloat imageScale = kSCREEN_WIDTH/image.size.width;
                    CGFloat imageW = imageScale*image.size.width;
                    CGFloat imageH = imageScale*image.size.height;
                    imageScrollView.contentSize = CGSizeMake(imageW, imageH);
                    PNSLog(@">>>>>>>>>>>>>>>>>>>>>>%f>>>>>>>>>>>>>>>>.%f",imageW,imageH);
                    PNSLog(@">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>%f>>>>>>>>>>>>>>>>.%f",image.size.width,image.size.height);

                    [imageScrollView addSubview:self.nilViews];
                    [self.nilViews mas_makeConstraints:^(MASConstraintMaker *make) {
                        make.left.right.equalTo(self);
                        make.height.offset(image.size.height);
                        make.top.equalTo(self).offset(navH);
                    }];
                }];
                self.nilViews.image = subImage;

//                if (imageURLString) {
//                    if ([imageURLString isKindOfClass:[NSString class]]) {
//                        [self.nilViews sd_setImageWithURL:[NSURL URLWithString:imageURLString] placeholderImage:kImageNamed(self.loadingImageName) options:SDWebImageRetryFailed];
//                        [self.saveImageArr addObject:self.nilViews.image];
//                    }else if([imageURLString isKindOfClass:[NSURL class]]){
//                        [self.nilViews sd_setImageWithURL:(NSURL*)imageURLString placeholderImage:kImageNamed(self.loadingImageName) options:SDWebImageRetryFailed];
//                        [self.saveImageArr addObject:self.nilViews.image];
//                    }else if([imageURLString isKindOfClass:[UIImage class]]){
//                        self.nilViews.image = (UIImage*)imageURLString;
//                        [self.saveImageArr addObject:(UIImage*)imageURLString];
//                    }
//                }
                
                self.nilViews.tag = 1000 + i;
            }
            [self.imageScrollViews addObject:imageScrollView];
            
        }
        [self.scrollView setContentOffset:CGPointMake(W * (self.viewClickTag - YMShowImageViewClickTagAppend), 0) animated:YES];
        self.page = self.viewClickTag - YMShowImageViewClickTagAppend;
        
        PooShowImageModel *model = self.imageModelArr[0];
        
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
        
        switch (self.moreType) {
            case MoreActionTypeNoMore:
                break;
            default:
            {
                self.deleteButton                           = [UIButton buttonWithType:UIButtonTypeCustom];
                self.deleteButton.showsTouchWhenHighlighted = YES;
                [self.deleteButton setImage:kImageNamed(self.moreActionImageNames) forState:UIControlStateNormal];
                [self.deleteButton addTarget:self action:@selector(removeCurrImage) forControlEvents:UIControlEventTouchUpInside];
                [self addSubview:self.deleteButton];
                [self.deleteButton mas_makeConstraints:^(MASConstraintMaker *make) {
                    make.width.height.offset(30);
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

- (void)orientationChanged:(NSNotification *)note
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSLog(@"0.1秒后获取frame：%@", self);
        [self.scrollView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.left.right.top.bottom.equalTo(self);
        }];
        [self.pageControl mas_updateConstraints:^(MASConstraintMaker *make) {
            make.left.right.equalTo(self);
            make.top.offset(kScreenStatusBottom+5);
            make.height.offset(20);
            make.centerX.equalTo(self);
        }];
        self.scrollView.contentSize = CGSizeMake(self.width * self.imageModelArr.count, 0);
        for (int i = 0; i < self.imageModelArr.count; i ++)
        {
            PooShowImageModel *model = self.imageModelArr[i];
            UIScrollView *imageScrollView = (UIScrollView *)[self.scrollView viewWithTag:100+i];
            [imageScrollView mas_updateConstraints:^(MASConstraintMaker *make) {
                make.left.offset(self.width*i);
                make.top.offset(0);
                make.width.offset(self.width);
                make.height.offset(self.height);

            }];
            
            CGFloat navH = 0.0f;
            if (kDevice_Is_iPhoneX)
            {
                navH = HEIGHT_IPHONEXNAVBAR;
            }
            else
            {
                navH = HEIGHT_NAVBAR;
            }
            
            if ([model.imageFullView isEqualToString:@"1"])
            {
                SCNView *sceneView = (SCNView *)[imageScrollView viewWithTag:2000+i];
                [sceneView mas_updateConstraints:^(MASConstraintMaker *make) {
                    make.left.right.equalTo(self);
                    make.height.offset(self.height-navH-80);
                    make.top.equalTo(self).offset(navH);
                }];
                imageScrollView.contentSize = CGSizeMake(self.width, self.height);
            }
            else
            {
                self.nilViews = (UIImageView *)[imageScrollView viewWithTag:1000+i];
                [self.nilViews mas_updateConstraints:^(MASConstraintMaker *make) {
                    make.left.right.equalTo(self);
                    make.height.offset(self.height-navH-80);
                    make.top.equalTo(self).offset(navH);
                }];
                imageScrollView.contentSize = CGSizeMake(self.nilViews.image.size.width, self.nilViews.image.size.height);

            }
        }
        [self.scrollView setContentOffset:CGPointMake(self.width * (self.viewClickTag - YMShowImageViewClickTagAppend), 0) animated:YES];

    });
    
}

#pragma mark - ScorllViewDelegate
-(void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (scrollView == self.scrollView) {
        int page = (scrollView.contentOffset.x)/scrollView.width;
        self.pageControl.currentPage = page;
        
        if (scrollView == self.scrollView) {
            PooShowImageModel *model = self.modelArr[page];
            self.titleLabel.text = model.imageTitle;
            self.infoLabel.text = model.imageInfo;
        }
    }
    else
    {
        UIScrollView *currentScrollView = [self.scrollView viewWithTag:100+self.page];
        if (scrollView == currentScrollView) {
            PNSLog(@">>>>>>>>>>>>>.%f",scrollView.contentOffset.x);
        }
    }
}


- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
  
    if (scrollView == self.scrollView) {
        CGPoint offset = self.scrollView.contentOffset;
        self.page = offset.x / self.width ;
        
        
        UIScrollView *scrollV_next = (UIScrollView *)[self viewWithTag:self.page+100+1]; //前一页
        
        if (scrollV_next.zoomScale != 1.0){
            
            scrollV_next.zoomScale = 1.0;
        }
        
        UIScrollView *scollV_pre = (UIScrollView *)[self viewWithTag:self.page+100-1]; //后一页
        if (scollV_pre.zoomScale != 1.0){
            scollV_pre.zoomScale = 1.0;
        }
    }
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView
{
    UIScrollView *currentScrollView = [self.scrollView viewWithTag:100+self.page];
    if (scrollView == currentScrollView) {
        if (scrollView.contentOffset.x == 0 && scrollView.contentOffset.y == 0) {
            self.scrollView.scrollEnabled = YES;
            UIImageView *imageView = (UIImageView *)[scrollView viewWithTag:self.page + 1000];
            imageView.center = [self centerOfScrollViewContent:scrollView];

        }
        else
        {
            self.scrollView.scrollEnabled = NO;
        }
    }
}

-(void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(CGFloat)scale
{
    PNSLog(@"viewW:%f>>>>>>>>>>>viewH%f",view.width,view.height);
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
    [self saveImageToPhotos:self.saveImageArr[index]];
}

- (void)saveImageToPhotos:(UIImage*)savedImage
{
    UIImageWriteToSavedPhotosAlbum(savedImage, self, @selector(image:didFinishSavingWithError:contextInfo:), NULL);
    //因为需要知道该操作的完成情况，即保存成功与否，所以此处需要一个回调方法image:didFinishSavingWithError:contextInfo:
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
    BOOL saveimageAction;
    if(error != NULL){
        saveimageAction = NO;
    }else{
        saveimageAction = YES;
    }
    if (self.saveImageStatus) {
        self.saveImageStatus(saveimageAction);
    }
}

#pragma mark - ----> 删除图片
- (void)removeCurrImage{

    ALActionSheetView *actionSheetView = [ALActionSheetView showActionSheetWithTitle:@"图片操作"
                                                                   cancelButtonTitle:@"取消"
                                                              destructiveButtonTitle:nil
                                                                   otherButtonTitles:self.actionSheetOtherBtnArr
                                                                      buttonFontName:self.fontName
                                                                             handler:^(ALActionSheetView *actionSheetView, NSInteger buttonIndex)
                                          {
                                              switch (self.moreType) {
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
                                                      switch (buttonIndex) {
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
    
    UIScrollView *currView = (UIScrollView *)[self.scrollView viewWithTag:100+index];
    
    if (currView) {
        if (self.imageScrollViews.count == 1)
        {
            [self disappear];
        }
        else
        {
            __block float lastWidth = currView.width;
            [UIView animateWithDuration:0.2 animations:^{
                
                self.scrollView.contentSize = CGSizeMake(self.scrollView.contentSize.width - lastWidth, self.scrollView.contentSize.height);
                [self.imageScrollViews removeObjectAtIndex:index];
                [self.modelArr removeObjectAtIndex:index];
                [self.saveImageArr removeObjectAtIndex:index];
                
                self.pageControl.numberOfPages = self.imageScrollViews.count;
                
                [self.imageModelArr removeObjectAtIndex:index];
                
                if (index >= self.imageScrollViews.count)
                {
                    self.page = self.page - 1;
                }
                else
                {
                    for (int i = (int)index ; i < self.imageScrollViews.count ;  i++)
                    {
                        UIScrollView *nextView = (UIScrollView *)self.imageScrollViews[i];
                        nextView.tag = i+100;
                        [nextView mas_updateConstraints:^(MASConstraintMaker *make) {
                            make.left.offset(self.width*i);
                            make.top.offset(0);
                            make.width.offset(self.width);
                            make.height.offset(self.height);
                            
                        }];
                    }
                }
                GCDWithMain(^{
                    PooShowImageModel *model = self.modelArr[self.page];
                    self.titleLabel.text = model.imageTitle;
                    self.infoLabel.text = model.imageInfo;
                });
                
            } completion:^(BOOL finished) {
                GCDWithMain(^{
                    [currView removeFromSuperview];
                });
                
            }];
        }
    }
}


@end
