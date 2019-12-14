//
//  CGLayout.m
//  CloudGateCustom
//
//  Created by 邓杰豪 on 12/5/18.
//  Copyright © 2018年 邓杰豪. All rights reserved.
//

#import "CGLayout.h"

@implementation CGLayout

+(UICollectionViewFlowLayout *)createLayoutItemSize:(CGSize)itemSize
                                           paddingY:(CGFloat)pY
                                           paddingX:(CGFloat)pX
                                    scrollDirection:(UICollectionViewScrollDirection)sd
{
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.itemSize                    = itemSize;
    layout.scrollDirection = sd;
    
    CGFloat paddingY                   = pY;
    CGFloat paddingX                   = pX;
    layout.sectionInset                = UIEdgeInsetsMake(paddingY, paddingX, paddingY, paddingX);
    layout.minimumLineSpacing          = paddingY;

    return layout;
}

+(UICollectionViewFlowLayout *)createLayoutItemSize:(CGSize)itemSize
                                       sectionInset:(UIEdgeInsets)inset
                                 minimumLineSpacing:(CGFloat)mls
                            minimumInteritemSpacing:(CGFloat)mis
                                    scrollDirection:(UICollectionViewScrollDirection)sd
{
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.itemSize                    = itemSize;
    layout.scrollDirection = sd;
    
    layout.sectionInset                = inset;
    layout.minimumLineSpacing          = mls;
    layout.minimumInteritemSpacing     = mis;
    
    return layout;
}

+(UICollectionViewFlowLayout *)createLayoutNormalScrollDirection:(UICollectionViewScrollDirection)sd
{
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.scrollDirection = sd;

    return layout;
}

@end
