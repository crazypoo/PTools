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

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdocumentation"
#include "TargetConditionals.h"
#include <Foundation/Foundation.h>

#pragma mark - Static String Keys
static NSString * kColoursRGBA_R = @"RGBA-r";
static NSString * kColoursRGBA_G = @"RGBA-g";
static NSString * kColoursRGBA_B = @"RGBA-b";
static NSString * kColoursRGBA_A = @"RGBA-a";
static NSString * kColoursHSBA_H = @"HSBA-h";
static NSString * kColoursHSBA_S = @"HSBA-s";
static NSString * kColoursHSBA_B = @"HSBA-b";
static NSString * kColoursHSBA_A = @"HSBA-a";
static NSString * kColoursCIE_L = @"LABa-L";
static NSString * kColoursCIE_A = @"LABa-A";
static NSString * kColoursCIE_B = @"LABa-B";
static NSString * kColoursCIE_alpha = @"LABa-a";
static NSString * kColoursCMYK_C = @"CMYK-c";
static NSString * kColoursCMYK_M = @"CMYK-m";
static NSString * kColoursCMYK_Y = @"CMYK-y";
static NSString * kColoursCMYK_K = @"CMYK-k";


#pragma mark - Create correct iOS/OSX interface

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
@interface UIColor (Colours)

#elif TARGET_OS_MAC
#import <AppKit/AppKit.h>
@interface NSColor (Colours)

#endif


#pragma mark - Enums
// Color Scheme Generation Enum
typedef NS_ENUM(NSInteger, ColorScheme) {
    ColorSchemeAnalagous,
    ColorSchemeMonochromatic,
    ColorSchemeTriad,
    ColorSchemeComplementary
};

typedef NS_ENUM(NSInteger, ColorComparison) {
    ColorComparisonDarkness,
    ColorComparisonLightness,
    ColorComparisonDesaturated,
    ColorComparisonSaturated,
    ColorComparisonRed,
    ColorComparisonGreen,
    ColorComparisonBlue
};

#pragma mark - Color Components
///**
// *  Creates an NSDictionary with RGBA and HSBA color components inside.
// *
// *  @return NSDictionary
// */
//- (NSDictionary *)colorComponents;

#pragma mark - Darken/Lighten
///**
// *  Darkens a color by changing the brightness by a percentage you pass in. If you want a 25% darker color, you pass in 0.25;
// *
// *  @param percentage CGFloat
// *
// *  @return Color
// */
//- (instancetype)darken:(CGFloat)percentage;
//
///**
// *  Lightens a color by changing the brightness by a percentage you pass in. If you want a 25% lighter color, you pass in 0.25;
// *
// *  @param percentage CGFloat
// *
// *  @return Color
// */
//- (instancetype)lighten:(CGFloat)percentage;


#pragma mark - 4 Color Scheme from Color
/**
 Creates an NSArray of 4 Colors that complement the Color.
 @param type ColorSchemeAnalagous, ColorSchemeMonochromatic, ColorSchemeTriad, ColorSchemeComplementary
 @return    NSArray
 */
- (NSArray *)colorSchemeOfType:(ColorScheme)type;


#pragma mark - Contrasting Color from Color
/**
 Creates either [Color whiteColor] or [Color blackColor] depending on if the color this method is run on is dark or light.
 @return    Color
 */
- (instancetype)blackOrWhiteContrastingColor;


#pragma mark - Complementary Color
///**
// Creates a complementary color - a color directly opposite it on the color wheel.
// @return    Color
// */
//- (instancetype)complementaryColor;


#pragma mark - Compare Colors
//+ (NSArray *)sortColors:(NSArray *)colors withComparison:(ColorComparison)comparison;
//+ (NSComparisonResult)compareColor:(id)colorA andColor:(id)colorB withComparison:(ColorComparison)comparison;


#pragma mark - Colors
// System Colors
+ (instancetype)infoBlueColor;
+ (instancetype)successColor;
+ (instancetype)warningColor;
+ (instancetype)dangerColor;

@end
#pragma clang diagnostic pop
