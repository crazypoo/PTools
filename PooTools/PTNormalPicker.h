//
//  PTNormalPicker.h
//  PooTools_Example
//
//  Created by 邓杰豪 on 2018/12/27.
//  Copyright © 2018年 crazypoo. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PTNormalPicker;
@class PTNormalPickerModel;

typedef void(^PickerReturnBlock) (PTNormalPicker *normalPicker,PTNormalPickerModel *pickerModel);

@interface PTNormalPickerModel : NSObject
@property (nonatomic, strong) NSIndexPath *pickerIndexPath;
@property (nonatomic, strong) NSString *pickerTitle;
@end

@interface PTNormalPicker : UIView
-(instancetype)initWithNormalPickerBackgroundColor:(UIColor *)pickerBGC withTapBarBGColor:(UIColor *)tabColor withTitleAndBtnTitleColor:(UIColor *)textColor withTitleFont:(UIFont *)titleFont withPickerData:(NSArray <PTNormalPickerModel *>*)dataArr;
@property (nonatomic, copy) PickerReturnBlock returnBlock;

@end
