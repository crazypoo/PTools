//
//  PLabel.m
//  adasdasdadadasdasdadadadad
//
//  Created by MYX on 2017/4/18.
//  Copyright © 2017年 邓杰豪. All rights reserved.
//

#import "PLabel.h"

@implementation PLabel
@synthesize verticalAlignment = verticalAlignment_;
@synthesize strikeThroughAlignment = strikeThroughAlignment_;

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.verticalAlignment = VerticalAlignmentMiddle;
        self.strikeThroughAlignment = StrikeThroughAlignmentMiddle;
        self.strikeThroughEnabled = NO;
    }
    return self;
}

- (void)setVerticalAlignment:(VerticalAlignment)verticalAlignment strikeThroughAlignment:(StrikeThroughAlignment)strikeThroughAlignment setStrikeThroughEnabled:(BOOL)strikeThroughEnabled
{
    verticalAlignment_ = verticalAlignment;
    strikeThroughAlignment_ = strikeThroughAlignment;
    self.strikeThroughEnabled = strikeThroughEnabled;
    [self setNeedsDisplay];
}

- (CGRect)textRectForBounds:(CGRect)bounds limitedToNumberOfLines:(NSInteger)numberOfLines {
    CGRect textRect = [super textRectForBounds:bounds limitedToNumberOfLines:numberOfLines];
    switch (self.verticalAlignment) {
        case VerticalAlignmentTop:
            textRect.origin.y = bounds.origin.y;
            break;
        case VerticalAlignmentBottom:
            textRect.origin.y = bounds.origin.y + bounds.size.height - textRect.size.height;
            break;
        case VerticalAlignmentMiddle:
        default:
            textRect.origin.y = bounds.origin.y + (bounds.size.height - textRect.size.height) / 2.0;
    }
    
    if (self.strikeThroughEnabled)
    {
        CGFloat strikeWidth = textRect.size.width;
        CGRect lineRect;
        switch (self.strikeThroughAlignment) {
            case StrikeThroughAlignmentTop:
            {
                lineRect = CGRectMake(textRect.origin.x, textRect.origin.y, strikeWidth, 1);
            }
                break;
            case StrikeThroughAlignmentBottom:
            {
                lineRect = CGRectMake(textRect.origin.x, textRect.origin.y + textRect.size.height, strikeWidth, 1);
            }
                break;
            default:
            {
                lineRect = CGRectMake(textRect.origin.x, textRect.origin.y + textRect.size.height/2, strikeWidth, 1);
            }
                break;
        }
        
        CGContextRef context = UIGraphicsGetCurrentContext();
        
        CGContextSetFillColorWithColor(context, [self strikeThroughColor].CGColor);
        
        CGContextFillRect(context, lineRect);
    }
    return textRect;
}

-(void)drawTextInRect:(CGRect)requestedRect
{
    CGRect actualRect = [self textRectForBounds:requestedRect limitedToNumberOfLines:self.numberOfLines];
    [super drawTextInRect:actualRect];

}

@end
