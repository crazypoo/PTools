// Copyright (C) 2013 by Benjamin Gordon
//
// Permission is hereby granted, free of charge, to any
// person obtaining a copy of this software and
// associated documentation files (the "Software"), to
// deal in the Software without restriction, including
// without limitation the rights to use, copy, modify, merge,
// publish, distribute, sublicense, and/or sell copies of the
// Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall
// be included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
// OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
// BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
// ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#import "UIColor+Colours.h"
#import <objc/runtime.h>

#pragma mark - Static Block
static CGFloat (^RAD)(CGFloat) = ^CGFloat (CGFloat degree){
    return degree * M_PI/180;
};


#pragma mark - Create correct iOS/OSX implementation
#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
@implementation UIColor (Colours)
#define ColorClass UIColor

#elif TARGET_OS_MAC
#import <AppKit/AppKit.h>
@implementation NSColor (Colours)
#define ColorClass NSColor

#endif


#pragma mark - Color from Hex
+ (instancetype)colorFromHexString:(NSString *)hexString
{
    unsigned rgbValue = 0;
    hexString = [hexString stringByReplacingOccurrencesOfString:@"#" withString:@""];
    NSScanner *scanner = [NSScanner scannerWithString:hexString];
    [scanner scanHexInt:&rgbValue];
    
    return [[self class] colorWithR:((rgbValue & 0xFF0000) >> 16) G:((rgbValue & 0xFF00) >> 8) B:(rgbValue & 0xFF) A:1.0];
}


#pragma mark - Hex from Color
- (NSString *)hexString
{
    NSArray *colorArray	= [self rgbaArray];
    int r = [colorArray[0] floatValue] * 255;
    int g = [colorArray[1] floatValue] * 255;
    int b = [colorArray[2] floatValue] * 255;
    NSString *red = [NSString stringWithFormat:@"%02x", r];
    NSString *green = [NSString stringWithFormat:@"%02x", g];
    NSString *blue = [NSString stringWithFormat:@"%02x", b];
    
    return [NSString stringWithFormat:@"#%@%@%@", red, green, blue];
}


#pragma mark - Color from RGBA
+ (instancetype)colorFromRGBAArray:(NSArray *)rgbaArray
{
    if (rgbaArray.count < 4) {
        return [[self class] clearColor];
    }
    
    return [[self class] colorWithRed:[rgbaArray[0] floatValue]
                                green:[rgbaArray[1] floatValue]
                                 blue:[rgbaArray[2] floatValue]
                                alpha:[rgbaArray[3] floatValue]];
}

+ (instancetype)colorFromRGBADictionary:(NSDictionary *)rgbaDict
{
    if (rgbaDict[kColoursRGBA_R] && rgbaDict[kColoursRGBA_G] && rgbaDict[kColoursRGBA_B] && rgbaDict[kColoursRGBA_A]) {
        return [[self class] colorWithRed:[rgbaDict[kColoursRGBA_R] floatValue]
                                    green:[rgbaDict[kColoursRGBA_G] floatValue]
                                     blue:[rgbaDict[kColoursRGBA_B] floatValue]
                                    alpha:[rgbaDict[kColoursRGBA_A] floatValue]];
    }
    
    return [[self class] clearColor];
}


#pragma mark - RGBA from Color
- (NSArray *)rgbaArray
{
    CGFloat r=0,g=0,b=0,a=0;
    
    if ([self respondsToSelector:@selector(getRed:green:blue:alpha:)]) {
        [self getRed:&r green:&g blue:&b alpha:&a];
    }
    else {
        const CGFloat *components = CGColorGetComponents(self.CGColor);
        r = components[0];
        g = components[1];
        b = components[2];
        a = components[3];
    }
    
    return @[@(r),
             @(g),
             @(b),
             @(a)];
}

- (NSDictionary *)rgbaDictionary
{
    CGFloat r=0,g=0,b=0,a=0;
    if ([self respondsToSelector:@selector(getRed:green:blue:alpha:)]) {
        [self getRed:&r green:&g blue:&b alpha:&a];
    }
    else {
        const CGFloat *components = CGColorGetComponents(self.CGColor);
        r = components[0];
        g = components[1];
        b = components[2];
        a = components[3];
    }
    
    return @{kColoursRGBA_R:@(r),
             kColoursRGBA_G:@(g),
             kColoursRGBA_B:@(b),
             kColoursRGBA_A:@(a)};
}


