//
//  PTextField.m
//  CollTest
//
//  Created by crazypoo on 14/10/27.
//  Copyright (c) 2014年 crazypoo. All rights reserved.
//

#import "PTextField.h"

@implementation PTextField

-(id)initWithFrame:(CGRect)frame image:(UIImage *)image
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.textFieldHeadImageView = [[UIImageView alloc] initWithFrame:CGRectMake(5, 1, frame.size.height-1, frame.size.height-1)];
        self.textFieldHeadImageView.image = image;
        [self addSubview:self.textFieldHeadImageView];
        
        self.textColor = [UIColor whiteColor];
    }
    return self;
}
-(CGRect)placeholderRectForBounds:(CGRect)bounds
{
    return CGRectInset(bounds, self.textFieldHeadImageView.frame.size.height+10, 0);
}

-(CGRect)textRectForBounds:(CGRect)bounds
{
    return CGRectInset(bounds, self.textFieldHeadImageView.frame.size.height+10, 0);
}

-(CGRect)editingRectForBounds:(CGRect)bounds
{
    CGRect inset = CGRectMake(bounds.origin.x + self.textFieldHeadImageView.frame.size.height+10, bounds.origin.y, bounds.size.width - ((self.textFieldHeadImageView.frame.size.height+10)*2), bounds.size.height);
    return inset;
}

@end
