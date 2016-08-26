//
//  Utils.m
//  login
//
//  Created by crazypoo on 14/7/10.
//  Copyright (c) 2014年 crazypoo. All rights reserved.
//

#import "Utils.h"

@implementation Utils

+ (UIImageView *)imageViewWithFrame:(CGRect)frame withImage:(UIImage *)image{
    
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:frame];
    imageView.image = image;
    return imageView;
}

+ (UILabel *)labelWithFrame:(CGRect)frame withTitle:(NSString *)title titleFontSize:(UIFont *)font textColor:(UIColor *)color backgroundColor:(UIColor *)bgColor alignment:(NSTextAlignment)textAlignment{
    
    UILabel *label = [[UILabel alloc] initWithFrame:frame];
    label.text = title;
    label.font = font;
    label.textColor = color;
    label.backgroundColor = bgColor;
    label.textAlignment = textAlignment;
    return label;
}

+(UIAlertView *)alertTitle:(NSString *)title message:(NSString *)msg delegate:(id)aDeleagte cancelBtn:(NSString *)cancelName otherBtnName:(NSString *)otherbuttonName{
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:msg delegate:aDeleagte cancelButtonTitle:cancelName otherButtonTitles:otherbuttonName, nil];
    [alert show];
    return alert;
}

+(UIButton *)createBtnWithType:(UIButtonType)btnType frame:(CGRect)btnFrame backgroundColor:(UIColor*)bgColor{
    UIButton *btn = [UIButton buttonWithType:btnType];
    btn.frame = btnFrame;
    [btn setBackgroundColor:bgColor];
    return btn;
}

+(BOOL)isValidateEmail:(NSString *)email {
    
    NSString *emailRegex = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    return [emailTest evaluateWithObject:email];
    
}

+(NSString *)chineseTransform:(NSString *)chinese
{
    NSMutableString *pinyin = [chinese mutableCopy];
    CFStringTransform((__bridge CFMutableStringRef)pinyin, NULL, kCFStringTransformMandarinLatin, NO);
    CFStringTransform((__bridge CFMutableStringRef)pinyin, NULL, kCFStringTransformStripCombiningMarks, NO);
    NSString *newStr = pinyin;
    newStr = [newStr stringByReplacingOccurrencesOfString:@" " withString:@""];
    return newStr.uppercaseString;
}

+(CGSize)sizeForString:(NSString *)string fontToSize:(float)fontToSize andHeigh:(float)heigh andWidth:(float)width
{
    NSDictionary *dic = @{NSFontAttributeName: [UIFont systemFontOfSize:fontToSize]};
    CGSize size = [string boundingRectWithSize:CGSizeMake(width, heigh) options:NSStringDrawingTruncatesLastVisibleLine | NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading attributes:dic context:nil].size;
    return size;
}
@end