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
#import <PooTools/PooTools-Swift.h>

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

#pragma mark - Color Components
//- (NSDictionary *)colorComponents
//{
//    NSMutableDictionary *components = [[self rgbaDictionary] mutableCopy];
//    [components addEntriesFromDictionary:[self hsbaDictionary]];
//    [components addEntriesFromDictionary:[self CIE_LabDictionary]];
//    return components;
//}

#pragma mark - Darken/Lighten
//- (instancetype)darken:(CGFloat)percentage {
//    return [self modifyBrightnessByPercentage:percentage];
//}
//
//- (instancetype)lighten:(CGFloat)percentage {
//    return [self modifyBrightnessByPercentage:percentage+1.0];
//}

//- (instancetype)modifyBrightnessByPercentage:(CGFloat)percentage {
//    NSMutableDictionary *hsba = [[self hsbaDictionary] mutableCopy];
//    [hsba setObject:@([hsba[kColoursHSBA_B] floatValue] * percentage) forKey:kColoursHSBA_B];
//    return [ColorClass colorFromHSBADictionary:hsba];
//}


#pragma mark - Generate Color Scheme
- (NSArray *)colorSchemeOfType:(ColorScheme)type
{
    float hue = self.hsbaColorHValue * 360;
    float sat = self.hsbaColorSValue * 100;
    float bright = self.hsbaColorBValue * 100;
    float alpha = self.hsbaColorAValue;
    
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
    double a = 1 - ((0.299 * self.colorRValue) + (0.587 * self.colorGValue) + (0.114 * self.colorBValue));
    return a < 0.5 ? [[self class] blackColor] : [[self class] whiteColor];
}


#pragma mark - Complementary Color
//- (instancetype)complementaryColor
//{
//    NSMutableDictionary *hsba = [[self hsbaDictionary] mutableCopy];
//    float newH = [[self class] addDegrees:180.0f toDegree:([hsba[kColoursHSBA_H] floatValue]*360.0f)];
//    [hsba setObject:@(newH/360.0f) forKey:kColoursHSBA_H];
//    return [[self class] colorFromHSBADictionary:hsba];
//}

#pragma mark - Compare Colors
//+ (NSArray *)sortColors:(NSArray *)colors withComparison:(ColorComparison)comparison {
//    return [colors sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
//        return [self compareColor:obj1 andColor:obj2 withComparison:comparison];
//    }];
//}

//+ (NSComparisonResult)compareColor:(id)colorA andColor:(id)colorB withComparison:(ColorComparison)comparison {
//    if (![colorA isKindOfClass:[self class]] || ![colorB isKindOfClass:[self class]]) {
//        return NSOrderedSame;
//    }
//
//    // Check Colors
//    NSString *key = @"";
//    boolean_t greater = true;
//    NSDictionary *c1 = [colorA colorsForComparison:comparison key:&key greater:&greater];
//    NSDictionary *c2 = [colorB colorsForComparison:comparison key:&key greater:&greater];
//    return [self compareValue:[c1[key] floatValue] andValue:[c2[key] floatValue] greaterThan:greater];
//}


#pragma mark - System Colors
+ (instancetype)infoBlueColor
{
	return [[self class] colorBaseWithR:47 G:112 B:225 A:1.0];
}

+ (instancetype)successColor
{
	return [[self class] colorBaseWithR:83 G:215 B:106 A:1.0];
}

+ (instancetype)warningColor
{
	return [[self class] colorBaseWithR:221 G:170 B:59 A:1.0];
}

+ (instancetype)dangerColor
{
	return [[self class] colorBaseWithR:229 G:0 B:15 A:1.0];
}

#pragma mark - Private

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
//- (NSDictionary *)colorsForComparison:(ColorComparison)comparison key:(NSString **)key greater:(boolean_t *)greaterThan {
//    switch (comparison) {
//        case ColorComparisonRed:
//            *key = kColoursRGBA_R;
//            *greaterThan = true;
//            return [self rgbaDictionary];
//
//        case ColorComparisonGreen:
//            *key = kColoursRGBA_G;
//            *greaterThan = true;
//            return [self rgbaDictionary];
//
//        case ColorComparisonBlue:
//            *key = kColoursRGBA_B;
//            *greaterThan = true;
//            return [self rgbaDictionary];
//
//        case ColorComparisonDarkness:
//            *key = kColoursHSBA_B;
//            *greaterThan = false;
//            return [self hsbaDictionary];
//
//        case ColorComparisonLightness:
//            *key = kColoursHSBA_B;
//            *greaterThan = true;
//            return [self hsbaDictionary];
//
//        case ColorComparisonSaturated:
//            *key = kColoursHSBA_S;
//            *greaterThan = true;
//            return [self hsbaDictionary];
//
//        case ColorComparisonDesaturated:
//            *key = kColoursHSBA_S;
//            *greaterThan = false;
//            return [self hsbaDictionary];
//
//        default:
//            *key = kColoursRGBA_R;
//            *greaterThan = true;
//            return [self rgbaDictionary];
//    }
//}

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
