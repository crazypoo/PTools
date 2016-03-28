//
//  SecurityStrategy.m
//  VoteWhere
//
//  Created by WJ02047 mini on 14-12-9.
//  Copyright (c) 2014年 Touna Wang. All rights reserved.
//

#import "SecurityStrategy.h"
#import "UIImage+BlurGlass.h"

#define screenWidth ([UIScreen mainScreen].bounds.size.width)
#define screenHeight ([UIScreen mainScreen].bounds.size.height)
#define screenScale ([UIScreen mainScreen].scale)

#define effectTag 19999

@implementation SecurityStrategy

+(void)addBlurEffect
{
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    imageView.tag = effectTag;
    imageView.image = [self blurImage];
    [[[UIApplication sharedApplication] keyWindow] addSubview:imageView];
}
+(void)removeBlurEffect
{
    NSArray *subViews = [[UIApplication sharedApplication] keyWindow].subviews;
    for (id object in subViews) {
        if ([[object class] isSubclassOfClass:[UIImageView class]]) {
            UIImageView *imageView = (UIImageView *)object;
            if(imageView.tag == effectTag)
            {
                [UIView animateWithDuration:0.2 animations:^{
                    imageView.alpha = 0;
                    [imageView removeFromSuperview];
                }];
               
            }
        }
    }
}


//毛玻璃效果
+(UIImage *)blurImage
{
    UIImage *image = [[self screenShot] imgWithBlur];
    //保存图片到照片库(test)
//    UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
    
    return image;
}
//屏幕截屏
+(UIImage *)screenShot
{
    
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(screenWidth*screenScale, screenHeight*screenScale), YES, 0);
    //设置截屏大小
    [[[[UIApplication sharedApplication] keyWindow] layer] renderInContext:UIGraphicsGetCurrentContext()];
    
    UIImage *viewImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    CGImageRef imageRef = viewImage.CGImage;
    CGRect rect = CGRectMake(0, 0, screenWidth*screenScale,screenHeight*screenScale);
   
    CGImageRef imageRefRect =CGImageCreateWithImageInRect(imageRef, rect);
    UIImage *sendImage = [[UIImage alloc] initWithCGImage:imageRefRect];
    return sendImage;
}


@end

// 版权属于原作者
// http://code4app.com (cn) http://code4app.net (en)
// 发布代码于最专业的源码分享网站: Code4App.com 
