//
//  PooSearchBar.h
//  OMCN
//
//  Created by 邓杰豪 on 15/8/10.
//  Copyright (c) 2015年 doudou. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PooSearchBar : UISearchBar
/*! @brief SearchBar未输入文字 (默认:请输入文字)
 */
@property (nonatomic, strong, nonnull) NSString *searchPlaceholder;

/*! @brief SearchBar未输入文字字体 (默认字体:HelveticaNeue-Light,字号:16)
 */
@property (nonatomic, strong, nonnull) UIFont *searchPlaceholderFont;

/*! @brief SearchBar未输入文字颜色 (默认随机)
 */
@property (nonatomic, strong, nonnull) UIColor *searchPlaceholderColor;

/*! @brief SearchBar输入文字颜色 (默认随机)
 */
@property (nonatomic, strong) UIColor *searchTextColor;

/*! @brief SearchBar输入框背景颜色 (默认随机)
 */
@property (nonatomic, strong) UIColor *searchTextFieldBackgroundColor;

/*! @brief SearchBar输入框左边小图标 (默认没图片)
 */
@property (nonatomic, strong) UIImage *searchBarImage;

/*! @brief SearchBar输入框外框颜色 (默认随机)
 */
@property (nonatomic, strong) UIColor *searchBarOutViewColor;

/*! @brief SearchBar输入框内框Border颜色 (默认随机)
 */
@property (nonatomic, strong) UIColor *searchBarTextFieldBorderColor;

/*! @brief SearchBar输入框内框Border宽度 (默认0.5)
 */
@property (nonatomic, assign) float searchBarTextFieldBorderWidth;

/*! @brief SearchBar输入框内框Border四角弧度 (默认5)
 */
@property (nonatomic, assign) float searchBarTextFieldCornerRadius;

/*! @brief SearchBar输入框光标颜色 (默认浅灰色)
 */
@property (nonatomic, strong) UIColor *cursorColor;
@end
