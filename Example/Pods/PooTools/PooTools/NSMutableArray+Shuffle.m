//
//  NSMutableArray+Shuffle.m
//  OMCN
//
//  Created by 邓杰豪 on 15/4/24.
//  Copyright (c) 2015年 doudou. All rights reserved.
//

#import "NSMutableArray+Shuffle.h"

@implementation NSMutableArray (Shuffle)

- (void)shuffle {
    for (NSInteger i = [self count] - 1; i > 0; --i) {
        NSInteger j = random() % i;
        [self exchangeObjectAtIndex:j withObjectAtIndex:i];
    }
}

-(NSMutableArray *)randomizedArray
{
    NSMutableArray *results = [NSMutableArray arrayWithArray:self];
    
    int i = (int)[results count];
    while(--i > 0) {
        int j = arc4random() % (i+1);
        [results exchangeObjectAtIndex:i withObjectAtIndex:j];
    }
    return results;
}

@end

