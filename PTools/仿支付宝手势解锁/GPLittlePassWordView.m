//
//  GPLittlePassWordView.m
//  LittlePassWorld
//
//  Created by crazypoo on 14/7/8.
//  Copyright (c) 2014年 crazypoo. All rights reserved.
//

#import "GPLittlePassWordView.h"

@implementation GPLittlePassWordView

- (id)initWithFrame:(CGRect)frame str:(NSString *)strrrrrrr
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.strr = strrrrrrr;
        
        CGFloat width = 10.f;
        CGFloat height = 10.f;
        CGFloat space = 5.f;
        CGFloat startX = 13.f;
        CGFloat startY = 13.f;
        for (NSInteger index = 0; index < 9; index ++) {
            UILabel *tempLabel = [[UILabel alloc] initWithFrame:CGRectMake(startX + (width + space) * (index % 3), startY + (width + space) * (index / 3), width, height)];
            tempLabel.layer.borderWidth = 5;
            tempLabel.layer.cornerRadius = 4.0;
            tempLabel.layer.masksToBounds = YES;
            [self setValue:tempLabel forKey:[NSString stringWithFormat:@"label%ld",(long)index]];
            [self addSubview:tempLabel];
        }
        [self refreshSubViews];
    }
    return self;
}

- (void)refreshSubViews {
    for (NSInteger location = 0; location < self.strr.length; location ++) {
        NSString *tempString = [self.strr substringWithRange:NSMakeRange(location, 1)];
        UILabel *tempLabel = [self valueForKey:[NSString stringWithFormat:@"label%@", tempString]];
        tempLabel.layer.borderColor = [UIColor orangeColor].CGColor;
    }
}
@end
