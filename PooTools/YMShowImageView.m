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

@interface YMShowImageView ()<NSURLConnectionDataDelegate, NSURLConnectionDelegate>
{
    UIPageControl *pageControl;
}
@property (nonatomic, strong) UIImageView *nilViews;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) NSMutableArray *imageScrollViews;
@property (nonatomic, assign) NSInteger page;
@end

@implementation YMShowImageView
{
    CGRect self_Frame;
    BOOL doubleClick;
    UIButton *deleteButton;
}

-(id)initWithFrame:(CGRect)frame byClick:(NSInteger)clickTag appendArray:(NSArray <PooShowImageModel*>*)appendArray titleColor:(UIColor *)tC fontName:(NSString *)fName currentPageIndicatorTintColor:(UIColor *)cpic pageIndicatorTintColor:(UIColor *)pic deleteImageName:(NSString *)di showImageBackgroundColor:(UIColor *)sibc showWindow:(UIWindow *)w deleteAble:(BOOL)canDelete
{
    self = [super initWithFrame:frame];
    if (self) {
        
        self_Frame = frame;
        titleColor = tC;
        fontName = fName;
        currentPageIndicatorTintColor = cpic;
        pageIndicatorTintColor = pic;
        deleteImageName = di;
        showImageBackgroundColor = sibc;
        window = w;
        
        self.alpha = 0.0f;
        self.page = 0;
        doubleClick = YES;
        
        [self configScrollViewWith:clickTag andAppendArray:appendArray canDelete:canDelete];
        
        UITapGestureRecognizer *tapGser = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(disappear)];
        tapGser.numberOfTouchesRequired = 1;
        tapGser.numberOfTapsRequired = 1;
        [self addGestureRecognizer:tapGser];
        
        UITapGestureRecognizer *doubleTapGser = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(changeBig:)];
        doubleTapGser.numberOfTapsRequired = 2;
        [self addGestureRecognizer:doubleTapGser];
        [tapGser requireGestureRecognizerToFail:doubleTapGser];
        
    }
    return self;

}