#pragma mark - HSBA from Color
- (NSArray *)hsbaArray
{
    // Takes a [self class] and returns Hue,Saturation,Brightness,Alpha values in NSNumber form
    CGFloat h=0,s=0,b=0,a=0;
    
    if ([self respondsToSelector:@selector(getHue:saturation:brightness:alpha:)]) {
        [self getHue:&h saturation:&s brightness:&b alpha:&a];
    }
    
    return @[@(h),
             @(s),
             @(b),
             @(a)];
}

- (NSDictionary *)hsbaDictionary
{
    CGFloat h=0,s=0,b=0,a=0;
    
    if ([self respondsToSelector:@selector(getHue:saturation:brightness:alpha:)]) {
        [self getHue:&h saturation:&s brightness:&b alpha:&a];
    }
    
    return @{kColoursHSBA_H:@(h),
             kColoursHSBA_S:@(s),
             kColoursHSBA_B:@(b),
             kColoursHSBA_A:@(a)};
}


#pragma mark - Color from HSBA
+ (instancetype)colorFromHSBAArray:(NSArray *)hsbaArray
{
    if (hsbaArray.count < 4) {
        return [[self class] clearColor];
    }
    
    return [[self class] colorWithHue:[hsbaArray[0] doubleValue]
                           saturation:[hsbaArray[1] doubleValue]
                           brightness:[hsbaArray[2] doubleValue]
                                alpha:[hsbaArray[3] doubleValue]];
}

+ (instancetype)colorFromHSBADictionary:(NSDictionary *)hsbaDict
{
    if (hsbaDict[kColoursHSBA_H] && hsbaDict[kColoursHSBA_S] && hsbaDict[kColoursHSBA_B] && hsbaDict[kColoursHSBA_A]) {
        return [[self class] colorWithHue:[hsbaDict[kColoursHSBA_H] doubleValue]
                               saturation:[hsbaDict[kColoursHSBA_S] doubleValue]
                               brightness:[hsbaDict[kColoursHSBA_B] doubleValue]
                                    alpha:[hsbaDict[kColoursHSBA_A] doubleValue]];
    }
    
    return [[self class] clearColor];
}


#pragma mark - LAB from Color
- (NSArray *)CIE_LabArray {
    // Convert Color to XYZ format first
    NSArray *rgba = [self rgbaArray];
    CGFloat R = [rgba[0] floatValue];
    CGFloat G = [rgba[1] floatValue];
    CGFloat B = [rgba[2] floatValue];
    
    // Create deltaR block
    void (^deltaRGB)(CGFloat *R);
    deltaRGB = ^(CGFloat *R) {
        *R = (*R > 0.04045) ? pow((*R + 0.055)/1.055, 2.40) : (*R/12.92);
    };
    deltaRGB(&R);
    deltaRGB(&G);
    deltaRGB(&B);
    CGFloat X = R*41.24 + G*35.76 + B*18.05;
    CGFloat Y = R*21.26 + G*71.52 + B*7.22;
    CGFloat Z = R*1.93 + G*11.92 + B*95.05;
    
    // Convert XYZ to L*a*b*
    X = X/95.047;
    Y = Y/100.000;
    Z = Z/108.883;
    
    // Create deltaF block
    void (^deltaF)(CGFloat *f);
    deltaF = ^(CGFloat *f){
        *f = (*f > pow((6.0/29.0), 3.0)) ? pow(*f, 1.0/3.0) : (1/3)*pow((29.0/6.0), 2.0) * *f + 4/29.0;
    };
    deltaF(&X);
    deltaF(&Y);
    deltaF(&Z);
    NSNumber *L = @(116*Y - 16);
    NSNumber *a = @(500 * (X - Y));
    NSNumber *b = @(200 * (Y - Z));
    
    return @[L,
             a,
             b,
             rgba[3]];
}

- (NSDictionary *)CIE_LabDictionary {
    NSArray *colors = [self CIE_LabArray];
    return @{kColoursCIE_L:colors[0],
             kColoursCIE_A:colors[1],
             kColoursCIE_B:colors[2],
             kColoursCIE_alpha:colors[3],};
}


