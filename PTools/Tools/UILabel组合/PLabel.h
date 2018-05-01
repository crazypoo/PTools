//
//  PLabel.h
//  adasdasdadadasdasdadadadad
//
//  Created by MYX on 2017/4/18.
//  Copyright © 2017年 邓杰豪. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum
{
    VerticalAlignmentTop = 0,
    VerticalAlignmentMiddle,
    VerticalAlignmentBottom,
} VerticalAlignment;

typedef enum
{
    StrikeThroughAlignmentTop = 0,
    StrikeThroughAlignmentMiddle,
    StrikeThroughAlignmentBottom,
} StrikeThroughAlignment;

@interface PLabel : UILabel

- (void)setVerticalAlignment:(VerticalAlignment)verticalAlignment strikeThroughAlignment:(StrikeThroughAlignment)strikeThroughAlignment setStrikeThroughEnabled:(BOOL)strikeThroughEnabled;
@property (nonatomic) VerticalAlignment verticalAlignment;
@property (nonatomic) StrikeThroughAlignment strikeThroughAlignment;
@property (assign, nonatomic) BOOL strikeThroughEnabled;
@property (strong, nonatomic) UIColor *strikeThroughColor;
@end