- (void)configScrollViewWith:(NSInteger)clickTag andAppendArray:(NSArray<PooShowImageModel *> *)appendArray canDelete:(BOOL)cd
{
    if (cd) {
        deleteButton                           = [UIButton buttonWithType:UIButtonTypeCustom];
        deleteButton.frame                     = CGRectMake(self.width - 50.0f, self.height-50, 45.0f, 45.0f);
        deleteButton.imageEdgeInsets           = UIEdgeInsetsMake(5.0f, 5.0f, 5.0f, 5.0f);
        deleteButton.showsTouchWhenHighlighted = YES;
        [deleteButton setImage:kImageNamed(deleteImageName) forState:UIControlStateNormal];
        [deleteButton addTarget:self action:@selector(removeCurrImage) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:deleteButton];
    }
    
    self.scrollView = [[UIScrollView alloc] initWithFrame:self_Frame];
    self.scrollView.backgroundColor = [UIColor blackColor];
    self.scrollView.pagingEnabled = true;
    self.scrollView.delegate = self;
    self.scrollView.contentSize = CGSizeMake(self.width * appendArray.count, 0);
    [self addSubview:self.scrollView];
    
    pageControl = [[UIPageControl alloc]initWithFrame:CGRectMake(0,24, kSCREEN_WIDTH, 20)];
    pageControl.numberOfPages = appendArray.count;
    pageControl.backgroundColor = [UIColor clearColor];
    pageControl.pageIndicatorTintColor = pageIndicatorTintColor;
    pageControl.currentPageIndicatorTintColor = currentPageIndicatorTintColor;
    [pageControl sizeForNumberOfPages:2];
    [self addSubview:pageControl];
    
    self.imageScrollViews = [[NSMutableArray alloc] init];
    
    float W = self.frame.size.width;
    
    
    for (int i = 0; i < appendArray.count; i ++) {
        PooShowImageModel *model = appendArray[i];
        
        UIScrollView *imageScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(self.width * i, 0, self.width, self.height)];
        imageScrollView.backgroundColor = showImageBackgroundColor;
        imageScrollView.contentSize = CGSizeMake(self.width, self.height);
        imageScrollView.delegate = self;
        imageScrollView.maximumZoomScale = 4;
        imageScrollView.minimumZoomScale = 1;
        
        if ([model.imageFullView isEqualToString:@"1"]) {
            
            UILabel *fullViewLabel = [[UILabel alloc] initWithFrame:CGRectMake(kSCREEN_WIDTH-60 , 24, 50, 20)];
            kViewBorderRadius(fullViewLabel, 5, 1, titleColor);
            fullViewLabel.textAlignment = NSTextAlignmentCenter;
            fullViewLabel.font = kDEFAULT_FONT(fontName, 18);
            fullViewLabel.textColor = titleColor;
            fullViewLabel.text = @"全景";
            [imageScrollView addSubview:fullViewLabel];
            
            SCNView *sceneView = [[SCNView alloc] initWithFrame:CGRectMake(0, HEIGHT_NAVBAR, self.width, self.height-HEIGHT_NAVBAR-80)];
            [imageScrollView addSubview:sceneView];
            
            sceneView.scene = [[SCNScene alloc] init];
            sceneView.showsStatistics = NO;
            sceneView.allowsCameraControl = YES;
            
            SCNSphere *sphere =   [SCNSphere sphereWithRadius:20.0];
            sphere.firstMaterial.doubleSided = YES;
            [[SDWebImageManager sharedManager] loadImageWithURL:[NSURL URLWithString:model.imageUrl] options:0 progress:^(NSInteger receivedSize, NSInteger expectedSize, NSURL * _Nullable targetURL) {
                sphere.firstMaterial.diffuse.contents = kImageNamed(@"DemoImage");
            } completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, SDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL) {
                
                //Create node, containing a sphere, using the panoramic image as a texture
                
                sphere.firstMaterial.diffuse.contents = image;
            }];
            SCNNode *sphereNode = [SCNNode nodeWithGeometry:sphere];
            sphereNode.position = SCNVector3Make(0,0,0);
            [sceneView.scene.rootNode addChildNode:sphereNode];
        }
        else
        {
            self.nilViews = [[UIImageView alloc] initWithFrame:self.bounds];
            NSString *imageURLString = model.imageUrl;
            if (imageURLString) {
                if ([imageURLString isKindOfClass:[NSString class]]) {
                    [self.nilViews sd_setImageWithURL:[NSURL URLWithString:imageURLString] placeholderImage:kImageNamed(@"DemoImage")];
                }else if([imageURLString isKindOfClass:[NSURL class]]){
                    [self.nilViews sd_setImageWithURL:(NSURL*)imageURLString
                                     placeholderImage:kImageNamed(@"DemoImage")];
                    
                }else if([imageURLString isKindOfClass:[UIImage class]]){
                    self.nilViews.image = (UIImage*)imageURLString;
                }
            }
            self.nilViews.contentMode = UIViewContentModeScaleAspectFit;
            [imageScrollView addSubview:self.nilViews];
        }
        
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, imageScrollView.height-80, kSCREEN_WIDTH-20, 40)];
        titleLabel.textAlignment = NSTextAlignmentLeft;
        titleLabel.textColor     = titleColor;
        titleLabel.numberOfLines = 0;
        titleLabel.lineBreakMode = NSLineBreakByCharWrapping;
        titleLabel.font = kDEFAULT_FONT(fontName, 16);
        titleLabel.text          = model.imageTitle;
        titleLabel.hidden        = titleLabel.text.length == 0;
        [imageScrollView addSubview:titleLabel];
        
        UILabel *infoLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, imageScrollView.height-40, kSCREEN_WIDTH-20, 40)];
        infoLabel.textAlignment = NSTextAlignmentLeft;
        infoLabel.textColor     = titleColor;
        infoLabel.numberOfLines = 0;
        infoLabel.lineBreakMode = NSLineBreakByCharWrapping;
        infoLabel.font = kDEFAULT_FONT(fontName, 16);
        infoLabel.text          = model.imageInfo;
        infoLabel.hidden        = infoLabel.text.length == 0;
        [imageScrollView addSubview:infoLabel];
        
        [self.scrollView addSubview:imageScrollView];
        [self.imageScrollViews addObject:imageScrollView];
        
        imageScrollView.tag = 100 + i ;
        self.nilViews.tag = 1000 + i;
        
        
    }
    [self.scrollView setContentOffset:CGPointMake(W * (clickTag - YMShowImageViewClickTagAppend), 0) animated:YES];
    self.page = clickTag - YMShowImageViewClickTagAppend;
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
    
    UIImageView *imageView = (UIImageView *)[self viewWithTag:scrollView.tag + 900];
    return imageView;

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
    UIView *maskview = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kSCREEN_WIDTH, kSCREEN_HEIGHT)];
    maskview.backgroundColor = [UIColor blackColor];
    [window addSubview:maskview];
    
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