#pragma mark - Color from LAB
+ (instancetype)colorFromCIE_LabArray:(NSArray *)colors {
    if (!colors || colors.count < 4) {
        return [[self class] clearColor];
    }
    
    // Convert LAB to XYZ
    CGFloat L = [colors[0] floatValue];
    CGFloat A = [colors[1] floatValue];
    CGFloat B = [colors[2] floatValue];
    CGFloat Y = (L + 16.0)/116.0;
    CGFloat X = A/500 + Y;
    CGFloat Z = Y - B/200;
    
    void (^deltaXYZ)(CGFloat *);
    deltaXYZ = ^(CGFloat *k){
        *k = (pow(*k, 3.0) > 0.008856) ? pow(*k, 3.0) : (*k - 4/29.0)/7.787;
    };
    
    deltaXYZ(&X);
    deltaXYZ(&Y);
    deltaXYZ(&Z);
    X = X*.95047;
    Y = Y*1.00000;
    Z = Z*1.08883;
    
    // Convert XYZ to RGB
    CGFloat R = X*3.2406 + Y*-1.5372 + Z*-0.4986;
    CGFloat G = X*-0.9689 + Y*1.8758 + Z*0.0415;
    CGFloat _B = X*0.0557 + Y*-0.2040 + Z*1.0570;
    
    void (^deltaRGB)(CGFloat *);
    deltaRGB = ^(CGFloat *k){
        *k = (*k > 0.0031308) ? 1.055 * (pow(*k, (1/2.4))) - 0.055 : *k * 12.92;
    };
    
    deltaRGB(&R);
    deltaRGB(&G);
    deltaRGB(&_B);
    
    // return Color
    return [[self class] colorFromRGBAArray:@[@(R), @(G), @(_B), colors[3]]];
}

+ (instancetype)colorFromCIE_LabDictionary:(NSDictionary *)colors {
    if (!colors) {
        return [[self class] clearColor];
    }
    
    if (colors[kColoursCIE_L] && colors[kColoursCIE_A] && colors[kColoursCIE_B] && colors[kColoursCIE_alpha]) {
        return [self colorFromCIE_LabArray:@[colors[kColoursCIE_L],
                                             colors[kColoursCIE_A],
                                             colors[kColoursCIE_B],
                                             colors[kColoursCIE_alpha]]];
    }
    
    return [[self class] clearColor];
}


#pragma mark - Color to CMYK
- (NSArray *)cmykArray
{
    // Convert RGB to CMY
    NSArray *rgb = [self rgbaArray];
    CGFloat C = 1 - [rgb[0] floatValue];
    CGFloat M = 1 - [rgb[1] floatValue];
    CGFloat Y = 1 - [rgb[2] floatValue];
    
    // Find K
    CGFloat K = MIN(1, MIN(C, MIN(Y, M)));
    if (K == 1) {
        C = 0;
        M = 0;
        Y = 0;
    }
    else {
        void (^newCMYK)(CGFloat *);
        newCMYK = ^(CGFloat *x){
            *x = (*x - K)/(1 - K);
        };
        newCMYK(&C);
        newCMYK(&M);
        newCMYK(&Y);
    }
    
    return @[@(C),
             @(M),
             @(Y),
             @(K)];
}

- (NSDictionary *)cmykDictionary
{
    NSArray *colors = [self cmykArray];
    return @{kColoursCMYK_C:colors[0],
             kColoursCMYK_M:colors[1],
             kColoursCMYK_Y:colors[2],
             kColoursCMYK_K:colors[3]};
}

#pragma mark - CMYK to Color
+ (instancetype)colorFromCMYKArray:(NSArray *)cmyk
{
    if (!cmyk || cmyk.count < 4) {
        return [[self class] clearColor];
    }
    
    // Find CMY values
    CGFloat C = [cmyk[0] floatValue];
    CGFloat M = [cmyk[1] floatValue];
    CGFloat Y = [cmyk[2] floatValue];
    CGFloat K = [cmyk[3] floatValue];
    void (^cmyTransform)(CGFloat *);
    cmyTransform = ^(CGFloat *x){
        *x = *x * (1 - K) + K;
    };
    cmyTransform(&C);
    cmyTransform(&M);
    cmyTransform(&Y);
    
    // Translate CMY to RGB
    CGFloat R = 1 - C;
    CGFloat G = 1 - M;
    CGFloat B = 1 - Y;
    
    // return the Color
    return [[self class] colorFromRGBAArray:@[@(R),
                                              @(G),
                                              @(B),
                                              @(1)]];
}

