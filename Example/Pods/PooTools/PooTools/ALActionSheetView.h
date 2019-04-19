//
//  ALActionSheetView.h
//  ALActionSheetView
//
//  Created by WangQi on 7/4/15.
//  Copyright (c) 2015 WangQi. All rights reserved.
//

#import <UIKit/UIKit.h>

#define kCancelBtnTag 99999
#define kCancelRealTag kCancelBtnTag - 100

@class ALActionSheetView;

typedef void (^ALActionSheetViewDidSelectButtonBlock)(ALActionSheetView *actionSheetView, NSInteger buttonIndex);

@interface ALActionSheetView : UIView

/*! @brief 初始化
 * @param title 标题(可以为空)
 * @param cancelButtonTitle (默认取消)
 * @param destructiveButtonTitle (特殊选择行,字体颜色为红色)
 * @param otherButtonTitles (其他选项,数组形式填入)
 * @param bfName 字体 (默认HelveticaNeue-Light)
 * @return block 按钮点击回调tag
 */
- (instancetype)initWithTitle:(NSString *)title
            cancelButtonTitle:(NSString *)cancelButtonTitle
       destructiveButtonTitle:(NSString *)destructiveButtonTitle
            otherButtonTitles:(NSArray *)otherButtonTitles
               buttonFontName:(NSString *)bfName
                      handler:(ALActionSheetViewDidSelectButtonBlock)block;

/*! @brief 展示
 */
- (void)show;

/*! @brief 单例初始化
 * @param title 标题(可以为空)
 * @param cancelButtonTitle (默认取消)
 * @param destructiveButtonTitle (特殊选择行,字体颜色为红色)
 * @param otherButtonTitles (其他选项,数组形式填入)
 * @param bfName 字体 (默认HelveticaNeue-Light)
 * @return block 按钮点击回调tag
 */
+ (ALActionSheetView *)showActionSheetWithTitle:(NSString *)title
                              cancelButtonTitle:(NSString *)cancelButtonTitle
                         destructiveButtonTitle:(NSString *)destructiveButtonTitle
                              otherButtonTitles:(NSArray *)otherButtonTitles
                                 buttonFontName:(NSString *)bfName
                                        handler:(ALActionSheetViewDidSelectButtonBlock)block;

/*! @brief 消失
 */
- (void)dismiss;

@end
