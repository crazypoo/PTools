//
//  PTShowFunctionViewController.h
//  PooTools_Example
//
//  Created by 邓杰豪 on 2018/10/24.
//  Copyright © 2018年 crazypoo. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, ShowFunction) {
    ShowFunctionFile = 0,
    ShowFunctionCollectionAD,
    ShowFunctionStarRate,
    ShowFunctionSegmented,
    ShowFunctionTagLabel,
    ShowFunctionInputView,
    ShowFunctionViewCorner,
    ShowFunctionLabelThroughLine,
    ShowFunctionShowAlert,
    ShowFunctionPicker,
    ShowFunctionCountryCodeSelect,
    ShowFunctionCountryLoading,
    ShowFunctionAboutImage,
};

NS_ASSUME_NONNULL_BEGIN

@interface PTShowFunctionViewController : UIViewController
-(instancetype)initWithShowFunctionType:(ShowFunction)type;
@end

NS_ASSUME_NONNULL_END