+ (instancetype)colorFromCMYKDictionary:(NSDictionary *)cmyk
{
    if (!cmyk) {
        return [[self class] clearColor];
    }
    
    if (cmyk[kColoursCMYK_C] && cmyk[kColoursCMYK_M] && cmyk[kColoursCMYK_Y] && cmyk[kColoursCMYK_K]) {
        return [[self class] colorFromCMYKArray:@[cmyk[kColoursCMYK_C],
                                                  cmyk[kColoursCMYK_M],
                                                  cmyk[kColoursCMYK_Y],
                                                  cmyk[kColoursCMYK_K]]];
    }
    
    return [[self class] clearColor];
}


#pragma mark - Color Components
- (NSDictionary *)colorComponents
{
    NSMutableDictionary *components = [[self rgbaDictionary] mutableCopy];
    [components addEntriesFromDictionary:[self hsbaDictionary]];
    [components addEntriesFromDictionary:[self CIE_LabDictionary]];
    return components;
}

- (CGFloat)red
{
    return [[self rgbaArray][0] floatValue];
}

- (CGFloat)green
{
    return [[self rgbaArray][1] floatValue];
}

- (CGFloat)blue
{
    return [[self rgbaArray][2] floatValue];
}

- (CGFloat)hue
{
    return [[self hsbaArray][0] floatValue];
}

- (CGFloat)saturation
{
    return [[self hsbaArray][1] floatValue];
}

- (CGFloat)brightness
{
    return [[self hsbaArray][2] floatValue];
}

- (CGFloat)alpha
{
    return [[self rgbaArray][3] floatValue];
}

- (CGFloat)CIE_Lightness
{
    return [[self CIE_LabArray][0] floatValue];
}

- (CGFloat)CIE_a
{
    return [[self CIE_LabArray][1] floatValue];
}

- (CGFloat)CIE_b
{
    return [[self CIE_LabArray][2] floatValue];
}

- (CGFloat)cyan {
    return [[self cmykArray][0] floatValue];
}

- (CGFloat)magenta {
    return [[self cmykArray][1] floatValue];
}

- (CGFloat)yellow {
    return [[self cmykArray][2] floatValue];
}

- (CGFloat)keyBlack {
    return [[self cmykArray][3] floatValue];
}


#pragma mark - Darken/Lighten
- (instancetype)darken:(CGFloat)percentage {
    return [self modifyBrightnessByPercentage:percentage];
}

- (instancetype)lighten:(CGFloat)percentage {
    return [self modifyBrightnessByPercentage:percentage+1.0];
}

- (instancetype)modifyBrightnessByPercentage:(CGFloat)percentage {
    NSMutableDictionary *hsba = [[self hsbaDictionary] mutableCopy];
    [hsba setObject:@([hsba[kColoursHSBA_B] floatValue] * percentage) forKey:kColoursHSBA_B];
    return [ColorClass colorFromHSBADictionary:hsba];
}


#pragma mark - Generate Color Scheme
- (NSArray *)colorSchemeOfType:(ColorScheme)type
{
    NSArray *hsbArray = [self hsbaArray];
    float hue = [hsbArray[0] floatValue] * 360;
    float sat = [hsbArray[1] floatValue] * 100;
    float bright = [hsbArray[2] floatValue] * 100;
    float alpha = [hsbArray[3] floatValue];
    
    switch (type) {
        case ColorSchemeAnalagous:
            return [[self class] analagousColorsFromHue:hue saturation:sat brightness:bright alpha:alpha];
        case ColorSchemeMonochromatic:
            return [[self class] monochromaticColorsFromHue:hue saturation:sat brightness:bright alpha:alpha];
        case ColorSchemeTriad:
            return [[self class] triadColorsFromHue:hue saturation:sat brightness:bright alpha:alpha];
        case ColorSchemeComplementary:
            return [[self class] complementaryColorsFromHue:hue saturation:sat brightness:bright alpha:alpha];
        default:
            return nil;
    }
}


