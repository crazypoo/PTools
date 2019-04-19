//
//  MAThermometerBorder.m
//  MAThermometer-Demo
//
//  Created by Michael Azevedo on 16/06/2014.
//

#import "MAThermometerBorder.h"


static const CGFloat colorsLight [] = {
	1.0, 1.0, 1.0, 0.5,
	1.0, 1.0, 1.0, 0.0
};

static const CGFloat colorsReflect [] = {
	1.0, 1.0, 1.0, 1.0,
	1.0, 1.0, 1.0, 0.0
};

@interface MAThermometerBorder ()

@property (nonatomic, assign) CGFloat height;
@property (nonatomic, assign) CGFloat yOffset;


@property (nonatomic, assign) CGFloat lineWidth;

// Lower part of the thermometer
@property (nonatomic, assign) CGFloat lowerCircleRadius;
@property (nonatomic, assign) CGPoint lowerCircleCenter;
@property (nonatomic, assign) CGPoint lowerCircleFirst;
@property (nonatomic, assign) CGPoint lowerCircleMiddle;
@property (nonatomic, assign) CGPoint lowerCircleSecond;

// Upper part of the thermometer
@property (nonatomic, assign) CGFloat upperCircleRadius;
@property (nonatomic, assign) CGPoint upperCircleCenter;
@property (nonatomic, assign) CGPoint upperCircleFirst;
@property (nonatomic, assign) CGPoint upperCircleMiddle;
@property (nonatomic, assign) CGPoint upperCircleSecond;




@end


@implementation MAThermometerBorder

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [self customInit];
    }
    return self;
}

-(id)init
{
    self = [super init];
    if (self) {
        // Initialization code
        [self customInit];
    }
    return self;
    
}

-(id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        // Initialization code
        [self customInit];
    }
    return self;
}

-(void)customInit
{
    _yOffset                = 0;
    _darkTheme              = NO;
    _glassEffect            = NO;
    
    _height = CGRectGetHeight(self.bounds);
    
    CGFloat width = CGRectGetWidth(self.bounds);
    
    if (_height/width > 4) {
        _height = width* 4;
        _yOffset = (CGRectGetHeight(self.bounds) - _height)/2;
    }
    
    // We compute all the points in order to save some time on drawRect method
    
    _lineWidth              = _height/100.f;
    
    
    _lowerCircleRadius      = (_height -2*_lineWidth)/8;
    _lowerCircleCenter      = CGPointMake(CGRectGetMidX(self.bounds), _height - (_lowerCircleRadius + _lineWidth) + _yOffset);
    _lowerCircleFirst       = CGPointMake((_lowerCircleCenter.x - cos(M_PI_4) * _lowerCircleRadius),
                                          (_lowerCircleCenter.y - sin(M_PI_4) * _lowerCircleRadius));
    _lowerCircleMiddle      = CGPointMake(_lowerCircleCenter.x,
                                          _lowerCircleCenter.y + _lowerCircleRadius);
    _lowerCircleSecond      = CGPointMake((_lowerCircleCenter.x + cos(M_PI_4) * _lowerCircleRadius),
                                          (_lowerCircleCenter.y - sin(M_PI_4) * _lowerCircleRadius));
    
    
    _upperCircleRadius      = (_lowerCircleSecond.x - _lowerCircleFirst.x)/2;
    _upperCircleCenter      = CGPointMake(CGRectGetMidX(self.bounds), _lineWidth + _upperCircleRadius+ _yOffset);
    _upperCircleFirst       = CGPointMake(_lowerCircleFirst.x, _upperCircleCenter.y);
    _upperCircleMiddle      = CGPointMake(_upperCircleCenter.x,_upperCircleCenter.y - _upperCircleRadius);
    _upperCircleSecond      = CGPointMake(_lowerCircleSecond.x, _upperCircleCenter.y);
    

    self.backgroundColor = [UIColor clearColor];
}

#pragma mark - Custom setters

-(void)setDarkTheme:(BOOL)darkTheme
{
    _darkTheme = darkTheme;
    [self setNeedsDisplay];
}

-(void)setGlassEffect:(BOOL)glassEffect
{
    _glassEffect = glassEffect;
    [self setNeedsDisplay];
}


#pragma mark - Drawing methods

