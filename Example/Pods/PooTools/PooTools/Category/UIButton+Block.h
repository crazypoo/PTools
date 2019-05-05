//
//  UIButton+Block.h
//  OMCN
//
//  Created by 邓杰豪 on 16/6/8.
//  Copyright © 2016年 doudou. All rights reserved.
//

#import <UIKit/UIKit.h>
typedef void (^TouchedBlock)(UIButton *sender);

@interface UIButton (Block)
-(void)addActionHandler:(TouchedBlock)touchHandler;
+(instancetype)bs_creat;
-(void)bs_setTitle:(NSString *)titleStr;
-(void)bs_setTitleColor:(UIColor *)color;
-(void)bs_setNormalImage:(UIImage *)image;
-(void)bs_setSelectedImage:(UIImage *)image;
-(void)bs_setTextAlignment:(NSTextAlignment)textAlignment;
-(void)bs_setFont:(UIFont *)font;
@end

@interface UIButton (EX)//按钮图片上文字下
- (void)verticalImageAndTitle:(CGFloat)spacing;
@end
