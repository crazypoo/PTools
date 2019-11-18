//
//  UITextView+KJLimitCounter.h
//  CategoryDemo
//
//  Created by 杨科军 on 2018/7/12.
//  Copyright © 2018年 杨科军. All rights reserved.
//
#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN

@interface UITextView (KJLimitCounter)
/** 限制字数*/
@property(nonatomic,assign)NSInteger kj_LimitCount;
/** lab的右边距(默认10)*/
@property(nonatomic,assign)CGFloat kj_LabMargin;
/** lab的高度(默认20)*/
@property(nonatomic,assign)CGFloat kj_LabHeight;
/** lab的文字大小(默认12)*/
@property(nonatomic,strong)UIFont *kj_LabFont;
/** 统计限制字数Label*/
@property(nonatomic,readonly)UILabel *kj_InputLimitLabel;
@end
NS_ASSUME_NONNULL_END
