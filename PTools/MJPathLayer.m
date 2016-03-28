//
//  MJPathLayer.m
//  MJPasswordView
//
//  Created by tenric on 13-6-30.
//  Copyright (c) 2013年 tenric. All rights reserved.
//

#import "MJPathLayer.h"
#import "MJPasswordView.h"

#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]


@implementation MJPathLayer

- (void)drawInContext:(CGContextRef)ctx
{
    if(!self.passwordView.isTracking)
    {
        return;
    }
    
    NSArray* circleIds = self.passwordView.trackingIds;
    int circleId = [[circleIds objectAtIndex:0] intValue];
    CGPoint point = [self getPointWithId:circleId];
    CGContextSetLineWidth(ctx, kPathWidth);
    CGContextSetLineJoin(ctx, kCGLineJoinRound);
    //线颜色设置
    CGContextSetStrokeColorWithColor(ctx, UIColorFromRGB(0x02aeef).CGColor);
    CGContextBeginPath(ctx);
    
    CGContextMoveToPoint(ctx, point.x, point.y);
    
    for (int i = 1; i < [circleIds count]; i++)
    {
        circleId = [[circleIds objectAtIndex:i] intValue];
        point = [self getPointWithId:circleId];
        CGContextAddLineToPoint(ctx, point.x, point.y);
    }
    
    point = self.passwordView.previousTouchPoint;
    CGContextAddLineToPoint(ctx, point.x, point.y);
    CGContextDrawPath(ctx, kCGPathStroke);
}

- (CGPoint)getPointWithId:(int)circleId
{
    CGFloat x = kCircleLeftTopMargin+kCircleRadius+circleId%3*(kCircleRadius*2+kCircleBetweenMargin);
    CGFloat y = kCircleLeftTopMargin+kCircleRadius+circleId/3*(kCircleRadius*2+kCircleBetweenMargin);
    CGPoint point = CGPointMake(x, y);
    return point;
}
@end