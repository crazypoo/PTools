//
//  EasySignatureView.m
//  EsayHandwritingSignature
//
//  Created by Liangk on 2017/11/9.
//  Copyright © 2017年 liang. All rights reserved.
//

#import "EasySignatureView.h"
#import <QuartzCore/QuartzCore.h>

#define StrWidth 350
#define StrHeight 25

static CGPoint midpoint(CGPoint p0,CGPoint p1) {
    return (CGPoint) {
        (p0.x + p1.x) /2.0,
        (p0.y + p1.y) /2.0
    };
}

@interface EasySignatureView () {
    UIBezierPath *path;
    CGPoint previousPoint;
}
@property (nonatomic,assign) BOOL isHaveDraw;
@property (assign,nonatomic) CGFloat pathWidth;
@property (assign,nonatomic) CGFloat touchForce;
@end

@implementation EasySignatureView

-(BOOL)check3DTouch
{
    if(self.traitCollection.forceTouchCapability == UIForceTouchCapabilityAvailable)
    {
        //ok
        return YES;
    }
    else
    {
        return NO;
        //notok
    }
}

-(instancetype)initWithLinePathWidth:(CGFloat)linePathWidth
{
    self = [super init];
    if (self) {
        self.pathWidth = linePathWidth;
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    
    path = [UIBezierPath bezierPath];
    [path setLineWidth:self.pathWidth];
    [path setLineCapStyle:kCGLineCapRound];
    [path setLineJoinStyle:kCGLineJoinRound];

    max = 0;
    min = 0;
    // Capture touches
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)];
    pan.maximumNumberOfTouches = pan.minimumNumberOfTouches =1;
    [self addGestureRecognizer:pan];
    
}

-(void)clearPan
{
    path = [UIBezierPath bezierPath];
    [path setLineWidth:self.pathWidth+1];
    
    [self setNeedsDisplay];
}


- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder])
        [self commonInit];
    self.currentPointArr = [NSMutableArray array];
    self.hasSignatureImg = NO;
    self.isHaveDraw = NO;
    return self;
}
- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
        [self commonInit];
    return self;
}


//void ProviderReleaseData (void *info,const void *data,size_t size)
//{
//    free((void*)data);
//}


- (UIImage*) imageBlackToTransparent:(UIImage*) image
{
    // 分配内存
    const int imageWidth = image.size.width;
    const int imageHeight = image.size.height;
    size_t      bytesPerRow = imageWidth * 4;
    uint32_t* rgbImageBuf = (uint32_t*)malloc(bytesPerRow * imageHeight);
    
    // 创建context
    CGColorSpaceRef colorSpace =CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(rgbImageBuf, imageWidth, imageHeight, 8, bytesPerRow, colorSpace,
                                                 kCGBitmapByteOrder32Little | kCGImageAlphaNoneSkipLast);
    
    CGContextDrawImage(context, CGRectMake(0, 0, imageWidth, imageHeight), image.CGImage);
    
    // 遍历像素
    int pixelNum = imageWidth * imageHeight;
    uint32_t* pCurPtr = rgbImageBuf;
    for (int i =0; i < pixelNum; i++, pCurPtr++)
    {
        //        if ((*pCurPtr & 0xFFFFFF00) == 0)    //将黑色变成透明
        if (*pCurPtr == 0xffffff)
        {
            uint8_t* ptr = (uint8_t*)pCurPtr;
            ptr[0] =0;
        }
        
        //改成下面的代码，会将图片转成灰度
        /*uint8_t* ptr = (uint8_t*)pCurPtr;
         // gray = red * 0.11 + green * 0.59 + blue * 0.30
         uint8_t gray = ptr[3] * 0.11 + ptr[2] * 0.59 + ptr[1] * 0.30;
         ptr[3] = gray;
         ptr[2] = gray;
         ptr[1] = gray;*/
    }
    
    // 将内存转成image
    CGDataProviderRef dataProvider = CGDataProviderCreateWithData(NULL, rgbImageBuf, bytesPerRow * imageHeight,/*ProviderReleaseData**/NULL);
    CGImageRef imageRef = CGImageCreate(imageWidth, imageHeight, 8,32, bytesPerRow, colorSpace,
                                        kCGImageAlphaLast | kCGBitmapByteOrder32Little, dataProvider,
                                        NULL, true,kCGRenderingIntentDefault);
    CGDataProviderRelease(dataProvider);
    
    UIImage* resultUIImage = [UIImage imageWithCGImage:imageRef];
    
    // 释放
    CGImageRelease(imageRef);
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    // free(rgbImageBuf) 创建dataProvider时已提供释放函数，这里不用free
    
    return resultUIImage;
}


-(void)handelSingleTap:(UITapGestureRecognizer*)tap
{
    return [self imageRepresentation];
}

