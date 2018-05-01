//
//  PooCodeView.h
//  Code
//
//  Created by crazypoo on 14-4-14.
//  Copyright (c) 2014年 crazypoo. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PooCodeView : UIView
@property (nonatomic, retain) NSArray *changeArray;
@property (nonatomic, retain) NSString *changeString;
@property (nonatomic, assign) NSUInteger numberOfCodes;
@property (nonatomic, assign) int numberOfLines;
@property (nonatomic, assign) NSTimeInterval changeTimes;

- (id)initWithFrame:(CGRect)frame NumberOfCode:(NSInteger )noc NumberOfLines:(int)nol ChangeTime:(NSTimeInterval)time;
- (id)initWithFrame:(CGRect)frame NumberOfCode:(NSInteger )noc NumberOfLines:(int)nol;
-(void)changeCode;
@end
