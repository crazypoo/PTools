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
 */
+(UICollectionViewFlowLayout *)createLayoutItemW:(CGFloat)w
                                           itemH:(CGFloat)h
                                        paddingY:(CGFloat)pY
                                        paddingX:(CGFloat)pX
                                 scrollDirection:(UICollectionViewScrollDirection)sd;

/*! @brief UICollectionViewFlowLayout初始化(带Cell长宽+UIEdgeInsets参数录入)
 */
+(UICollectionViewFlowLayout *)createLayoutItemW:(CGFloat)w
                                           itemH:(CGFloat)h
                                    sectionInset:(UIEdgeInsets)inset
                              minimumLineSpacing:(CGFloat)mls
                         minimumInteritemSpacing:(CGFloat)mis
                                 scrollDirection:(UICollectionViewScrollDirection)sd;
@end
