//
//  CGADCollectionViewCell.m
//  CloudGateCustom
//
//  Created by mouth on 2018/5/15.
//  Copyright © 2018年 邓杰豪. All rights reserved.
//

#import "CGADCollectionViewCell.h"
#import "Masonry/Masonry.h"

@implementation CGADCollectionViewCell

-(instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self confingSubViews];
    }
    return self;
}

-(void)confingSubViews
{
    self.adImage = [UIImageView new];
    self.adImage.contentMode = UIViewContentModeScaleAspectFit;
    [self.contentView addSubview:self.adImage];
    [self.adImage mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.bottom.equalTo(self.contentView);
        make.left.equalTo(self.contentView).offset(20);
        make.right.equalTo(self.contentView).offset(-20);
    }];
    
    self.adTitle = [UILabel new];
    self.adTitle.textColor = [UIColor whiteColor];
    self.adTitle.textAlignment = NSTextAlignmentCenter;
    self.adTitle.backgroundColor = [UIColor colorWithRed:0.1f green:0.1f blue:0.1f alpha:0.3f];
    [self.contentView addSubview:self.adTitle];
    [self.adTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.offset(20);
        make.bottom.equalTo(self.contentView);
        make.left.right.equalTo(self.adImage);
    }];
}
@end
