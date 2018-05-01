//
//  PGifHud.m
//  adasdasdadadasdasdadadadad
//
//  Created by MYX on 2017/4/25.
//  Copyright © 2017年 邓杰豪. All rights reserved.
//

#import "PGifHud.h"
#import <ImageIO/ImageIO.h>
#import "PMacros.h"


#define Size            150
#define FadeDuration    0.3
#define GifSpeed        0.3

#if __has_feature(objc_arc)
#define toCF (__bridge CFTypeRef)
#define fromCF (__bridge id)
#else
#define toCF (CFTypeRef)
#define fromCF (id)
#endif

#pragma mark - UIImage Animated GIF


@implementation UIImage (animatedGIF)

static int delayCentisecondsForImageAtIndex(CGImageSourceRef const source, size_t const i) {
    int delayCentiseconds = 1;
    CFDictionaryRef const properties = CGImageSourceCopyPropertiesAtIndex(source, i, NULL);
    if (properties) {
        CFDictionaryRef const gifProperties = CFDictionaryGetValue(properties, kCGImagePropertyGIFDictionary);
        if (gifProperties) {
            NSNumber *number = fromCF CFDictionaryGetValue(gifProperties, kCGImagePropertyGIFUnclampedDelayTime);
            if (number == NULL || [number doubleValue] == 0) {
                number = fromCF CFDictionaryGetValue(gifProperties, kCGImagePropertyGIFDelayTime);
            }
            if ([number doubleValue] > 0) {
                delayCentiseconds = (int)lrint([number doubleValue] * 100);
            }
        }
        CFRelease(properties);
    }
    return delayCentiseconds;
}

static void createImagesAndDelays(CGImageSourceRef source, size_t count, CGImageRef imagesOut[count], int delayCentisecondsOut[count]) {
    for (size_t i = 0; i < count; ++i) {
        imagesOut[i] = CGImageSourceCreateImageAtIndex(source, i, NULL);
        delayCentisecondsOut[i] = delayCentisecondsForImageAtIndex(source, i);
    }
}

static int sum(size_t const count, int const *const values) {
    int theSum = 0;
    for (size_t i = 0; i < count; ++i) {
        theSum += values[i];
    }
    return theSum;
}

static int pairGCD(int a, int b) {
    if (a < b)
        return pairGCD(b, a);
    while (true) {
        int const r = a % b;
        if (r == 0)
            return b;
        a = b;
        b = r;
    }
}

static int vectorGCD(size_t const count, int const *const values) {
    int gcd = values[0];
    for (size_t i = 1; i < count; ++i) {
        gcd = pairGCD(values[i], gcd);
    }
    return gcd;
}

static NSArray *frameArray(size_t const count, CGImageRef const images[count], int const delayCentiseconds[count], int const totalDurationCentiseconds) {
    int const gcd = vectorGCD(count, delayCentiseconds);
    size_t const frameCount = totalDurationCentiseconds / gcd;
    UIImage *frames[frameCount];
    for (size_t i = 0, f = 0; i < count; ++i) {
        UIImage *const frame = [UIImage imageWithCGImage:images[i]];
        for (size_t j = delayCentiseconds[i] / gcd; j > 0; --j) {
            frames[f++] = frame;
        }
    }
    return [NSArray arrayWithObjects:frames count:frameCount];
}

static void releaseImages(size_t const count, CGImageRef const images[count]) {
    for (size_t i = 0; i < count; ++i) {
        CGImageRelease(images[i]);
    }
}

static UIImage *animatedImageWithAnimatedGIFImageSource(CGImageSourceRef const source) {
    size_t const count = CGImageSourceGetCount(source);
    CGImageRef images[count];
    int delayCentiseconds[count];
    createImagesAndDelays(source, count, images, delayCentiseconds);
    int const totalDurationCentiseconds = sum(count, delayCentiseconds);
    NSArray *const frames = frameArray(count, images, delayCentiseconds, totalDurationCentiseconds);
    UIImage *const animation = [UIImage animatedImageWithImages:frames duration:(NSTimeInterval)totalDurationCentiseconds / 100.0];
    releaseImages(count, images);
    return animation;
}

static UIImage *animatedImageWithAnimatedGIFReleasingImageSource(CGImageSourceRef CF_RELEASES_ARGUMENT source) {
    if (source) {
        UIImage *const image = animatedImageWithAnimatedGIFImageSource(source);
        CFRelease(source);
        return image;
    } else {
        return nil;
    }
}

+ (UIImage *)animatedImageWithAnimatedGIFData:(NSData *)data {
    return animatedImageWithAnimatedGIFReleasingImageSource(CGImageSourceCreateWithData(toCF data, NULL));
}

+ (UIImage *)animatedImageWithAnimatedGIFURL:(NSURL *)url {
    return animatedImageWithAnimatedGIFReleasingImageSource(CGImageSourceCreateWithURL(toCF url, NULL));
}

@end

#pragma mark ---------------> GiFHUD Private
@interface PGifHud ()

@property (nonatomic, strong) UIView *_contentView;
@property (nonatomic, strong) UIView *overlayView;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, assign) BOOL shown;
@property (nonatomic, strong) UILabel *infoLabel;

@end



#pragma mark ---------------> GiFHUD Implementation

@implementation PGifHud

static PGifHud *instance = nil;

#pragma mark ---------------> Lifecycle

+(void)gifHUDShowIn:(id)views
{
    [[self instance] initShowInView:views];
    
}

+ (instancetype)instance
{
    @synchronized (self) {
        if (!instance) {
            instance = [[PGifHud alloc] init];
        }
        return instance;
    }
}

