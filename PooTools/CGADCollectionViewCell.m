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
    [self.contentView addSubview:self.adImage];
    [self.adImage mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.bottom.equalTo(self.contentView);
        make.left.equalTo(self.contentView).offset(20);
        make.right.equalTo(self.contentView).offset(-20);
    }];
}
@end
