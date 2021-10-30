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

/*! @brief Picker初始化
 * @param pickerBGC 背景颜色
 * @param tabColor tabbar的背景颜色
 * @param textColor Bar字体颜色
 * @param ptColor picker字体颜色
 * @param titleFont picker字体
 * @param dataArr 数据
 * @param pT Bar标题
 * @param currentStr 当前所选
 */
-(instancetype)initWithNormalPickerBackgroundColor:(UIColor *)pickerBGC
                                 withTapBarBGColor:(UIColor *)tabColor
                         withTitleAndBtnTitleColor:(UIColor *)textColor
                              withPickerTitleColor:(UIColor *)ptColor
                                     withTitleFont:(UIFont *)titleFont
                                    withPickerData:(NSArray <PTNormalPickerModel *>*)dataArr
                                   withPickerTitle:(NSString *)pT
                             checkPickerCurrentRow:(NSString *)currentStr;
/*! @brief 显示Picker
 */
-(void)pickerShow;

@property (nonatomic, copy) PickerReturnBlock returnBlock;

@end
