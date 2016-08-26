//
//  MJCircleLayer.m
//  MJCircleView
//
//  Created by tenric on 13-6-29.
//  Copyright (c) 2013年 tenric. All rights reserved.
//

#import "MJCircleLayer.h"
#import "MJPasswordView.h"

@implementation MJCircleLayer

- (void)drawInContext:(CGContextRef)ctx
{
    NSBundle *bundle = [[self class] resourceBundle:@"LikeAlipayLock"];

    UIImage *img = [UIImage imageNamed:[bundle pathForResource:[NSString stringWithFormat:@"image_CodeUnSet@2x"] ofType:@"png"]];
    CGImageRef image  = CGImageRetain(img.CGImage);
    CGContextDrawImage(ctx, self.bounds, image);
    CGImageRelease(image);

    if (self.highlighted)
    {
        UIImage *img = [UIImage imageNamed:[bundle pathForResource:[NSString stringWithFormat:@"image_CodeSet@2x"] ofType:@"png"]];
        CGImageRef image  = CGImageRetain(img.CGImage);
        CGContextDrawImage(ctx, self.bounds, image);
        CGImageRelease(image);
    }
}

+ (NSBundle *)resourceBundle:(NSString *)bundleName
{
    NSString *bundlePath = [[NSBundle mainBundle] pathForResource:bundleName ofType:@"bundle"]; //显然这里你也可以通过其他的方式取得，总之找到bundle的完整路径即可。
    NSBundle *bundle = [NSBundle bundleWithPath:bundlePath];
    
    return bundle;
}
@end