-(void) imageRepresentation {
    
    if(&UIGraphicsBeginImageContextWithOptions !=NULL)
    {
        UIGraphicsBeginImageContextWithOptions(self.bounds.size,NO, [UIScreen mainScreen].scale);
    }
//    else {
//        UIGraphicsBeginImageContext(self.bounds.size);
//    }
    
    [self.layer renderInContext:UIGraphicsGetCurrentContext()];
    
    UIImage *image =UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    image = [self imageBlackToTransparent:image];
    
//    NSLog(@"width:%f,height:%f",image.size.width,image.size.height);
    
    if (kStringIsEmpty(self.showMessage))
    {
        self.SignatureImg = [self scaleToSize:image];
    }
    else
    {
        UIImage *img = [self cutImage:image];
        self.SignatureImg = [self scaleToSize:img];
    }
}

//压缩图片,最长边为128(根据不同的比例来压缩)
- (UIImage *)scaleToSize:(UIImage *)img {
    CGRect rect ;
//    CGFloat imageWidth = img.size.width;
    //判断图片宽度
//    if(imageWidth >= 128)
//    {
//        rect = CGRectMake(0,0, 128, self.frame.size.height);
//    }
//    else
//    {
//        rect = CGRectMake(0,0, img.size.width,self.frame.size.height);
//    }
    rect = CGRectMake(0,0, img.size.width,self.frame.size.height);

    CGSize size = rect.size;
    UIGraphicsBeginImageContext(size);
    [img drawInRect:rect];
    UIImage* scaledImage =UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    //此处注释是为了防止该签名图片被保存到本地
    //    UIImageWriteToSavedPhotosAlbum(scaledImage,nil, nil, nil);
    [self setNeedsDisplay];
    return scaledImage;
}

//只截取签名部分图片
- (UIImage *)cutImage:(UIImage *)image
{
    CGRect rect ;
    //签名事件没有发生
    if(min == 0&&max == 0)
    {
        rect =CGRectMake(0,0, 0, 0);
    }
    else//签名发生
    {
        rect =CGRectMake(min-3,0, max-min+6,self.frame.size.height);
    }
    CGImageRef imageRef =CGImageCreateWithImageInRect([image CGImage], rect);
    UIImage * img = [UIImage imageWithCGImage:imageRef];
    
    UIImage *lastImage = [self addText:img text:self.showMessage];
    CGImageRelease(imageRef);
    [self setNeedsDisplay];
    return lastImage;
}

//签名完成，给签名照添加新的水印
- (UIImage *) addText:(UIImage *)img text:(NSString *)mark {
    int w = img.size.width;
    int h = img.size.height;
    
    //根据截取图片大小改变文字大小
    CGFloat size = 20;
    UIFont *textFont = kDEFAULT_FONT(self.placeholderFont, size);
//    CGSize sizeOfTxt = [mark sizeWithFont:textFont constrainedToSize:CGSizeMake(128,30)];

    CGSize sizeOfTxt = [mark boundingRectWithSize:CGSizeMake(128,30) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:textFont} context:nil].size;

    if(w<sizeOfTxt.width)
    {
        
        while (sizeOfTxt.width>w) {
            size --;
//            textFont = [UIFont systemFontOfSize:size];
            textFont = kDEFAULT_FONT(self.placeholderFont, size);
//            sizeOfTxt = [mark sizeWithFont:textFont constrainedToSize:CGSizeMake(128,30)];
            sizeOfTxt = [mark boundingRectWithSize:CGSizeMake(128,30) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:textFont} context:nil].size;
        }
        
    }
    else
    {
        
        size =45;
//        textFont = [UIFont systemFontOfSize:size];
        textFont = kDEFAULT_FONT(self.placeholderFont, size);
//        sizeOfTxt = [mark sizeWithFont:textFont constrainedToSize:CGSizeMake(self.frame.size.width,30)];
        sizeOfTxt = [mark boundingRectWithSize:CGSizeMake(128,30) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:textFont} context:nil].size;
        while (sizeOfTxt.width>w) {
            size ++;
//            textFont = [UIFont systemFontOfSize:size];
            textFont = kDEFAULT_FONT(self.placeholderFont, size);
            sizeOfTxt = [mark boundingRectWithSize:CGSizeMake(128,30) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:textFont} context:nil].size;

//            sizeOfTxt = [mark sizeWithFont:textFont constrainedToSize:CGSizeMake(self.frame.size.width,30)];
        }
        
    }
    UIGraphicsBeginImageContext(img.size);
    [[UIColor redColor] set];
    [img drawInRect:CGRectMake(0,0, w, h)];