#pragma mark - Color Scheme Generation - Helper methods
+ (NSArray *)analagousColorsFromHue:(float)h saturation:(float)s brightness:(float)b alpha:(float)a
{
    return @[[[self class] colorWithHue:[[self class] addDegrees:30 toDegree:h]/360 saturation:(s-5)/100 brightness:(b-10)/100 alpha:a],
             [[self class] colorWithHue:[[self class] addDegrees:15 toDegree:h]/360 saturation:(s-5)/100 brightness:(b-5)/100 alpha:a],
             [[self class] colorWithHue:[[self class] addDegrees:-15 toDegree:h]/360 saturation:(s-5)/100 brightness:(b-5)/100 alpha:a],
             [[self class] colorWithHue:[[self class] addDegrees:-30 toDegree:h]/360 saturation:(s-5)/100 brightness:(b-10)/100 alpha:a]];
}

+ (NSArray *)monochromaticColorsFromHue:(float)h saturation:(float)s brightness:(float)b alpha:(float)a
{
    return @[[[self class] colorWithHue:h/360 saturation:(s/2)/100 brightness:(b/3)/100 alpha:a],
             [[self class] colorWithHue:h/360 saturation:s/100 brightness:(b/2)/100 alpha:a],
             [[self class] colorWithHue:h/360 saturation:(s/3)/100 brightness:(2*b/3)/100 alpha:a],
             [[self class] colorWithHue:h/360 saturation:s/100 brightness:(4*b/5)/100 alpha:a]];
}

+ (NSArray *)triadColorsFromHue:(float)h saturation:(float)s brightness:(float)b alpha:(float)a
{
    return @[[[self class] colorWithHue:[[self class] addDegrees:120 toDegree:h]/360 saturation:(7*s/6)/100 brightness:(b-5)/100 alpha:a],
             [[self class] colorWithHue:[[self class] addDegrees:120 toDegree:h]/360 saturation:s/100 brightness:b/100 alpha:a],
             [[self class] colorWithHue:[[self class] addDegrees:240 toDegree:h]/360 saturation:s/100 brightness:b/100 alpha:a],
             [[self class] colorWithHue:[[self class] addDegrees:240 toDegree:h]/360 saturation:(7*s/6)/100 brightness:(b-5)/100 alpha:a]];
}

+ (NSArray *)complementaryColorsFromHue:(float)h saturation:(float)s brightness:(float)b alpha:(float)a
{
    return @[[[self class] colorWithHue:h/360 saturation:s/100 brightness:(4*b/5)/100 alpha:a],
             [[self class] colorWithHue:h/360 saturation:(5*s/7)/100 brightness:b/100 alpha:a],
             [[self class] colorWithHue:[[self class] addDegrees:180 toDegree:h]/360 saturation:s/100 brightness:b/100 alpha:a],
             [[self class] colorWithHue:[[self class] addDegrees:180 toDegree:h]/360 saturation:(5*s/7)/100 brightness:b/100 alpha:a]];
}


#pragma mark - Contrasting Color
- (instancetype)blackOrWhiteContrastingColor
{
    NSArray *rgbaArray = [self rgbaArray];
    double a = 1 - ((0.299 * [rgbaArray[0] doubleValue]) + (0.587 * [rgbaArray[1] doubleValue]) + (0.114 * [rgbaArray[2] doubleValue]));
    return a < 0.5 ? [[self class] blackColor] : [[self class] whiteColor];
}


#pragma mark - Complementary Color
- (instancetype)complementaryColor
{
    NSMutableDictionary *hsba = [[self hsbaDictionary] mutableCopy];
    float newH = [[self class] addDegrees:180.0f toDegree:([hsba[kColoursHSBA_H] floatValue]*360.0f)];
    [hsba setObject:@(newH/360.0f) forKey:kColoursHSBA_H];
    return [[self class] colorFromHSBADictionary:hsba];
}


#pragma mark - Distance between Colors
- (CGFloat)distanceFromColor:(id)color
{
    // Defaults to CIE94
    return [self distanceFromColor:color type:ColorDistanceCIE94];
}