- (void)show:(UIView *)bgView didFinish:(didRemoveImage)tempBlock{
    
     [bgView addSubview:self];
    
     _removeImg = tempBlock;
    
     [UIView animateWithDuration:.4f animations:^(){
         
         self.alpha = 1.0f;
    
      } completion:^(BOOL finished) {
        
     }];
}

#pragma mark - ScorllViewDelegate
-(void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    int page = (scrollView.contentOffset.x)/scrollView.width;
    pageControl.currentPage = page;
}


- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
  
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

- (void)scrollViewDidZoom:(UIScrollView *)scrollView{
  

}

#pragma mark - ----> 删除图片
- (void)removeCurrImage{

    ALActionSheetView *actionSheetView = [ALActionSheetView showActionSheetWithTitle:nil
                                                                   cancelButtonTitle:@"取消"
                                                              destructiveButtonTitle:nil
                                                                   otherButtonTitles:@[@"删除照片"]
                                                                      buttonFontName:fontName
                                                                             handler:^(ALActionSheetView *actionSheetView, NSInteger buttonIndex)
                                          {
                                              if (buttonIndex == 0)
                                              {
                                                  NSInteger index = self.page;

                                                  if (self.didDeleted)
                                                  {
                                                      self.didDeleted(self,index);
                                                  }

                                                  UIView *currView = self.imageScrollViews[index];
                                                  if (currView) {
                                                      if (self.imageScrollViews.count == 1)
                                                      {
                                                          [self disappear];
                                                      }
                                                      else
                                                      {
                                                          __block float lastWidth = currView.width;
                                                          [UIView animateWithDuration:0.2 animations:^{
                                                              currView.alpha = 0;
                                                              currView.frame = CGRectMake(currView.x*0.5, currView.y, 0, 0);

                                                              self.scrollView.contentSize = CGSizeMake(self.scrollView.contentSize.width - lastWidth, self.scrollView.contentSize.height);
                                                              [self.imageScrollViews removeObjectAtIndex:index];

                                                              if (index >= self.imageScrollViews.count)
                                                              {
                                                                  self.page = self.page - 1;
                                                              }
                                                              else
                                                              {
                                                                  for (int i = (int)index ; i < self.imageScrollViews.count ;  i++)
                                                                  {
                                                                      UIView *nextView = self.imageScrollViews[i];
                                                                      nextView.tag = i+100;
                                                                      nextView.x -= lastWidth;
                                                                      lastWidth = nextView.width;
                                                                  }
                                                              }
                                                          } completion:^(BOOL finished) {
                                                              [currView removeFromSuperview];
                                                          }];
                                                      }
                                                  }
                                              }
                                          }];
    [actionSheetView show];
}




@end