//    [mark drawInRect:CGRectMake((w-sizeOfTxt.width)/2,(h-sizeOfTxt.height)/2, sizeOfTxt.width, sizeOfTxt.height)withFont:textFont];
    [mark drawInRect:CGRectMake((w-sizeOfTxt.width)/2,(h-sizeOfTxt.height)/2, sizeOfTxt.width, sizeOfTxt.height) withAttributes:@{NSFontAttributeName:textFont}];
    UIImage *aimg =UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return aimg;
}

- (void)pan:(UIPanGestureRecognizer *)pan {
    CGPoint currentPoint = [pan locationInView:self];
    CGPoint midPoint = midpoint(previousPoint, currentPoint);
//    NSLog(@"获取到的触摸点的位置为--currentPoint:%@",NSStringFromCGPoint(currentPoint));
    [self.currentPointArr addObject:[NSValue valueWithCGPoint:currentPoint]];
    self.hasSignatureImg = YES;
    CGFloat viewHeight = self.frame.size.height;
    CGFloat currentY = currentPoint.y;
    if (pan.state ==UIGestureRecognizerStateBegan)
    {
        [path moveToPoint:currentPoint];
    }
    else if (pan.state ==UIGestureRecognizerStateChanged)
    {
        [path addQuadCurveToPoint:midPoint controlPoint:previousPoint];
    }
    
    if(0 <= currentY && currentY <= viewHeight)
    {
        if(max == 0&&min == 0)
        {
            max = currentPoint.x;
            min = currentPoint.x;
        }
        else
        {
            if(max <= currentPoint.x)
            {
                max = currentPoint.x;
            }
            if(min>=currentPoint.x)
            {
                min = currentPoint.x;
            }
        }
        
    }
    
    previousPoint = currentPoint;
    
    [self setNeedsDisplay];
    self.isHaveDraw = YES;
    if (self.delegate != nil &&[self.delegate respondsToSelector:@selector(onSignatureWriteAction)]) {
        [self.delegate onSignatureWriteAction];
    }
}

- (void)drawRect:(CGRect)rect
{
    self.backgroundColor = UIColor.whiteColor;
    PNSLog(@">>>>>>>>%f",self.touchForce);
    if ([self check3DTouch])
    {
        [UIColor colorWithWhite:0 alpha:self.pathWidth*(1-self.touchForce)];
    }
    else
    {
        [UIColor.blackColor setStroke];
    }
    [path stroke];
    
    /*self.layer.cornerRadius =5.0;
     self.clipsToBounds =YES;
     self.layer.borderWidth =0.5;
     self.layer.borderColor = [[UIColor grayColor] CGColor];*/
    
//    CGContextRef context =UIGraphicsGetCurrentContext();
    
    
    PNSLog(@">>>>>>>>>>%f",rect.size.width);
    
    if(!isSure && !self.isHaveDraw)
    {
        NSString *str = @"请在白色区域手写签名:正楷,工整书写";
        CGFloat labelW = kAdaptedWidth(15)*str.length;
        CGRect rect1 = CGRectMake((rect.size.width -labelW)/2, (rect.size.height -StrHeight)/2,labelW, StrHeight);
        origionX = rect1.origin.x;
        totalWidth = rect1.origin.x+labelW;
        UIFont  *font = kDEFAULT_FONT(self.placeholderFont, kAdaptedWidth(15));//设置字体
        [str drawAtPoint:CGPointMake(rect1.origin.x, rect1.origin.y-rect1.size.height/2) withAttributes:@{NSFontAttributeName:font,NSForegroundColorAttributeName:kRGBAColor(199, 199, 199, 1)}];
    }
    else
    {
        isSure = NO;
    }
}

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    if ([self check3DTouch])
    {
        self.touchForce = touch.force;
//        NSString * touchForce = [NSString stringWithFormat:@"%f",touch.force];
//        self.pointForces = @[touchForce,touchForce,touchForce];
    }
}

-(void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    if ([self check3DTouch])
    {
        NSLog(@"%f",touch.force);
    }
    
    if ([self check3DTouch])
    {
        self.touchForce = touch.force;
//        NSString * touchForce = [NSString stringWithFormat:@"%f",touch.force];
//        self.pointForces = @[self.pointForces[1],self.pointForces[2],touchForce];
    }
}


- (void)clear
{
    if (self.currentPointArr && self.currentPointArr.count > 0) {
        [self.currentPointArr removeAllObjects];
    }
    self.hasSignatureImg = NO;
    max = 0;
    min = 0;
    path = [UIBezierPath bezierPath];
    [path setLineWidth:self.pathWidth];
    self.isHaveDraw = NO;
    [self setNeedsDisplay];
    
}

- (void)sure
{
    //没有签名发生时
    if(min == 0&&max == 0)
    {
        min = 0;
        max = 0;
    }
    isSure = YES;
    [self setNeedsDisplay];
    return [self imageRepresentation];
}


@end
