//
//  MyScrollLabelView.h
//  WNMPro
//
//  Created by Zhu Shouyu on 5/30/13.
//  Copyright (c) 2013 朱守宇. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MyScrollLabelView : UIScrollView


@property (nonatomic, retain) UIColor *ZSYTextColor;
@property (nonatomic, retain) UIColor *ZSYBackgroundColor;
@property (nonatomic, retain) UIFont *ZSYFont;
@property (nonatomic, retain) NSString *ZSYText;
@property (nonatomic, assign) NSTextAlignment textAlignment;
@property (nonatomic, assign) BOOL isScroll;

@end
