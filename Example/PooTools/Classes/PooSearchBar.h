//
//  PooSearchBar.h
//  OMCN
//
//  Created by 邓杰豪 on 15/8/10.
//  Copyright (c) 2015年 doudou. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PooSearchBar : UISearchBar
@property (nonatomic, retain) NSString *searchPlaceholder;
@property (nonatomic, retain) UIFont *searchPlaceholderFont;
@property (nonatomic, retain) UIColor *searchPlaceholderColor;
@property (nonatomic, retain) UIColor *searchTextColor;
@property (nonatomic, retain) UIColor *searchTextFieldBackgroundColor;
@property (nonatomic, retain) UIImage *searchBarImage;
@property (nonatomic, retain) UIColor *searchBarOutViewColor;
@property (nonatomic, retain) UIColor *searchBarTextFieldBorderColor;
@property (nonatomic) float searchBarTextFieldBorderWidth;
@property (nonatomic) float searchBarTextFieldCornerRadius;
@end
