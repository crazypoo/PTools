//
//  NSMutableArray+Shuffle.h
//  OMCN
//
//  Created by 邓杰豪 on 15/4/24.
//  Copyright (c) 2015年 doudou. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NSMutableArray (Shuffle)

/*! @brief 数组随机
 */
- (void)shuffle;

/*! @brief 数组随机(NSMutableArray)
 */
-(NSMutableArray *)randomizedArray;
@end