- (CGFloat)distanceFromColor:(id)color type:(ColorDistance)distanceType {
    /**
     *
     *  Detecting a difference in two colors is not as trivial as it sounds.
     *  One's first instinct is to go for a difference in RGB values, leaving
     *  you with a sum of the differences of each point. It looks great! Until
     *  you actually start comparing colors. Why do these two reds have a different
     *  distance than these two blues *in real life* vs computationally?
     *  Human visual perception is next in the line of things between a color
     *  and your brain. Some colors are just perceived to have larger variants inside
     *  of their respective areas than others, so we need a way to model this
     *  human variable to colors. Enter CIELAB. This color formulation is supposed to be
     *  this model. So now we need to standardize a unit of distance between any two
     *  colors that works independent of how humans visually perceive that distance.
     *  Enter CIE76,94,2000. These are methods that use user-tested data and other
     *  mathematically and statistically significant correlations to output this info.
     *  You can read the wiki articles below to get a better understanding historically
     *  of how we moved to newer and better color distance formulas, and what
     *  their respective pros/cons are.
     *
     *  References:
     *  
     *  http://en.wikipedia.org/wiki/Color_difference
     *  http://en.wikipedia.org/wiki/Just_noticeable_difference
     *  http://en.wikipedia.org/wiki/CIELAB
     *
     */
    
    // Check if it's a color
    if (![color isKindOfClass:[self class]]) {
        // NSLog(@"Not a %@ object.", NSStringFromClass([self class]));
        return MAXFLOAT;
    }
    
    // Set Up Common Variables
    NSArray *lab1 = [self CIE_LabArray];
    NSArray *lab2 = [color CIE_LabArray];
    CGFloat L1 = [lab1[0] floatValue];
    CGFloat A1 = [lab1[1] floatValue];
    CGFloat B1 = [lab1[2] floatValue];
    CGFloat L2 = [lab2[0] floatValue];
    CGFloat A2 = [lab2[1] floatValue];
    CGFloat B2 = [lab2[2] floatValue];
    
    // CIE76 first
    if (distanceType == ColorDistanceCIE76) {
        CGFloat distance = sqrtf(pow((L1-L2), 2) + pow((A1-A2), 2) + pow((B1-B2), 2));
        return distance;
    }
    
    // More Common Variables
    CGFloat kL = 1;
    CGFloat kC = 1;
    CGFloat kH = 1;
    CGFloat k1 = 0.045;
    CGFloat k2 = 0.015;
    CGFloat deltaL = L1 - L2;
    CGFloat C1 = sqrt((A1*A1) + (B1*B1));
    CGFloat C2 = sqrt((A2*A2) + (B2*B2));
    CGFloat deltaC = C1 - C2;
    CGFloat deltaH = sqrt(pow((A1-A2), 2.0) + pow((B1-B2), 2.0) - pow(deltaC, 2.0));
    CGFloat sL = 1;
    CGFloat sC = 1 + k1*(sqrt((A1*A1) + (B1*B1)));
    CGFloat sH = 1 + k2*(sqrt((A1*A1) + (B1*B1)));
    
    // CIE94
    if (distanceType == ColorDistanceCIE94) {
        return sqrt(pow((deltaL/(kL*sL)), 2.0) + pow((deltaC/(kC*sC)), 2.0) + pow((deltaH/(kH*sH)), 2.0));
    }
    
    // CIE2000
    // More variables
    CGFloat deltaLPrime = L2 - L1;
    CGFloat meanL = (L1 + L2)/2;
    CGFloat meanC = (C1 + C2)/2;
    CGFloat aPrime1 = A1 + A1/2*(1 - sqrt(pow(meanC, 7.0)/(pow(meanC, 7.0) + pow(25.0, 7.0))));
    CGFloat aPrime2 = A2 + A2/2*(1 - sqrt(pow(meanC, 7.0)/(pow(meanC, 7.0) + pow(25.0, 7.0))));
    CGFloat cPrime1 = sqrt((aPrime1*aPrime1) + (B1*B1));
    CGFloat cPrime2 = sqrt((aPrime2*aPrime2) + (B2*B2));
    CGFloat cMeanPrime = (cPrime1 + cPrime2)/2;
    CGFloat deltaCPrime = cPrime1 - cPrime2;
    CGFloat hPrime1 = atan2(B1, aPrime1);
    CGFloat hPrime2 = atan2(B2, aPrime2);
    hPrime1 = fmodf(hPrime1, RAD(360.0));
    hPrime2 = fmodf(hPrime2, RAD(360.0));
    CGFloat deltahPrime = 0;
    if (fabs(hPrime1 - hPrime2) <= RAD(180.0)) {
        deltahPrime = hPrime2 - hPrime1;
    }
    else {
        deltahPrime = (hPrime2 <= hPrime1) ? hPrime2 - hPrime1 + RAD(360.0) : hPrime2 - hPrime1 - RAD(360.0);
    }
    CGFloat deltaHPrime = 2 * sqrt(cPrime1*cPrime2) * sin(deltahPrime/2);
    CGFloat meanHPrime = (fabs(hPrime1 - hPrime2) <= RAD(180.0)) ? (hPrime1 + hPrime2)/2 : (hPrime1 + hPrime2 + RAD(360.0))/2;
    CGFloat T = 1 - 0.17*cos(meanHPrime - RAD(30.0)) + 0.24*cos(2*meanHPrime)+0.32*cos(3*meanHPrime + RAD(6.0)) - 0.20*cos(4*meanHPrime - RAD(63.0));
    sL = 1 + (0.015 * pow((meanL - 50), 2))/sqrt(20 + pow((meanL - 50), 2));
    sC = 1 + 0.045*cMeanPrime;
    sH = 1 + 0.015*cMeanPrime*T;
    CGFloat Rt = -2 * sqrt(pow(cMeanPrime, 7)/(pow(cMeanPrime, 7) + pow(25.0, 7))) * sin(RAD(60.0)* exp(-1 * pow((meanHPrime - RAD(275.0))/RAD(25.0), 2)));
    
    // Finally return CIE2000 distance
    return sqrt(pow((deltaLPrime/(kL*sL)), 2) + pow((deltaCPrime/(kC*sC)), 2) + pow((deltaHPrime/(kH*sH)), 2) + Rt*(deltaC/(kC*sC))*(deltaHPrime/(kH*sH)));
}


