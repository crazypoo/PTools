//
//  PStarRateView.m
//  PTools
//
//  Created by MYX on 2017/4/19.
//  Copyright © 2017年 crazypoo. All rights reserved.
//

#import "PStarRateView.h"

#import "Utils.h"
#import <Masonry/Masonry.h>
#import "UIView+ModifyFrame.h"
#import "PMacros.h"

#define DEFALUT_STAR_NUMBER        5
#define ANIMATION_TIME_INTERVAL    0.2

#define BackgroundViewTags 4567
#define ForegroundViewTags 7654

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

- (instancetype)initWithRateBlock:(PStarRateViewRateBlock)block{
    return [self initWithNumberOfStars:DEFALUT_STAR_NUMBER imageForeground:[Utils createImageWithColor:[UIColor redColor]] imageBackGround:[Utils createImageWithColor:[UIColor blueColor]] withTap:YES rateBlock:block];
}

- (instancetype)initWithNumberOfStars:(NSInteger)numberOfStars imageForeground:(UIImage *)fStr imageBackGround:(UIImage *)bStr withTap:(BOOL)yesORno rateBlock:(PStarRateViewRateBlock)block
{
    if (self = [super init]) {
        self.rateBlock = block;
        self.numberOfStars = numberOfStars;
        [self buildUIWithImageStr:fStr backGround:bStr taped:yesORno];
    }
    return self;
}
#pragma mark - Private Methods

-(void)buildUIWithImageStr:(UIImage *)f backGround:(UIImage *)b taped:(BOOL)tapped
{
    self.scorePercent = 0.2;//默认为1
    self.hasAnimation = NO;//默认为NO
    self.allowIncompleteStar = NO;//默认为NO

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            self.backgroundStarView = [self createStarViewWithImage:b imageTag:BackgroundViewTags];
            self.foregroundStarView = [self createStarViewWithImage:f imageTag:ForegroundViewTags];
            [self addSubview:self.backgroundStarView];
            [self.backgroundStarView mas_makeConstraints:^(MASConstraintMaker *make) {
                make.left.right.top.bottom.equalTo(self);
            }];
            [self addSubview:self.foregroundStarView];
            [self.foregroundStarView mas_makeConstraints:^(MASConstraintMaker *make) {
                make.left.right.top.bottom.equalTo(self);
            }];
        
            if (tapped)
            {
                UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(userTapRateView:)];
                tapGesture.numberOfTapsRequired = 1;
                [self addGestureRecognizer:tapGesture];
            }
    });
}

- (void)userTapRateView:(UITapGestureRecognizer *)gesture
{
    CGPoint tapPoint = [gesture locationInView:self];
    CGFloat offset = tapPoint.x;
    CGFloat realStarScore = offset / (self.width / self.numberOfStars);
    CGFloat starScore = self.allowIncompleteStar ? realStarScore : ceilf(realStarScore);
    self.scorePercent = starScore / self.numberOfStars;
}

- (UIView *)createStarViewWithImage:(UIImage *)imageName imageTag:(NSInteger)viewTag
{
    UIView *view = [UIView new];
    view.clipsToBounds = YES;
    view.backgroundColor = [UIColor clearColor];
    for (NSInteger i = 0; i < self.numberOfStars; i ++)
    {
        UIImageView *imageView = [UIImageView new];
        imageView.image = imageName;
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        imageView.tag = viewTag+i;
        [view addSubview:imageView];
        [imageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(view).offset(i * self.width / self.numberOfStars);
            make.top.equalTo(view);
            make.width.offset(self.width / self.numberOfStars);
            make.height.equalTo(view);
        }];
    }
    return view;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    [self.backgroundStarView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.left.right.top.bottom.equalTo(self);
    }];
    [self.foregroundStarView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.left.right.top.bottom.equalTo(self);
    }];
    
    for (NSInteger i = 0; i < self.numberOfStars; i ++)
    {
        UIImageView *b = (UIImageView *)[self.backgroundStarView viewWithTag:BackgroundViewTags+i];
        [b mas_updateConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.backgroundStarView).offset(i * self.backgroundStarView.width / self.numberOfStars);
            make.top.equalTo(self.backgroundStarView);
            make.width.offset(self.backgroundStarView.width / self.numberOfStars);
            make.height.equalTo(self.backgroundStarView);
        }];
        
        UIImageView *f = (UIImageView *)[self.foregroundStarView viewWithTag:ForegroundViewTags+i];
        [f mas_updateConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.foregroundStarView).offset(i * self.foregroundStarView.width / self.numberOfStars);
            make.top.equalTo(self.foregroundStarView);
            make.width.offset(self.foregroundStarView.width / self.numberOfStars);
            make.height.equalTo(self.foregroundStarView);
        }];
    }

    kWeakSelf(self);
    CGFloat animationTimeInterval = self.hasAnimation ? ANIMATION_TIME_INTERVAL : 0;
    [UIView animateWithDuration:animationTimeInterval animations:^{
        weakself.foregroundStarView.frame = CGRectMake(0, 0, weakself.width * weakself.scorePercent, weakself.height);
    }];
}

#pragma mark - Get and Set Methods

- (void)setScorePercent:(CGFloat)scroePercent
{
    if (_scorePercent == scroePercent)
    {
        return;
    }
    
    if (scroePercent < 0)
    {
        _scorePercent = 0;
    }
    else if (scroePercent > 1)
    {
        _scorePercent = 1;
    }
    else
    {
        _scorePercent = scroePercent;
    }
    
    if (self.rateBlock)
    {
        self.rateBlock(self, scroePercent);
    }
    
    [self setNeedsLayout];
}

@end