-(void)initShowInView:(id)contentView
{
    CGFloat hudW = 250;
    
    self.frame = CGRectMake(0, 0, hudW, Size);
    
    self._contentView = contentView;
    
    [self setAlpha:0];
    [self setCenter:self._contentView.center];
    [self setClipsToBounds:NO];
    
    [self.layer setBackgroundColor:[UIColor whiteColor].CGColor];
    [self.layer setCornerRadius:10];
    [self.layer setMasksToBounds:YES];
    
    self.imageView = [[UIImageView alloc] initWithFrame:CGRectMake((hudW-100)/2, 5, 100, 100)];
    [self addSubview:self.imageView];
    
    self.infoLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, self.imageView.frame.size.height+10, (hudW-100)/2, 30)];
    self.infoLabel.textAlignment = NSTextAlignmentCenter;
    self.infoLabel.numberOfLines = 0;
    self.infoLabel.lineBreakMode = NSLineBreakByCharWrapping;
    self.infoLabel.textColor = [UIColor blackColor];
    self.infoLabel.font = [UIFont systemFontOfSize:18];
    [self addSubview:self.infoLabel];
    
    [self._contentView addSubview:self];
}

#pragma mark ---------------> HUD
+ (void)showWithOverlay {
    [self dismiss:^{
        [instance._contentView addSubview:[[self instance] overlay]];
        [self show];
    }];
}

+ (void)show {
    [self dismiss:^{
        [instance._contentView bringSubviewToFront:[self instance]];
        [[self instance] setShown:YES];
        [[self instance] fadeIn];
    }];
}


+ (void)dismiss {
    if (![[self instance] shown])
        return;
    
    [[[self instance] overlay] removeFromSuperview];
    [[self instance] fadeOut];
}

+ (void)dismiss:(void(^)(void))complated {
    if (![[self instance] shown])
        return complated ();
    
    [[self instance] fadeOutComplate:^{
        [[[self instance] overlay] removeFromSuperview];
        complated ();
    }];
}

#pragma mark ---------------> Effects
- (void)fadeIn {
    [self.imageView startAnimating];
    [UIView animateWithDuration:FadeDuration animations:^{
        [self setAlpha:1];
    }];
}

- (void)fadeOut {
    [UIView animateWithDuration:FadeDuration animations:^{
        [self setAlpha:0];
    } completion:^(BOOL finished) {
        [self setShown:NO];
        [self.imageView stopAnimating];
    }];
}

- (void)fadeOutComplate:(void(^)(void))complated {
    [UIView animateWithDuration:FadeDuration animations:^{
        [self setAlpha:0];
    } completion:^(BOOL finished) {
        [self setShown:NO];
        [self.imageView stopAnimating];
        complated ();
    }];
}


- (UIView *)overlay {
    
    if (!self.overlayView) {
        self.overlayView = [[UIView alloc] initWithFrame:self._contentView.frame];
        [self.overlayView setBackgroundColor:[UIColor blackColor]];
        [self.overlayView setAlpha:0];
        
        [UIView animateWithDuration:FadeDuration animations:^{
            [self.overlayView setAlpha:0.3];
        }];
    }
    return self.overlayView;
}

#pragma mark ---------------> Gif
+(NSMutableArray *)showLoading:(NSArray *)images
{
    NSMutableArray *arr = [[NSMutableArray alloc] init];
    for (int i = 0; i < images.count; i++) {
        NSString *imageStr = images[i];
        if ([imageStr isKindOfClass:[NSString class]]) {
            UIImage *image = [UIImage imageNamed:imageStr];
            [arr addObject:image];
        }
        else if ([imageStr isKindOfClass:[UIImage class]])
        {
            [arr addObject:imageStr];
        }
    }
    return arr;
}

+(NSMutableArray *)showSuccess:(NSString *)successImage
{
    NSMutableArray *arr = [[NSMutableArray alloc] init];
    [arr addObject:[UIImage imageNamed:successImage]];
    return arr;
}

+(NSMutableArray *)showFail:(NSString *)failImage
{
    NSMutableArray *arr = [[NSMutableArray alloc] init];
    [arr addObject:[UIImage imageNamed:failImage]];
    return arr;
}

+(void)setInfoLabelText:(NSString *)str
{
    [[self instance] infoLabel].text = str;
}

+ (void)setGifWithImages:(NSArray *)images
{
    [[[self instance] imageView] setAnimationImages:[self showLoading:images]];
    [[[self instance] imageView] setAnimationDuration:GifSpeed];
}

+ (void)setSuccessHub:(NSString *)successImage
{
    [[[self instance] imageView] setAnimationImages:[self showSuccess:successImage]];
    [[[self instance] imageView] setAnimationDuration:GifSpeed];
}

+ (void)setFailHub:(NSString *)failImage
{
    [[[self instance] imageView] setAnimationImages:[self showFail:failImage]];
    [[[self instance] imageView] setAnimationDuration:GifSpeed];
}

+ (void)setGifWithImageName:(NSString *)imageName {
    [[[self instance] imageView] stopAnimating];
    [[[self instance] imageView] setImage:[UIImage animatedImageWithAnimatedGIFURL:[[NSBundle mainBundle] URLForResource:imageName withExtension:nil]]];
}

+ (void)setGifWithURL:(NSURL *)gifUrl {
    [[[self instance] imageView] stopAnimating];
    [[[self instance] imageView] setImage:[UIImage animatedImageWithAnimatedGIFURL:gifUrl]];
}

@end