#pragma mark - Compare Colors
+ (NSArray *)sortColors:(NSArray *)colors withComparison:(ColorComparison)comparison {
    return [colors sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        return [self compareColor:obj1 andColor:obj2 withComparison:comparison];
    }];
}

+ (NSComparisonResult)compareColor:(id)colorA andColor:(id)colorB withComparison:(ColorComparison)comparison {
    if (![colorA isKindOfClass:[self class]] || ![colorB isKindOfClass:[self class]]) {
        return NSOrderedSame;
    }
    
    // Check Colors
    NSString *key = @"";
    boolean_t greater = true;
    NSDictionary *c1 = [colorA colorsForComparison:comparison key:&key greater:&greater];
    NSDictionary *c2 = [colorB colorsForComparison:comparison key:&key greater:&greater];
    return [self compareValue:[c1[key] floatValue] andValue:[c2[key] floatValue] greaterThan:greater];
}


#pragma mark - System Colors
+ (instancetype)infoBlueColor
{
	return [[self class] colorWithR:47 G:112 B:225 A:1.0];
}

+ (instancetype)successColor
{
	return [[self class] colorWithR:83 G:215 B:106 A:1.0];
}

+ (instancetype)warningColor
{
	return [[self class] colorWithR:221 G:170 B:59 A:1.0];
}

+ (instancetype)dangerColor
{
	return [[self class] colorWithR:229 G:0 B:15 A:1.0];
}

#pragma mark - Private

#pragma mark - RGBA Helper method
+ (instancetype)colorWithR:(CGFloat)red G:(CGFloat)green B:(CGFloat)blue A:(CGFloat)alpha
{
    return [[self class] colorWithRed:red/255.0f green:green/255.0f blue:blue/255.0f alpha:alpha];
}


#pragma mark - Degrees Helper method for Color Schemes
+ (float)addDegrees:(float)addDeg toDegree:(float)staticDeg
{
    staticDeg += addDeg;
    if (staticDeg > 360) {
        float offset = staticDeg - 360;
        return offset;
    }
    else if (staticDeg < 0) {
        return -1 * staticDeg;
    }
    else {
        return staticDeg;
    }
}


#pragma mark - Color Comparison
- (NSDictionary *)colorsForComparison:(ColorComparison)comparison key:(NSString **)key greater:(boolean_t *)greaterThan {
    switch (comparison) {
        case ColorComparisonRed:
            *key = kColoursRGBA_R;
            *greaterThan = true;
            return [self rgbaDictionary];
            
        case ColorComparisonGreen:
            *key = kColoursRGBA_G;
            *greaterThan = true;
            return [self rgbaDictionary];
            
        case ColorComparisonBlue:
            *key = kColoursRGBA_B;
            *greaterThan = true;
            return [self rgbaDictionary];
            
        case ColorComparisonDarkness:
            *key = kColoursHSBA_B;
            *greaterThan = false;
            return [self hsbaDictionary];
            
        case ColorComparisonLightness:
            *key = kColoursHSBA_B;
            *greaterThan = true;
            return [self hsbaDictionary];
            
        case ColorComparisonSaturated:
            *key = kColoursHSBA_S;
            *greaterThan = true;
            return [self hsbaDictionary];
            
        case ColorComparisonDesaturated:
            *key = kColoursHSBA_S;
            *greaterThan = false;
            return [self hsbaDictionary];
            
        default:
            *key = kColoursRGBA_R;
            *greaterThan = true;
            return [self rgbaDictionary];
    }
}

