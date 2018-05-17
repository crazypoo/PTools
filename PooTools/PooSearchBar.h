//
//  PooSearchBar.h
//  OMCN
//
//  Created by 邓杰豪 on 15/8/10.
//  Copyright (c) 2015年 doudou. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PooSearchBar : UISearchBar
@property (nonatomic, strong, nonnull) NSString *searchPlaceholder;
@property (nonatomic, strong, nonnull) UIFont *searchPlaceholderFont;
@property (nonatomic, strong, nonnull) UIColor *searchPlaceholderColor;
@property (nonatomic, strong) UIColor *searchTextColor;
@property (nonatomic, strong) UIColor *searchTextFieldBackgroundColor;
@property (nonatomic, strong) UIImage *searchBarImage;
@property (nonatomic, strong) UIColor *searchBarOutViewColor;
@property (nonatomic, strong) UIColor *searchBarTextFieldBorderColor;
@property (nonatomic, assign) float searchBarTextFieldBorderWidth;
@property (nonatomic, assign) float searchBarTextFieldCornerRadius;
@property (nonatomic, strong) UIColor *cursorColor;
@end
