//
//  CGLayout.h
//  CloudGateCustom
//
//  Created by 邓杰豪 on 12/5/18.
//  Copyright © 2018年 邓杰豪. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CGLayout : NSObject
/*! @brief UICollectionViewFlowLayout初始化(不带Cell长宽)
 */
+(UICollectionViewFlowLayout *)createLayoutNormalScrollDirection:(UICollectionViewScrollDirection)sd;

/*! @brief UICollectionViewFlowLayout初始化(带Cell长宽+普通间距设置)
 * @param w 每页的宽
 * @param h 每页的高
 * @param pY uiedge's up and bottom
 * @param pX uiedge's left and right
 * @param sd 滑动方向
 */
+(UICollectionViewFlowLayout *)createLayoutItemW:(CGFloat)w
                                           itemH:(CGFloat)h
                                        paddingY:(CGFloat)pY
                                        paddingX:(CGFloat)pX
                                 scrollDirection:(UICollectionViewScrollDirection)sd;

/*! @brief UICollectionViewFlowLayout初始化(带Cell长宽+UIEdgeInsets参数录入)
 * @param w 每页的宽
 * @param h 每页的高
 * @param inset uiedge
 * @param mls 最小line间隙
 * @param mis 最小Interitem间隙
 * @param sd 滑动方向
 */
+(UICollectionViewFlowLayout *)createLayoutItemW:(CGFloat)w
                                           itemH:(CGFloat)h
                                    sectionInset:(UIEdgeInsets)inset
                              minimumLineSpacing:(CGFloat)mls
                         minimumInteritemSpacing:(CGFloat)mis
                                 scrollDirection:(UICollectionViewScrollDirection)sd;
@end
