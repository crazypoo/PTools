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

/*! @brief 验证码初始化
 * @param frame frame设置
 * @param noc 有多少个字符
 * @param nol 多少条线
 * @param time 刷新时间
 */
- (id)initWithFrame:(CGRect)frame
       NumberOfCode:(NSInteger )noc
      NumberOfLines:(int)nol
         ChangeTime:(NSTimeInterval)time;

/*! @brief 验证码初始化 (手动刷新)
 * @param frame frame设置
 * @param noc 有多少个字符
 * @param nol 多少条线
 */
- (id)initWithFrame:(CGRect)frame
       NumberOfCode:(NSInteger )noc
      NumberOfLines:(int)nol;

/*! @brief 刷新验证码
 */
-(void)changeCode;
@end
