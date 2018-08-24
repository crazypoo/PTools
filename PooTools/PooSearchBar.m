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
        self.tintColor = [UIColor whiteColor];
    }
    return self;
}

-(void) layoutSubviews
{
    [super layoutSubviews];
    
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
        UIFont *searchFieldFont = self.searchPlaceholderFont ? self.searchPlaceholderFont : [UIFont fontWithName:@"HelveticaNeue-Light" size:16];
        NSString *placeholderStr = self.searchPlaceholder ? self.searchPlaceholder : @"请输入文字";
        UIColor *searchBarTextFieldBorderColorSelect = self.searchBarTextFieldBorderColor ? self.searchBarTextFieldBorderColor : kRandomColor;
        
        searchField.placeholder = placeholderStr;
        [searchField setBorderStyle:UITextBorderStyleRoundedRect];
        [searchField setBackgroundColor:self.searchTextFieldBackgroundColor ? self.searchTextFieldBackgroundColor :kRandomColor];
        searchField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:placeholderStr attributes:@{NSFontAttributeName: searchFieldFont,NSForegroundColorAttributeName:self.searchPlaceholderColor ? self.searchPlaceholderColor : kRandomColor}];
        [searchField setTextColor:self.searchTextColor ? self.searchTextColor :kRandomColor];
        [searchField setFont:searchFieldFont];
        searchField.layer.borderColor = searchBarTextFieldBorderColorSelect.CGColor;
        searchField.layer.borderWidth = self.searchBarTextFieldBorderWidth ? self.searchBarTextFieldBorderWidth : 0.5;
        searchField.layer.cornerRadius = self.searchBarTextFieldCornerRadius ? self.searchBarTextFieldCornerRadius : 5;

        UIImage *searchBarImageSelect = self.searchBarImage ? self.searchBarImage : [Utils createImageWithColor:kClearColor];
        
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

        [[[self.subviews objectAtIndex:0].subviews objectAtIndex:1] setTintColor:self.cursorColor ? self.cursorColor : [UIColor lightGrayColor]];
    }
    
    UIView *outView = [[UIView alloc] initWithFrame:self.bounds];
    [outView setBackgroundColor:self.searchBarOutViewColor ? self.searchBarOutViewColor : kRandomColor];
    [self insertSubview:outView atIndex:1];
    
}

@end