- (void)drawRect:(CGRect)rect
{
	//FIX: optimise and save some reusable stuff
    CGColorSpaceRef baseSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextClearRect(context, rect);
    
    if (_glassEffect)
    {
        CGGradientRef gradient = CGGradientCreateWithColorComponents(baseSpace, colorsLight, NULL, 2);
        
        CGContextMoveToPoint(context, _lowerCircleCenter.x, _lowerCircleCenter.y);
        CGContextAddArc(context, _lowerCircleCenter.x, _lowerCircleCenter.y, _lowerCircleRadius, -M_PI_4, -3* M_PI_4, 0);
        CGContextClosePath(context);
        CGContextSaveGState(context);
        CGContextClip(context);
        CGContextDrawRadialGradient(context, gradient, _lowerCircleCenter, _lowerCircleRadius, _lowerCircleCenter, _lowerCircleRadius - _upperCircleRadius, 0);
        CGContextRestoreGState(context);
        
        
        CGContextMoveToPoint(context, _lowerCircleFirst.x, _lowerCircleFirst.y);
        CGContextAddArc(context, _lowerCircleFirst.x, _lowerCircleFirst.y, _upperCircleRadius, 0, M_PI_4, 0);
        CGContextClosePath(context);
        CGContextSaveGState(context);
        CGContextClip(context);
        CGContextDrawRadialGradient(context, gradient, _lowerCircleFirst, 0, _lowerCircleFirst, _upperCircleRadius , 0);
        CGContextRestoreGState(context);
        
        
        CGContextMoveToPoint(context, _lowerCircleSecond.x, _lowerCircleSecond.y);
        CGContextAddArc(context, _lowerCircleSecond.x, _lowerCircleSecond.y, _upperCircleRadius, M_PI,3*M_PI_4, 1);
        CGContextClosePath(context);
        CGContextSaveGState(context);
        CGContextClip(context);
        CGContextDrawRadialGradient(context, gradient, _lowerCircleSecond, 0, _lowerCircleSecond, _upperCircleRadius , 0);
        CGContextRestoreGState(context);
        
        CGContextAddRect(context, CGRectMake(_upperCircleFirst.x, _upperCircleFirst.y, _upperCircleCenter.x - _upperCircleFirst.x, _lowerCircleFirst.y - _upperCircleFirst.y));
        CGContextClosePath(context);
        CGContextSaveGState(context);
        CGContextClip(context);
        CGContextDrawLinearGradient(context, gradient, _upperCircleFirst, CGPointMake(_upperCircleMiddle.x ,_upperCircleFirst.y), 0);
        CGContextRestoreGState(context);
        
        CGContextAddRect(context, CGRectMake(_upperCircleCenter.x, _upperCircleCenter.y, _upperCircleSecond.x - _upperCircleCenter.x, _lowerCircleSecond.y - _upperCircleSecond.y));
        CGContextClosePath(context);
        CGContextSaveGState(context);
        CGContextClip(context);
        CGContextDrawLinearGradient(context, gradient, _upperCircleSecond, CGPointMake(_upperCircleMiddle.x ,_upperCircleSecond.y), 0);
        CGContextRestoreGState(context);
        
        CGContextAddArc(context, _upperCircleCenter.x, _upperCircleCenter.y, _upperCircleRadius, 0, M_PI, 1);
        CGContextClosePath(context);
        CGContextSaveGState(context);
        CGContextClip(context);
        CGContextDrawRadialGradient(context, gradient, _upperCircleCenter, _upperCircleRadius, _upperCircleCenter, 0, 0);
        CGContextRestoreGState(context);
        
        (void)(CGGradientRelease(gradient)), gradient = NULL;
        
        gradient = CGGradientCreateWithColorComponents(baseSpace, colorsReflect, NULL, 2);
        
        CGPoint reflectionPoint = CGPointMake((_lowerCircleFirst.x + _lowerCircleCenter.x) /2,
                                              (_lowerCircleFirst.y + _lowerCircleCenter.y) /2);
        
        
        CGContextDrawRadialGradient(context, gradient, reflectionPoint, 0, reflectionPoint, _lineWidth *2, 0);
        
        
        
        
        (void)(CGGradientRelease(gradient)), gradient = NULL;
    }
    
    CGContextSetLineWidth(context, _lineWidth);
    
    if (_darkTheme)
        CGContextSetStrokeColorWithColor(context,[[UIColor blackColor] CGColor]);
    else
        CGContextSetStrokeColorWithColor(context,[[UIColor whiteColor] CGColor]);
    
    CGContextMoveToPoint(context, _lowerCircleFirst.x, _lowerCircleFirst.y);
    CGContextAddArcToPoint(context, _lowerCircleMiddle.x -2*_lowerCircleRadius, _lowerCircleMiddle.y,
                           _lowerCircleMiddle.x, _lowerCircleMiddle.y, _lowerCircleRadius);
    
    CGContextMoveToPoint(context, _lowerCircleSecond.x, _lowerCircleSecond.y);
    CGContextAddArcToPoint(context, _lowerCircleMiddle.x +2*_lowerCircleRadius, _lowerCircleMiddle.y,
                           _lowerCircleMiddle.x, _lowerCircleMiddle.y, _lowerCircleRadius);
    
    CGContextMoveToPoint(context, _lowerCircleFirst.x, _lowerCircleFirst.y+_lineWidth/2);
    CGContextAddLineToPoint(context, _upperCircleFirst.x, _upperCircleFirst.y);

    CGContextMoveToPoint(context, _lowerCircleSecond.x, _lowerCircleSecond.y+_lineWidth/2);
    CGContextAddLineToPoint(context, _upperCircleSecond.x, _upperCircleSecond.y);
    
    CGContextAddArcToPoint(context, _upperCircleSecond.x, _upperCircleMiddle.y,
                           _upperCircleMiddle.x, _upperCircleMiddle.y, _upperCircleRadius);
    
    CGContextMoveToPoint(context, _upperCircleFirst.x, _upperCircleFirst.y);
    
    CGContextAddArcToPoint(context, _upperCircleFirst.x, _upperCircleMiddle.y,
                           _upperCircleMiddle.x, _upperCircleMiddle.y, _upperCircleRadius);
    
    CGContextStrokePath(context);
    
    
    CGFloat diff = _upperCircleFirst.y - _lowerCircleFirst.y;
    
    
    for (NSInteger i = 0; i <4 ; ++i)
    {
        CGPoint origin = CGPointMake(_upperCircleSecond.x, _lowerCircleFirst.y + diff*i/4.f + diff/8.f);
        CGPoint dest = CGPointMake(origin.x - 0.6f * (_upperCircleSecond.x -_upperCircleFirst.x) , origin.y);
        
        
        CGContextMoveToPoint(context, origin.x, origin.y);
        CGContextAddLineToPoint(context, dest.x, dest.y);
        
        CGContextStrokePath(context);
    }
    
    (void)(CGColorSpaceRelease(baseSpace)), baseSpace = NULL;
    
    
}


@end
