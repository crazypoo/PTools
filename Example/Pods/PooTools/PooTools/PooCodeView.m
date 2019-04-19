//
//  PooCodeView.m
//  Code
//
//  Created by crazypoo on 14-4-14.
//  Copyright (c) 2014年 crazypoo. All rights reserved.
//

#import "PooCodeView.h"

@implementation PooCodeView
@synthesize changeArray = _changeArray;
@synthesize changeString = _changeString;
@synthesize numberOfCodes = _numberOfCodes;

- (id)initWithFrame:(CGRect)frame NumberOfCode:(NSInteger )noc NumberOfLines:(int)nol ChangeTime:(NSTimeInterval)time
{
    self = [super initWithFrame:frame];
    
    self.layer.cornerRadius = 5.0;
    self.layer.masksToBounds = YES;
    self.backgroundColor = [UIColor blueColor];

    if (self) {
        NSMutableArray *datasource = [NSMutableArray array];
        for (int index = 0; index < 10; index ++)
        {
            [datasource addObject:[NSString stringWithFormat:@"%d", index]];
        }
        for (char index = 'A'; index <= 'Z'; index ++)
        {
            [datasource addObject:[NSString stringWithFormat:@"%c", index]];
        }
        for (char index = 'a'; index <= 'z'; index ++)
        {
            [datasource addObject:[NSString stringWithFormat:@"%c", index]];
        }
        self.changeArray = [[NSArray alloc] initWithArray:datasource];
        self.numberOfCodes = noc;
        self.numberOfLines = nol;
        [self changeResultString];
    }
    self.changeTimes = time;
    [self performSelector:@selector(timeChange) withObject:nil afterDelay:self.changeTimes];

    return self;
}

- (id)initWithFrame:(CGRect)frame NumberOfCode:(NSInteger )noc NumberOfLines:(int)nol
{
    self = [super initWithFrame:frame];
    
    self.layer.cornerRadius = 5.0;
    self.layer.masksToBounds = YES;
    self.backgroundColor = [UIColor blueColor];
    
    if (self) {
        NSMutableArray *datasource = [NSMutableArray array];
        for (int index = 0; index < 10; index ++)
        {
            [datasource addObject:[NSString stringWithFormat:@"%d", index]];
        }
        for (char index = 'A'; index <= 'Z'; index ++)
        {
            [datasource addObject:[NSString stringWithFormat:@"%c", index]];
        }
        for (char index = 'a'; index <= 'z'; index ++)
        {
            [datasource addObject:[NSString stringWithFormat:@"%c", index]];
        }
        self.changeArray = [[NSArray alloc] initWithArray:datasource];
        self.numberOfCodes = noc;
        self.numberOfLines = nol;
        [self changeResultString];
    }
    return self;
}

- (void)timeChange
{
    [self performSelector:@selector(timeChange) withObject:nil afterDelay:self.changeTimes];
    [self changeResultString];
    [self setNeedsDisplay];
}

- (void)changeResultString
{
    NSMutableString *tempString = [NSMutableString string];
    for(NSInteger i = 0; i < self.numberOfCodes; i++)
    {
        NSInteger index = arc4random() % ([self.changeArray count] - 1);
        
        tempString = (NSMutableString *)[tempString stringByAppendingString:[self.changeArray objectAtIndex:index]];
    }
    self.changeString= [[NSString alloc] initWithFormat:@"%@", tempString];
}


- (void)setNumberOfCodes:(NSUInteger)numberOfCodes
{
    _numberOfCodes = numberOfCodes;
    [self changeResultString];
    [self setNeedsDisplay];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self changeResultString];
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    
        float red = arc4random() % 100 / 100.0;
        float green = arc4random() % 100 / 100.0;
        float blue = arc4random() % 100 / 100.0;
        UIColor *color = [UIColor colorWithRed:red green:green blue:blue alpha:1.0];
        [self setBackgroundColor:color];

        NSString *text = [NSString stringWithFormat:@"%@",self.changeString];
        CGSize cSize = [@"S" sizeWithAttributes:@{NSFontAttributeName: [UIFont systemFontOfSize:20]}];
        int width = rect.size.width / text.length - cSize.width;
        int height = rect.size.height - cSize.height;
        CGPoint point;
    
        float pX, pY;
        for (int i = 0; i < text.length; i++)
        {
            pX = arc4random() % width + rect.size.width / text.length * i;
            pY = arc4random() % height;
            point = CGPointMake(pX, pY);
            unichar c = [text characterAtIndex:i];
            NSString *textC = [NSString stringWithFormat:@"%C", c];
            [textC drawAtPoint:point withAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:20]}];
        }
    
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGContextSetLineWidth(context, 1.0);
        for(int cout = 0; cout < self.numberOfLines; cout++)
        {
            red = arc4random() % 100 / 100.0;
            green = arc4random() % 100 / 100.0;
            blue = arc4random() % 100 / 100.0;
            color = [UIColor colorWithRed:red green:green blue:blue alpha:1.0];
            CGContextSetStrokeColorWithColor(context, [color CGColor]);
            pX = arc4random() % (int)rect.size.width;
            pY = arc4random() % (int)rect.size.height;
            CGContextMoveToPoint(context, pX, pY);
            pX = arc4random() % (int)rect.size.width;
            pY = arc4random() % (int)rect.size.height;
            CGContextAddLineToPoint(context, pX, pY);
            CGContextStrokePath(context);
        }
}

-(void)changeCode
{
    [self changeResultString];
    [self setNeedsDisplay];
}
@end
