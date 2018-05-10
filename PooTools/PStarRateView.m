//
//  PStarRateView.m
//  PTools
//
//  Created by MYX on 2017/4/19.
//  Copyright © 2017年 crazypoo. All rights reserved.
//

#import "PStarRateView.h"
#import "Utils.h"

#define DEFALUT_STAR_NUMBER        5
#define ANIMATION_TIME_INTERVAL    0.2

@interface PStarRateView ()

@property (nonatomic, strong) UIView *foregroundStarView;
@property (nonatomic, strong) UIView *backgroundStarView;

@property (nonatomic, assign) NSInteger numberOfStars;
@property (nonatomic, copy) PStarRateViewRateBlock rateBlock;

@end

@implementation PStarRateView

#pragma mark - Init Methods
- (instancetype)init {
    NSAssert(NO, @"You should never call this method in this class. Use initWithFrame: instead!");
    return nil;
}

- (instancetype)initWithFrame:(CGRect)frame rateBlock:(PStarRateViewRateBlock)block{
    return [self initWithFrame:frame numberOfStars:DEFALUT_STAR_NUMBER imageForeground:[Utils createImageWithColor:[UIColor redColor]] imageBackGround:[Utils createImageWithColor:[UIColor blueColor]] withTap:YES rateBlock:block];
}

- (instancetype)initWithFrame:(CGRect)frame numberOfStars:(NSInteger)numberOfStars imageForeground:(UIImage *)fStr imageBackGround:(UIImage *)bStr withTap:(BOOL)yesORno rateBlock:(PStarRateViewRateBlock)block
{
    if (self = [super initWithFrame:frame]) {
        self.rateBlock = block;
        _numberOfStars = numberOfStars;
        [self buildUIWithImageStr:fStr backGround:bStr taped:yesORno];
    }
    return self;
}
#pragma mark - Private Methods

-(void)buildUIWithImageStr:(UIImage *)f backGround:(UIImage *)b taped:(BOOL)tapped
{
    _scorePercent = 0.2;//默认为1
    _hasAnimation = NO;//默认为NO
    _allowIncompleteStar = NO;//默认为NO
    
    
    self.foregroundStarView = [self createStarViewWithImage:f];
    self.backgroundStarView = [self createStarViewWithImage:b];
    
    
    [self addSubview:self.backgroundStarView];
    [self addSubview:self.foregroundStarView];
    if (tapped) {
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(userTapRateView:)];
        tapGesture.numberOfTapsRequired = 1;
        [self addGestureRecognizer:tapGesture];
    }
    
}

- (void)userTapRateView:(UITapGestureRecognizer *)gesture {
    CGPoint tapPoint = [gesture locationInView:self];
    CGFloat offset = tapPoint.x;
    CGFloat realStarScore = offset / (self.bounds.size.width / self.numberOfStars);
    CGFloat starScore = self.allowIncompleteStar ? realStarScore : ceilf(realStarScore);
    self.scorePercent = starScore / self.numberOfStars;
}

- (UIView *)createStarViewWithImage:(UIImage *)imageName {
    UIView *view = [[UIView alloc] initWithFrame:self.bounds];
    view.clipsToBounds = YES;
    view.backgroundColor = [UIColor clearColor];
    for (NSInteger i = 0; i < self.numberOfStars; i ++)
    {
        UIImageView *imageView = [[UIImageView alloc] initWithImage:imageName];
        imageView.frame = CGRectMake(i * self.bounds.size.width / self.numberOfStars, 0, self.bounds.size.width / self.numberOfStars, self.bounds.size.height);
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        [view addSubview:imageView];
    }
    return view;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    __weak PStarRateView *weakSelf = self;
    CGFloat animationTimeInterval = self.hasAnimation ? ANIMATION_TIME_INTERVAL : 0;
    [UIView animateWithDuration:animationTimeInterval animations:^{
        weakSelf.foregroundStarView.frame = CGRectMake(0, 0, weakSelf.bounds.size.width * weakSelf.scorePercent, weakSelf.bounds.size.height);
    }];
}

#pragma mark - Get and Set Methods

- (void)setScorePercent:(CGFloat)scroePercent {
    if (_scorePercent == scroePercent) {
        return;
    }
    
    if (scroePercent < 0) {
        _scorePercent = 0;
    } else if (scroePercent > 1) {
        _scorePercent = 1;
    } else {
        _scorePercent = scroePercent;
    }
    
    if (self.rateBlock) {
        self.rateBlock(self, scroePercent);
    }
    
    [self setNeedsLayout];
}

@end