+ (NSComparisonResult)compareValue:(CGFloat)v1 andValue:(CGFloat)v2 greaterThan:(boolean_t)greaterThan {
    CGFloat comparison = v1 - v2;
    comparison = (greaterThan == true ? 1 : -1)*comparison;
    return (comparison == 0.0 ? NSOrderedSame : (comparison < 0.0 ? NSOrderedDescending : NSOrderedAscending));
}


#pragma mark - Swizzle


#pragma mark - On Load - Flip methods
+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class class = [self class];
        SEL rgbaSelector = @selector(getRed:green:blue:alpha:);
        SEL swizzledRGBASelector = @selector(colours_getRed:green:blue:alpha:);
        SEL hsbaSelector = @selector(getHue:saturation:brightness:alpha:);
        SEL swizzledHSBASelector = @selector(colours_getHue:saturation:brightness:alpha:);
        Method rgbaMethod = class_getInstanceMethod(class, rgbaSelector);
        Method swizzledRGBAMethod = class_getInstanceMethod(class, swizzledRGBASelector);
        Method hsbaMethod = class_getInstanceMethod(class, hsbaSelector);
        Method swizzledHSBAMethod = class_getInstanceMethod(class, swizzledHSBASelector);
        
        // Attempt adding the methods
        BOOL didAddRGBAMethod =
        class_addMethod(class,
                        rgbaSelector,
                        method_getImplementation(swizzledRGBAMethod),
                        method_getTypeEncoding(swizzledRGBAMethod));
        
        BOOL didAddHSBAMethod =
        class_addMethod(class,
                        hsbaSelector,
                        method_getImplementation(swizzledHSBAMethod),
                        method_getTypeEncoding(swizzledHSBAMethod));
        
        // Replace methods
        if (didAddRGBAMethod) {
            class_replaceMethod(class,
                                swizzledRGBASelector,
                                method_getImplementation(swizzledRGBAMethod),
                                method_getTypeEncoding(swizzledRGBAMethod));
        } else {
            method_exchangeImplementations(rgbaMethod, swizzledRGBAMethod);
        }
        
        if (didAddHSBAMethod) {
            class_replaceMethod(class,
                                swizzledHSBASelector,
                                method_getImplementation(swizzledHSBAMethod),
                                method_getTypeEncoding(swizzledHSBAMethod));
        } else {
            method_exchangeImplementations(hsbaMethod, swizzledHSBAMethod);
        }
    });
}


#pragma mark - Swizzled Methods
- (BOOL)colours_getRed:(CGFloat *)red green:(CGFloat *)green blue:(CGFloat *)blue alpha:(CGFloat *)alpha
{
    if (CGColorGetNumberOfComponents(self.CGColor) == 4) {
        return [self colours_getRed:red green:green blue:blue alpha:alpha];
    }
    else if (CGColorGetNumberOfComponents(self.CGColor) == 2) {
        CGFloat white;
        CGFloat m_alpha;
        [self getWhite:&white alpha:&m_alpha];
        *red = white * 1.0;
        *green = white * 1.0;
        *blue = white * 1.0;
        if (alpha) {
		    *alpha = m_alpha;
        }
        return YES;
    }
    
    return NO;
}


- (BOOL)colours_getHue:(CGFloat *)hue saturation:(CGFloat *)saturation brightness:(CGFloat *)brightness alpha:(CGFloat *)alpha
{
    if (CGColorGetNumberOfComponents(self.CGColor) == 4) {
        return [self colours_getHue:hue saturation:saturation brightness:brightness alpha:alpha];
    }
    else if (CGColorGetNumberOfComponents(self.CGColor) == 2) {
        CGFloat white = 0;
        CGFloat a = 0;
        [self getWhite:&white alpha:&a];
        *hue = 0;
        *saturation = 0;
        *brightness = white * 1.0;
        if (alpha) {
            *alpha = a * 1.0;
		}
        return YES;
    }
    
    return NO;
}


@end
