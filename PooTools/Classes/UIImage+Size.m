//
//  UIImage+Size.m
//  OMCN
//
//  Created by 邓杰豪 on 15/8/17.
//  Copyright (c) 2015年 doudou. All rights reserved.
//

#import "UIImage+Size.h"

@implementation UIImage (size)
- (UIImage*)transformWidth:(CGFloat)width height:(CGFloat)height
{
    
    CGFloat destW = width;
    CGFloat destH = height;
    CGFloat sourceW = width;
    CGFloat sourceH = height;
    
    CGImageRef imageRef = self.CGImage;
    CGContextRef bitmap = CGBitmapContextCreate(NULL, destW, destH, CGImageGetBitsPerComponent(imageRef), 4*destW, CGImageGetColorSpace(imageRef), (kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst));
    
    CGContextDrawImage(bitmap, CGRectMake(0, 0, sourceW, sourceH), imageRef);
    
    CGImageRef ref = CGBitmapContextCreateImage(bitmap);
    UIImage *resultImage = [UIImage imageWithCGImage:ref];
    CGContextRelease(bitmap);
    CGImageRelease(ref);
    
    return resultImage;
}
@end
