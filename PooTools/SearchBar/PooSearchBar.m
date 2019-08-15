//
//  PooSearchBar.m
//  OMCN
//
//  Created by 邓杰豪 on 15/8/10.
//  Copyright (c) 2015年 doudou. All rights reserved.
//

#import "PooSearchBar.h"

#import "PMacros.h"
#import "Utils.h"

@implementation PooSearchBar
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

-(void) layoutSubviews
{
    [super layoutSubviews];
    
    NSString *placeholderStr = self.searchPlaceholder ? self.searchPlaceholder : @"请输入文字";
    
    UIFont *searchFieldFont = self.searchPlaceholderFont ? self.searchPlaceholderFont : kDEFAULT_FONT(kDevLikeFont, 16);
    
    UIColor *searchBarTextFieldBorderColorSelect = self.searchBarTextFieldBorderColor ? self.searchBarTextFieldBorderColor : kRandomColor;
    UIImage *searchBarImageSelect = self.searchBarImage ? self.searchBarImage : [Utils createImageWithColor:kClearColor];
    UIColor *searchFieldCursorColor = self.cursorColor ? self.cursorColor : [UIColor lightGrayColor];
    UIColor *searchFieldPlaceHolderColor = self.searchPlaceholderColor ? self.searchPlaceholderColor : kRandomColor;
    UIColor *searchFieldColor = self.searchTextColor ? self.searchTextColor : kRandomColor;
    UIColor *searchBarOutSideViewColor = self.searchBarOutViewColor ? self.searchBarOutViewColor : kRandomColor;
    UIColor *searchTextFieldBackgroundColors = self.searchTextFieldBackgroundColor ? self.searchTextFieldBackgroundColor :kRandomColor;
    
    CGFloat searchBarFieldCornerRadius = self.searchBarTextFieldCornerRadius ? self.searchBarTextFieldCornerRadius : 5;
    CGFloat searchBarFieldBorderWidth = self.searchBarTextFieldBorderWidth ? self.searchBarTextFieldBorderWidth : 0.5;

//    if (@available(iOS 13.0, *))
//    {
//        [self.searchTextField setBackgroundColor:searchTextFieldBackgroundColors];
//        [self.searchTextField setTintColor:searchFieldCursorColor];
//        self.searchTextField.textColor = searchFieldColor;
//        self.searchTextField.font = searchFieldFont;
//        self.searchTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:placeholderStr attributes:@{NSFontAttributeName: searchFieldFont,NSForegroundColorAttributeName:searchFieldPlaceHolderColor}];
//        self.backgroundImage = [Utils createImageWithColor:searchBarOutSideViewColor];
//        [self setImage:searchBarImageSelect forSearchBarIcon:UISearchBarIconSearch state:UIControlStateNormal];
//        kViewBorderRadius(self.searchTextField, searchBarFieldCornerRadius, searchBarFieldBorderWidth, searchBarTextFieldBorderColorSelect);
//    }
//    else
//    {
        UITextField *searchField;
        NSArray *subviewArr = self.subviews;
        for(int i = 0; i < subviewArr.count ; i++)
        {
            UIView *viewSub = [subviewArr objectAtIndex:i];
            NSArray *arrSub = viewSub.subviews;
            for (int j = 0; j < arrSub.count ; j ++)
            {
                id tempId = [arrSub objectAtIndex:j];
                if([tempId isKindOfClass:[UITextField class]])
                {
                    searchField = (UITextField *)tempId;
                }
            }
        }

        if(searchField)
        {
            searchField.placeholder = placeholderStr;
            [searchField setBorderStyle:UITextBorderStyleRoundedRect];
            [searchField setBackgroundColor:searchTextFieldBackgroundColors];
            searchField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:placeholderStr attributes:@{NSFontAttributeName: searchFieldFont,NSForegroundColorAttributeName:searchFieldPlaceHolderColor}];
            [searchField setTextColor:searchFieldColor];
            [searchField setFont:searchFieldFont];
            searchField.layer.borderColor = searchBarTextFieldBorderColorSelect.CGColor;
            searchField.layer.borderWidth = searchBarFieldBorderWidth;
            searchField.layer.cornerRadius = searchBarFieldCornerRadius;


            if ([UIImagePNGRepresentation(searchBarImageSelect) isEqual:UIImagePNGRepresentation([Utils createImageWithColor:kClearColor])])
            {
                searchField.leftView = nil;
            }
            else
            {
                UIImageView *iView = [[UIImageView alloc] initWithImage:searchBarImageSelect];
                [iView setFrame:CGRectMake(0.0, 0.0, 16.0, 16.0)];
                searchField.leftView = iView;
            }

            [[[self.subviews objectAtIndex:0].subviews objectAtIndex:1] setTintColor:searchFieldCursorColor];
            UIView *outView = [[UIView alloc] initWithFrame:self.bounds];
            [outView setBackgroundColor:searchBarOutSideViewColor];
            [self insertSubview:outView atIndex:1];
        }
//    }
}

@end
