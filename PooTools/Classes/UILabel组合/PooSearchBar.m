//
//  PooSearchBar.m
//  OMCN
//
//  Created by 邓杰豪 on 15/8/10.
//  Copyright (c) 2015年 doudou. All rights reserved.
//

#import "PooSearchBar.h"

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
    for(int i = 0; i < subviewArr.count ; i++) {
        UIView *viewSub = [subviewArr objectAtIndex:i];
        NSArray *arrSub = viewSub.subviews;
        for (int j = 0; j < arrSub.count ; j ++) {
            id tempId = [arrSub objectAtIndex:j];
            if([tempId isKindOfClass:[UITextField class]]) {
                searchField = (UITextField *)tempId;
            }
        }
    }
    
    if(searchField) {
        searchField.placeholder = self.searchPlaceholder;
        [searchField setBorderStyle:UITextBorderStyleRoundedRect];
        [searchField setBackgroundColor:self.searchTextFieldBackgroundColor];
        searchField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:self.searchPlaceholder attributes:@{NSFontAttributeName: self.searchPlaceholderFont,NSForegroundColorAttributeName:self.searchPlaceholderColor}];
        [searchField setTextColor:self.searchTextColor];
        [searchField setFont:self.searchPlaceholderFont];
        searchField.layer.borderColor = self.searchBarTextFieldBorderColor.CGColor;
        searchField.layer.borderWidth = self.searchBarTextFieldBorderWidth;
        searchField.layer.cornerRadius = self.searchBarTextFieldCornerRadius;

        UIImageView *iView = [[UIImageView alloc] initWithImage:self.searchBarImage];
        [iView setFrame:CGRectMake(0.0, 0.0, 16.0, 16.0)];
        searchField.leftView = iView;
    }
    
    UIView *outView = [[UIView alloc] initWithFrame:self.bounds];
    [outView setBackgroundColor:self.searchBarOutViewColor];
    [self insertSubview:outView atIndex:1];
    
}

@end
