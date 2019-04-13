//
//  Utils.m
//  login
//
//  Created by crazypoo on 14/7/10.
//  Copyright (c) 2014年 crazypoo. All rights reserved.
//

#import "Utils.h"
#import "UIImage+UIColorEX.h"

#define HORIZONTAL_SPACE 30//水平间距
#define VERTICAL_SPACE 50//竖直间距
#define CG_TRANSFORM_ROTATION (M_PI_2 / 3)//旋转角度(正旋45度 || 反旋45度)

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

+(UIButton *)createBtnWithType:(UIButtonType)btnType frame:(CGRect)btnFrame backgroundColor:(UIColor*)bgColor{
    UIButton *btn = [UIButton buttonWithType:btnType];
    btn.frame = btnFrame;
    [btn setBackgroundColor:bgColor];
    return btn;
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

+(UIAlertView *)alertTitle:(NSString *)title message:(NSString *)msg delegate:(id)aDeleagte cancelBtn:(NSString *)cancelName otherBtnName:(NSString *)otherbuttonName{
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:msg delegate:aDeleagte cancelButtonTitle:cancelName otherButtonTitles:otherbuttonName, nil];
    [alert show];
    return alert;
}

+(UIAlertView *)alertShowWithMessage:(NSString *)message
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示" message:message delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
    [alert show];
    return alert;
}

+(void)alertVCWithTitle:(NSString *)title message:(NSString *)m cancelTitle:(NSString *)cT okTitle:(NSString *)okT shouIn:(UIViewController *)vC okAction:(void (^ _Nullable)(void))okBlock cancelAction:(void (^ _Nullable)(void))cancelBlock
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title
                                                                             message:m
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:okT style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        okBlock();
    }];
    [alertController addAction:okAction];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:cT style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        cancelBlock();
    }];
    [alertController addAction:cancelAction];
    [vC presentViewController:alertController animated:YES completion:^{
    }];
}

+(void)alertVCWithTitle:(NSString *)title message:(NSString *)m cancelTitle:(NSString *)cT shouIn:(UIViewController *)vC cancelAction:(void (^ _Nullable)(void))cancelBlock
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title
                                                                             message:m
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:cT style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        cancelBlock();
    }];
    [alertController addAction:cancelAction];
    [vC presentViewController:alertController animated:YES completion:^{
    }];
}

+(void)alertVCWithTitle:(NSString *)title message:(NSString *)m cancelTitle:(NSString *)cT okTitle:(NSString *)okT otherButtonArray:(NSArray *)titleArr shouIn:(UIViewController *)vC  alertStyle:(UIAlertControllerStyle)style okAction:(void (^ _Nullable)(void))okBlock cancelAction:(void (^ _Nullable)(void))cancelBlock otherButtonAction:(void (^) (NSInteger))buttonIndexPath
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title
                                                                             message:m
                                                                      preferredStyle:style];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:okT style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        okBlock();
    }];
    [alertController addAction:okAction];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:cT style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        cancelBlock();
    }];
    [alertController addAction:cancelAction];
    
    for (int i = 0; i < titleArr.count; i++) {
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:titleArr[i] style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            buttonIndexPath(i);
        }];
        [alertController addAction:cancelAction];
    }
    
    [vC presentViewController:alertController animated:YES completion:^{
    }];
}

+(void)timmerRunWithTime:(int)time button:(UIButton *)btn originalStr:(NSString *)str setTapEnable:(BOOL)yesOrNo
{
    __block int timeout = time;
    dispatch_queue_t queue   = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_source_t _timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0,queue);
    dispatch_source_set_timer(_timer,dispatch_walltime(NULL, 0),1.0*NSEC_PER_SEC, 0);
    dispatch_source_set_event_handler(_timer, ^{
        if(timeout <= 0){
            dispatch_source_cancel(_timer);
            dispatch_async(dispatch_get_main_queue(), ^{
                if (yesOrNo) {
                    btn.userInteractionEnabled = YES;
                    [btn setTitle:str forState:UIControlStateNormal];
                }
            });
        }
        else
        {
            NSString *strTime = [NSString stringWithFormat:@"%.2d",timeout];
            dispatch_async(dispatch_get_main_queue(), ^{
                NSString *buttonTime          = [NSString stringWithFormat:@"%@",strTime];
                [btn setTitle:buttonTime forState:UIControlStateNormal];
                btn.userInteractionEnabled = NO;
            });
            timeout--;
        }
    });
    dispatch_resume(_timer);
}

#pragma mark ------> 时间
+(NSString *)formateTime:(NSDate*)date WithType:(GetTimeType)type
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc]init];
    switch (type) {
        case GetTimeTypeYMD:
        {
            [formatter setDateFormat:@"YYYY-MM-dd"];
        }
            break;
        case GetTimeTypeYMDHHS:
        {
            [formatter setDateFormat:@"YYYY-MM-dd HH:mm:ss"];
        }
            break;
        case GetTimeTypeMD:
        {
            [formatter setDateFormat:@"MM-dd"];
        }
            break;
        case GetTimeTypeHHS:
        {
            [formatter setDateFormat:@"HH:mm:ss"];
        }
            break;
        case GetTimeTypeHH:
        {
            [formatter setDateFormat:@"HH:mm"];
        }
            break;
        default:
        {
            [formatter setDateFormat:@"HH:mm:ss"];
        }
            break;
    }
    NSTimeZone* timeZone = [NSTimeZone timeZoneWithName:@"Asia/Shanghai"];
    [formatter setTimeZone:timeZone];
    NSString *dateTime = [formatter stringFromDate:date];
    return dateTime;
}

+(NSString *)getTimeWithType:(GetTimeType)type
{
    NSDate *date = [NSDate date];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateStyle:NSDateFormatterMediumStyle];
    [formatter setTimeStyle:NSDateFormatterShortStyle];
    NSTimeZone* timeZone = [NSTimeZone timeZoneWithName:@"Asia/Shanghai"];
    
    switch (type) {
        case GetTimeTypeYMD:
        {
            [formatter setDateFormat:@"YYYY-MM-dd"];
            [formatter setTimeZone:timeZone];
            return [formatter stringFromDate:date];
        }
            break;
        case GetTimeTypeYMDHHS:
        {
            [formatter setDateFormat:@"YYYY-MM-dd HH:mm:ss"];
            [formatter setTimeZone:timeZone];
            return [formatter stringFromDate:date];
        }
            break;
        case GetTimeTypeTimeStamp:
        {
            return [NSString stringWithFormat:@"%ld", (long)[date timeIntervalSince1970]];
        }
            break;
        case GetTimeTypeMD:
        {
            [formatter setDateFormat:@"MM-dd"];
            [formatter setTimeZone:timeZone];
            return [formatter stringFromDate:date];
        }
            break;
        case GetTimeTypeHHS:
        {
            [formatter setDateFormat:@"HH:mm:ss"];
            [formatter setTimeZone:timeZone];
            return [formatter stringFromDate:date];
        }
            break;
        case GetTimeTypeHH:
        {
            [formatter setDateFormat:@"HH:mm"];
            [formatter setTimeZone:timeZone];
            return [formatter stringFromDate:date];
        }
            break;
        default:
        {
            return @"";
        }
            break;
    }
}

+(NSString *)dateStringFormater:(NSString *)timeString withType:(GetTimeType)type
{
    NSDateFormatter *formater = [[NSDateFormatter alloc] init];
    switch (type) {
        case GetTimeTypeYMD:
        {
            [formater setDateFormat:@"yyyy-MM-dd"];
            NSDate *create = [formater dateFromString:timeString];
            return [formater stringFromDate:create];
        }
            break;
        case GetTimeTypeYMDHHS:
        {
            [formater setDateFormat:@"YYYY-MM-dd HH:mm:ss"];
            NSDate *create = [formater dateFromString:timeString];
            return [formater stringFromDate:create];
        }
            break;
        case GetTimeTypeTimeStamp:
        {
            NSTimeInterval interval    =[timeString doubleValue] / 1000.0;
            NSDate *date = [NSDate dateWithTimeIntervalSince1970:interval];
            [formater setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
            return  [formater stringFromDate:date];
        }
            break;
        case GetTimeTypeMD:
        {
            [formater setDateFormat:@"MM-dd"];
            NSDate *create = [formater dateFromString:timeString];
            return [formater stringFromDate:create];
        }
            break;
        case GetTimeTypeHHS:
        {
            [formater setDateFormat:@"HH:mm:ss"];
            NSDate *create = [formater dateFromString:timeString];
            return [formater stringFromDate:create];
        }
            break;
        case GetTimeTypeHH:
        {
            [formater setDateFormat:@"HH:mm"];
            NSDate *create = [formater dateFromString:timeString];
            return [formater stringFromDate:create];
        }
            break;
        default:
        {
            return @"";
        }
            break;
    }
}

+(CheckNowTimeAndPastTimeRelationships)checkContractDateExpireContractDate:(NSString *)contractDate expTimeStamp:(int)timeStamp
{
    NSDateFormatter *formater = [[NSDateFormatter alloc] init];
    [formater setDateFormat:@"yyyy-MM-dd"];
    NSDate *create = [formater dateFromString:contractDate];
    NSDate *now = [NSDate date];
    NSTimeInterval timeDifference = [create timeIntervalSinceDate:now];
    float thirty = [[NSNumber numberWithInt: timeStamp] floatValue];
    if (timeDifference - thirty <= 0.000000)
    {
        return CheckNowTimeAndPastTimeRelationshipsExpire;
    }
    else
    {
        return CheckNowTimeAndPastTimeRelationshipsNormal;
    }
    return CheckNowTimeAndPastTimeRelationshipsError;
}

+(CheckNowTimeAndPastTimeRelationships)checkStartDateExpireEndDataWithStartDate:(NSString *)sD withEndDate:(NSString *)eD expTimeStamp:(int)timeStamp
{
    NSDateFormatter *formater = [[NSDateFormatter alloc] init];
    [formater setDateFormat:@"yyyy-MM-dd"];
    NSDate *startDate = [formater dateFromString:sD];
    NSDate *endDate = [formater dateFromString:eD];
    
    NSTimeInterval timeDifference = [endDate timeIntervalSinceDate:startDate];
    float thirty = [[NSNumber numberWithInt:timeStamp] floatValue];
    if (timeDifference - thirty <= 0.000000)
    {
        return CheckNowTimeAndPastTimeRelationshipsExpire;
    }
    else
    {
        return CheckNowTimeAndPastTimeRelationshipsNormal;
    }
    return CheckNowTimeAndPastTimeRelationshipsError;
}

#pragma mark ------> 获取地区
+(NSString *)getCurrentApplicationLocale
{
    NSLocale *locale = [NSLocale currentLocale];
    NSString *countryCode = [locale objectForKey: NSLocaleCountryCode];
    
    NSLocale *usLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    NSString *country = [usLocale displayNameForKey: NSLocaleCountryCode value: countryCode];
    return country;
}

+(NSString *)getCurrentDeviceLanguageInIOS
{
    NSString *language = [[[NSBundle mainBundle] preferredLocalizations] objectAtIndex:0];
    return language;
}

+(NSDictionary *)getCurrentDeviceLanguageInIOSWithDic
{
    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
    NSArray *arr = [NSLocale preferredLanguages];
    NSString *language = arr[0];
    [dic setObject:language forKey:LANGUAGEENGLISH];
    [dic setObject:[NSLocale canonicalLanguageIdentifierFromString:language] forKey:LANGUAGEANDCHINESE];
    [dic setObject:[[[NSLocale alloc] initWithLocaleIdentifier:language] displayNameForKey:NSLocaleIdentifier value:language] forKey:LANGUAGECHINESE];
    
    return dic;
}

+(UIImage*)createImageWithColor:(UIColor*)color
{
    CGRect rect = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    UIImage *theImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return theImage;
}

+(void)changeAPPIcon:(NSString *)IconName
{
    if (@available(iOS 10.3, *)) {
        if ([UIApplication sharedApplication].supportsAlternateIcons) {
            NSLog(@"you can change this app's icon");
        }else{
            [Utils alertShowWithMessage:@"你不能更换此APP的Icon"];
            return;
        }
        
        NSString *iconName = [[UIApplication sharedApplication] alternateIconName];
        
        if (iconName) {
            // change to primary icon
            [[UIApplication sharedApplication] setAlternateIconName:nil completionHandler:^(NSError * _Nullable error) {
                if (error) {
                    [Utils alertShowWithMessage:[NSString stringWithFormat:@"set icon error: %@",error]];
                }
                NSLog(@"The alternate icon's name is %@",iconName);
            }];
        }
        else
        {
            // change to alterante icon
            [[UIApplication sharedApplication] setAlternateIconName:IconName completionHandler:^(NSError * _Nullable error) {
                if (error) {
                    [Utils alertShowWithMessage:[NSString stringWithFormat:@"set icon error: %@",error]];
                }
                NSLog(@"The alternate icon's name is %@",iconName);
            }];
        }
    }
}

+(NSString *)stringToOtherLanguage:(NSString *)string otherLanguage:(NSStringTransform)language
{
    if (@available(iOS 9.0, *)) {
        return [string stringByApplyingTransform:language reverse:NO];
    }
    return @"只支持iOS9.0以上";
}

+(NSString *)backbankenameWithBanknumber:(NSString *)banknumber
{
    NSString *bankNumber = [banknumber stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSDictionary *dic;
    NSString *bank = @"";
    NSString *bank1 = @"";
    NSString *bank2 = @"";
    NSString *bankname;
    bank1 = [bankNumber substringToIndex:5];
    bank = [bankNumber substringToIndex:6];
    bank2 = [bankNumber substringToIndex:8];
    if (!dic) {
        dic = @{@"402791":@"工商银行",@"427028":@"工商银行",@"427038":@"工商银行",@"548259":@"工商银行",@"620200":@"工商银行",@"620302":@"工商银行",@"620402":@"工商银行",@"620403":@"工商银行",@"620404":@"工商银行",@"620405":@"工商银行",@"620406":@"工商银行",@"620407":@"工商银行",@"620408":@"工商银行",@"620409":@"工商银行",@"620410":@"工商银行",@"620411":@"工商银行",@"620412":@"工商银行",@"620502":@"工商银行",@"620503":@"工商银行",@"620512":@"工商银行",@"620602":@"工商银行",@"620604":@"工商银行",@"620607":@"工商银行",@"620609":@"工商银行",@"620611":@"工商银行",@"620612":@"工商银行",@"620704":@"工商银行",@"620706":@"工商银行",@"620707":@"工商银行",@"620708":@"工商银行",@"620709":@"工商银行",@"620710":@"工商银行",@"620711":@"工商银行",@"620712":@"工商银行",@"620713":@"工商银行",@"620714":@"工商银行",@"620802":@"工商银行",@"620904":@"工商银行",@"620905":@"工商银行",@"621101":@"工商银行",@"621102":@"工商银行",@"621103":@"工商银行",@"621105":@"工商银行",@"621106":@"工商银行",@"621107":@"工商银行",@"621202":@"工商银行",@"621203":@"工商银行",@"621204":@"工商银行",@"621205":@"工商银行",@"621206":@"工商银行",@"621207":@"工商银行",@"621208":@"工商银行",@"621209":@"工商银行",@"621210":@"工商银行",@"621211":@"工商银行",@"621302":@"工商银行",@"621303":@"工商银行",@"621304":@"工商银行",@"621305":@"工商银行",@"621306":@"工商银行",@"621307":@"工商银行",@"621308":@"工商银行",@"621309":@"工商银行",@"621311":@"工商银行",@"621313":@"工商银行",@"621315":@"工商银行",@"621317":@"工商银行",@"621402":@"工商银行",@"621404":@"工商银行",@"621405":@"工商银行",@"621406":@"工商银行",@"621407":@"工商银行",@"621408":@"工商银行",@"621409":@"工商银行",@"621410":@"工商银行",@"621502":@"工商银行",@"621511":@"工商银行",@"621602":@"工商银行",@"621603":@"工商银行",@"621604":@"工商银行",@"621605":@"工商银行",@"621606":@"工商银行",@"621607":@"工商银行",@"621608":@"工商银行",@"621609":@"工商银行",@"621610":@"工商银行",@"621611":@"工商银行",@"621612":@"工商银行",@"621613":@"工商银行",@"621614":@"工商银行",@"621615":@"工商银行",@"621616":@"工商银行",@"621617":@"工商银行",@"621804":@"工商银行",@"621807":@"工商银行",@"621813":@"工商银行",@"621814":@"工商银行",@"621817":@"工商银行",@"621901":@"工商银行",@"621903":@"工商银行",@"621904":@"工商银行",@"621905":@"工商银行",@"621906":@"工商银行",@"621907":@"工商银行",@"621908":@"工商银行",@"621909":@"工商银行",@"621910":@"工商银行",@"621911":@"工商银行",@"621912":@"工商银行",@"621913":@"工商银行",@"621914":@"工商银行",@"621915":@"工商银行",@"622002":@"工商银行",@"622003":@"工商银行",@"622004":@"工商银行",@"622005":@"工商银行",@"622006":@"工商银行",@"622007":@"工商银行",@"622008":@"工商银行",@"622009":@"工商银行",@"622010":@"工商银行",@"622011":@"工商银行",@"622012":@"工商银行",@"622013":@"工商银行",@"622014":@"工商银行",@"622015":@"工商银行",@"622016":@"工商银行",@"622017":@"工商银行",@"622018":@"工商银行",@"622019":@"工商银行",@"622020":@"工商银行",@"622102":@"工商银行",@"622103":@"工商银行",@"622104":@"工商银行",@"622105":@"工商银行",@"622110":@"工商银行",@"622111":@"工商银行",@"622114":@"工商银行",@"622302":@"工商银行",@"622303":@"工商银行",@"622304":@"工商银行",@"622305":@"工商银行",@"622306":@"工商银行",@"622307":@"工商银行",@"622308":@"工商银行",@"622309":@"工商银行",@"622313":@"工商银行",@"622314":@"工商银行",@"622315":@"工商银行",@"622317":@"工商银行",@"622402":@"工商银行",@"622403":@"工商银行",@"622404":@"工商银行",@"622502":@"工商银行",@"622504":@"工商银行",@"622505":@"工商银行",@"622509":@"工商银行",@"622510":@"工商银行",@"622513":@"工商银行",@"622517":@"工商银行",@"622604":@"工商银行",@"622605":@"工商银行",@"622606":@"工商银行",@"622703":@"工商银行",@"622706":@"工商银行",@"622715":@"工商银行",@"622806":@"工商银行",@"622902":@"工商银行",@"622903":@"工商银行",@"622904":@"工商银行",@"623002":@"工商银行",@"623006":@"工商银行",@"623008":@"工商银行",@"623011":@"工商银行",@"623012":@"工商银行",@"623014":@"工商银行",@"623015":@"工商银行",@"623100":@"工商银行",@"623202":@"工商银行",@"623301":@"工商银行",@"623400":@"工商银行",@"623500":@"工商银行",@"623602":@"工商银行",@"623700":@"工商银行",@"623803":@"工商银行",@"623901":@"工商银行",@"624000":@"工商银行",@"624100":@"工商银行",@"624200":@"工商银行",@"624301":@"工商银行",@"624402":@"工商银行",@"620058":@"工商银行",@"620516":@"工商银行",@"621225":@"工商银行",@"621226":@"工商银行",@"621227":@"工商银行",@"621281":@"工商银行",@"621288":@"工商银行",@"621721":@"工商银行",@"621722":@"工商银行",@"621723":@"工商银行",@"622200":@"工商银行",@"622202":@"工商银行",@"622203":@"工商银行",@"622208":@"工商银行",@"900000":@"工商银行",@"900010":@"工商银行",@"620086":@"工商银行",@"621558":@"工商银行",@"621559":@"工商银行",@"621618":@"工商银行",@"621670":@"工商银行",@"623062":@"工商银行",@"421349":@"建设银行",@"434061":@"建设银行",@"434062":@"建设银行",@"524094":@"建设银行",@"526410":@"建设银行",@"552245":@"建设银行",@"621080":@"建设银行",@"621082":@"建设银行",@"621466":@"建设银行",@"621488":@"建设银行",@"621499":@"建设银行",@"622966":@"建设银行",@"622988":@"建设银行",@"436742":@"建设银行",@"589970":@"建设银行",@"620060":@"建设银行",@"621081":@"建设银行",@"621284":@"建设银行",@"621467":@"建设银行",@"621598":@"建设银行",@"621621":@"建设银行",@"621700":@"建设银行",@"622280":@"建设银行",@"622700":@"建设银行",@"436742":@"建设银行",@"622280":@"建设银行",@"623211":@"建设银行",@"620059":@"农业银行",@"621282":@"农业银行",@"621336":@"农业银行",@"621619":@"农业银行",@"621671":@"农业银行",@"622821":@"农业银行",@"622822":@"农业银行",@"622823":@"农业银行",@"622824":@"农业银行",@"622825":@"农业银行",@"622826":@"农业银行",@"622827":@"农业银行",@"622828":@"农业银行",@"622840":@"农业银行",@"622841":@"农业银行",@"622843":@"农业银行",@"622844":@"农业银行",@"622845":@"农业银行",@"622846":@"农业银行",@"622847":@"农业银行",@"622848":@"农业银行",@"622849":@"农业银行",@"623018":@"农业银行",@"623206":@"农业银行",@"621626":@"平安银行",@"623058":@"平安银行",@"602907":@"平安银行",@"622298":@"平安银行",@"622986":@"平安银行",@"622989":@"平安银行",@"627066":@"平安银行",@"627067":@"平安银行",@"627068":@"平安银行",@"627069":@"平安银行",@"412962":@"发展银行",@"412963":@"发展银行",@"415752":@"发展银行",@"415753":@"发展银行",@"622535":@"发展银行",@"622536":@"发展银行",@"622538":@"发展银行",@"622539":@"发展银行",@"622983":@"发展银行",@"998800":@"发展银行",@"690755":@"招商银行",@"402658":@"招商银行",@"410062":@"招商银行",@"468203":@"招商银行",@"512425":@"招商银行",@"524011":@"招商银行",@"621286":@"招商银行",@"622580":@"招商银行",@"622588":@"招商银行",@"622598":@"招商银行",@"622609":@"招商银行",@"690755":@"招商银行",@"433670":@"中信银行",@"433671":@"中信银行",@"433680":@"中信银行",@"442729":@"中信银行",@"442730":@"中信银行",@"620082":@"中信银行",@"621767":@"中信银行",@"621768":@"中信银行",@"621770":@"中信银行",@"621771":@"中信银行",@"621772":@"中信银行",@"621773":@"中信银行",@"622690":@"中信银行",@"622691":@"中信银行",@"622692":@"中信银行",@"622696":@"中信银行",@"622698":@"中信银行",@"622998":@"中信银行",@"622999":@"中信银行",@"968807":@"中信银行",@"968808":@"中信银行",@"968809":@"中信银行",@"620085":@"广大银行",@"620518":@"广大银行",@"621489":@"广大银行",@"621492":@"广大银行",@"622660":@"广大银行",@"622661":@"广大银行",@"622662":@"广大银行",@"622663":@"广大银行",@"622664":@"广大银行",@"622665":@"广大银行",@"622666":@"广大银行",@"622667":@"广大银行",@"622668":@"广大银行",@"622669":@"广大银行",@"622670":@"广大银行",@"622671":@"广大银行",@"622672":@"广大银行",@"622673":@"广大银行",@"622674":@"广大银行",@"620535":@"广大银行",@"622516":@"浦发银行",@"622517":@"浦发银行",@"622518":@"浦发银行",@"622521":@"浦发银行",@"622522":@"浦发银行",@"622523":@"浦发银行",@"984301":@"浦发银行",@"984303":@"浦发银行",@"621352":@"浦发银行",@"621793":@"浦发银行",@"621795":@"浦发银行",@"621796":@"浦发银行",@"621351":@"浦发银行",@"621390":@"浦发银行",@"621792":@"浦发银行",@"621791":@"浦发银行",@"84301":@"浦发银行",@"84336":@"浦发银行",@"84373":@"浦发银行",@"84385":@"浦发银行",@"84390":@"浦发银行",@"87000":@"浦发银行",@"87010":@"浦发银行",@"87030":@"浦发银行",@"87040":@"浦发银行",@"84380":@"浦发银行",@"84361":@"浦发银行",@"87050":@"浦发银行",@"84342":@"浦发银行",@"415599":@"民生银行",@"421393":@"民生银行",@"421865":@"民生银行",@"427570":@"民生银行",@"427571":@"民生银行",@"472067":@"民生银行",@"472068":@"民生银行",@"622615":@"民生银行",@"622616":@"民生银行",@"622617":@"民生银行",@"622618":@"民生银行",@"622619":@"民生银行",@"622620":@"民生银行",@"622622":@"民生银行",@"601428":@"交通银行",@"405512":@"交通银行",@"622258":@"交通银行",@"622259":@"交通银行",@"622260":@"交通银行",@"622261":@"交通银行",@"622262":@"交通银行",@"621056":@"交通银行",@"621335":@"交通银行",@"621096":@"邮政储蓄银行",@"621098":@"邮政储蓄银行",@"622150":@"邮政储蓄银行",@"622151":@"邮政储蓄银行",@"622181":@"邮政储蓄银行",@"622188":@"邮政储蓄银行",@"955100":@"邮政储蓄银行",@"621095":@"邮政储蓄银行",@"620062":@"邮政储蓄银行",@"621285":@"邮政储蓄银行",@"621798":@"邮政储蓄银行",@"621799":@"邮政储蓄银行",@"621797":@"邮政储蓄银行",@"620529":@"邮政储蓄银行",@"622199":@"邮政储蓄银行",@"62215049":@"邮政储蓄银行",@"62215050":@"邮政储蓄银行",@"62215051":@"邮政储蓄银行",@"62218850":@"邮政储蓄银行",@"62218851":@"邮政储蓄银行",@"62218849":@"邮政储蓄银行",@"621622":@"邮政储蓄银行",@"621599":@"邮政储蓄银行",@"623219":@"邮政储蓄银行",@"621674":@"邮政储蓄银行",@"623218":@"邮政储蓄银行",@"621660":@"中国银行",@"621661":@"中国银行",@"621662":@"中国银行",@"621663":@"中国银行",@"621665":@"中国银行",@"621667":@"中国银行",@"621668":@"中国银行",@"621669":@"中国银行",@"621666":@"中国银行",@"456351":@"中国银行",@"601382":@"中国银行",@"621256":@"中国银行",@"621212":@"中国银行",@"621283":@"中国银行",@"620061":@"中国银行",@"621725":@"中国银行",@"621330":@"中国银行",@"621331":@"中国银行",@"621332":@"中国银行",@"621333":@"中国银行",@"621297":@"中国银行",@"621568":@"中国银行",@"621569":@"中国银行",@"621672":@"中国银行",@"623208":@"中国银行",@"621620":@"中国银行",@"621756":@"中国银行",@"621757":@"中国银行",@"621758":@"中国银行",@"621759":@"中国银行",@"621785":@"中国银行",@"621786":@"中国银行",@"621787":@"中国银行",@"621788":@"中国银行",@"621789":@"中国银行",@"621790":@"中国银行"};
    }
    
    for (NSString *s in [dic allKeys]) {
        if ([bank1 isEqualToString:s]||[bank isEqualToString:s]||[bank2 isEqualToString:s]) {
            bankname = dic[s];
            break ;
        }
    }
    
    return bankname;
}

+(NSString *)theDayBeforeToday:(NSString *)dayStr
{
    NSString *createdTimeStr = dayStr;
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSDate *timeDate = [dateFormatter dateFromString:createdTimeStr];
    NSTimeInterval timeInterval = [timeDate timeIntervalSinceNow];
    timeInterval = -timeInterval;
    long temp = 0;
    NSString *result;
    if (timeInterval < 60)
    {
        result = [NSString stringWithFormat:@"刚刚"];
    }
    else if((temp = timeInterval/60) < 60)
    {
        result = [NSString stringWithFormat:@"%ld分钟前",temp];
    }
    else if((temp = timeInterval/3600) > 1 && (temp = timeInterval/3600) <24)
    {
        result = [NSString stringWithFormat:@"%ld小时前",temp];
    }
    else if ((temp = timeInterval/3600) > 24 && (temp = timeInterval/3600) < 48)
    {
        result = [NSString stringWithFormat:@"昨天"];
    }
    else if ((temp = timeInterval/3600) > 48 && (temp = timeInterval/3600) < 72)
    {
        result = [NSString stringWithFormat:@"前天"];
    }
    else
    {
        result = createdTimeStr;
    }
    return result;
}

#pragma mark ------> Image
+(UIImage *)thumbnailImageForVideo:(NSURL *)videoURL atTime:(NSTimeInterval)time
{
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:videoURL options:nil];
    NSParameterAssert(asset);
    AVAssetImageGenerator *assetImageGenerator =[[AVAssetImageGenerator alloc] initWithAsset:asset];
    assetImageGenerator.appliesPreferredTrackTransform = YES;
    assetImageGenerator.apertureMode = AVAssetImageGeneratorApertureModeEncodedPixels;
    
    CGImageRef thumbnailImageRef = NULL;
    CFTimeInterval thumbnailImageTime = time;
    NSError *thumbnailImageGenerationError = nil;
    thumbnailImageRef = [assetImageGenerator copyCGImageAtTime:CMTimeMake(thumbnailImageTime, 60)actualTime:NULL error:&thumbnailImageGenerationError];
    
    if(!thumbnailImageRef)
        NSLog(@"thumbnailImageGenerationError %@",thumbnailImageGenerationError);
    
    UIImage *thumbnailImage = thumbnailImageRef ? [[UIImage alloc]initWithCGImage: thumbnailImageRef] : nil;
    
    return thumbnailImage;
}

+ (ToolsAboutImageType)contentTypeForImageData:(NSData *)data
{
    uint8_t c;
    
    [data getBytes:&c length:1];
    
    switch (c) {
            
        case 0xFF:
        {
            return ToolsAboutImageTypeJPEG;
        }
        case 0x89:
        {
            return ToolsAboutImageTypePNG;
        }
        case 0x47:
        {
            return ToolsAboutImageTypeGIF;
        }
        case 0x49:
        case 0x4D:
        {
            return ToolsAboutImageTypeTIFF;
        }
        case 0x52:
        {
            if ([data length] < 12) {
                return ToolsAboutImageTypeUNKNOW;
            }
            
            NSString *testString = [[NSString alloc] initWithData:[data subdataWithRange:NSMakeRange(0, 12)] encoding:NSASCIIStringEncoding];
            
            if ([testString hasPrefix:@"RIFF"] && [testString hasSuffix:@"WEBP"])
            {
                return ToolsAboutImageTypeWEBP;
            }
            return ToolsAboutImageTypeUNKNOW;
        }
    }
    return ToolsAboutImageTypeUNKNOW;
}

+ (ToolsUrlStringVideoType)contentTypeForUrlString:(NSString *)urlString
{
    NSString* pathExtention = [urlString pathExtension];
    if([pathExtention isEqualToString:@"mp4"] || [pathExtention isEqualToString:@"MP4"])
    {
        return ToolsUrlStringVideoTypeMP4;
    }
    else if([pathExtention isEqualToString:@"mov"] || [pathExtention isEqualToString:@"MOV"])
    {
        return ToolsUrlStringVideoTypeMOV;
    }
    else if([pathExtention isEqualToString:@"3gp"] || [pathExtention isEqualToString:@"3GP"])
    {
        return ToolsUrlStringVideoType3GP;
    }
    return ToolsUrlStringVideoTypeUNKNOW;
}

+(UIImage *)scaleImage:(UIImage *)image toScale:(float)scaleSize
{
    UIGraphicsBeginImageContext(CGSizeMake(image.size.width * scaleSize, image.size.height * scaleSize));
    [image drawInRect:CGRectMake(0, 0, image.size.width * scaleSize, image.size.height * scaleSize)];
    UIImage *scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return scaledImage;
}

+ (UIImage *)jx_WaterImageWithImage:(UIImage *)image text:(NSString *)text textPoint:(CGPoint)point attributedString:(NSDictionary * )attributed{
    //1.开启上下文
    UIGraphicsBeginImageContextWithOptions(image.size, NO, 0);
    //2.绘制图片
    [image drawInRect:CGRectMake(0, 0, image.size.width, image.size.height)];
    //添加水印文字
    [text drawAtPoint:point withAttributes:attributed];
    //3.从上下文中获取新图片
    UIImage * newImage = UIGraphicsGetImageFromCurrentImageContext();
    //4.关闭图形上下文
    UIGraphicsEndImageContext();
    //返回图片
    return newImage;
}

+ (UIImage *)jx_WaterImageWithImage:(UIImage *)image waterImage:(UIImage *)waterImage waterImageRect:(CGRect)rect{
    
    //1.获取图片
    
    //2.开启上下文
    UIGraphicsBeginImageContextWithOptions(image.size, NO, 0);
    //3.绘制背景图片
    [image drawInRect:CGRectMake(0, 0, image.size.width, image.size.height)];
    //绘制水印图片到当前上下文
    [waterImage drawInRect:rect];
    //4.从上下文中获取新图片
    UIImage * newImage = UIGraphicsGetImageFromCurrentImageContext();
    //5.关闭图形上下文
    UIGraphicsEndImageContext();
    //返回图片
    return newImage;
}

+ (UIImage *)getWaterMarkImage:(UIImage *)originalImage andTitle:(NSString *)title andMarkFont:(UIFont *)markFont andMarkColor:(UIColor *)markColor{
    
    UIFont *font = markFont;
    if (font == nil) {
        font = [UIFont systemFontOfSize:23];
    }
    UIColor *color = markColor;
    if (color == nil) {
        color = [originalImage imageMostColor];
    }
    //原始image的宽高
    CGFloat viewWidth = originalImage.size.width;
    CGFloat viewHeight = originalImage.size.height;
    //为了防止图片失真，绘制区域宽高和原始图片宽高一样
    UIGraphicsBeginImageContext(CGSizeMake(viewWidth, viewHeight));
    //先将原始image绘制上
    [originalImage drawInRect:CGRectMake(0, 0, viewWidth, viewHeight)];
    //sqrtLength：原始image的对角线length。在水印旋转矩阵中只要矩阵的宽高是原始image的对角线长度，无论旋转多少度都不会有空白。
    CGFloat sqrtLength = sqrt(viewWidth*viewWidth + viewHeight*viewHeight);
    //文字的属性
    NSDictionary *attr = @{
                           //设置字体大小
                           NSFontAttributeName: font,
                           //设置文字颜色
                           NSForegroundColorAttributeName :color,
                           };
    NSString* mark = title;
    NSMutableAttributedString *attrStr = [[NSMutableAttributedString alloc] initWithString:mark attributes:attr];
    //绘制文字的宽高
    CGFloat strWidth = attrStr.size.width;
    CGFloat strHeight = attrStr.size.height;
    
    //开始旋转上下文矩阵，绘制水印文字
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    //将绘制原点（0，0）调整到源image的中心
    CGContextConcatCTM(context, CGAffineTransformMakeTranslation(viewWidth/2, viewHeight/2));
    //以绘制原点为中心旋转
    CGContextConcatCTM(context, CGAffineTransformMakeRotation(CG_TRANSFORM_ROTATION));
    //将绘制原点恢复初始值，保证当前context中心和源image的中心处在一个点(当前context已经旋转，所以绘制出的任何layer都是倾斜的)
    CGContextConcatCTM(context, CGAffineTransformMakeTranslation(-viewWidth/2, -viewHeight/2));
    
    //计算需要绘制的列数和行数
    int horCount = sqrtLength / (strWidth + HORIZONTAL_SPACE) + 1;
    int verCount = sqrtLength / (strHeight + VERTICAL_SPACE) + 1;
    
    //此处计算出需要绘制水印文字的起始点，由于水印区域要大于图片区域所以起点在原有基础上移
    CGFloat orignX = -(sqrtLength-viewWidth)/2;
    CGFloat orignY = -(sqrtLength-viewHeight)/2;
    
    //在每列绘制时X坐标叠加
    CGFloat tempOrignX = orignX;
    //在每行绘制时Y坐标叠加
    CGFloat tempOrignY = orignY;
    for (int i = 0; i < horCount * verCount; i++) {
        [mark drawInRect:CGRectMake(tempOrignX, tempOrignY, strWidth, strHeight) withAttributes:attr];
        if (i % horCount == 0 && i != 0) {
            tempOrignX = orignX;
            tempOrignY += (strHeight + VERTICAL_SPACE);
        }else{
            tempOrignX += (strWidth + HORIZONTAL_SPACE);
        }
    }
    //根据上下文制作成图片
    UIImage *finalImg = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    CGContextRestoreGState(context);
    return finalImg;
}

#pragma mark ------> JSON
+ (NSDictionary *)dictionaryWithJsonString:(NSString *)jsonString
{
    if (jsonString == nil) {
        return nil;
    }
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSError *err;
    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:jsonData
                                                        options:NSJSONReadingMutableContainers
                                                          error:&err];
    if(err)
    {
        NSLog(@"json解析失败：%@",err);
        return nil;
    }
    return dic;
}

+ (NSArray *)stringToJSON:(NSString *)jsonStr
{
    if (jsonStr) {
        id tmp = [NSJSONSerialization JSONObjectWithData:[jsonStr dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingAllowFragments | NSJSONReadingMutableLeaves | NSJSONReadingMutableContainers error:nil];
        
        if (tmp) {
            if ([tmp isKindOfClass:[NSArray class]]) {
                
                return tmp;
                
            } else if([tmp isKindOfClass:[NSString class]]
                      || [tmp isKindOfClass:[NSDictionary class]]) {
                
                return [NSArray arrayWithObject:tmp];
                
            } else {
                return nil;
            }
        } else {
            return nil;
        }
        
    } else {
        return nil;
    }
}

+(NSString *)convertToJsonData:(NSDictionary *)dictData
{
    NSError *error = nil;
    NSData *jsonData = nil;
    if (!self) {
        return nil;
    }
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dictData enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        NSString *keyString = nil;
        NSString *valueString = nil;
        if ([key isKindOfClass:[NSString class]]) {
            keyString = key;
        }else{
            keyString = [NSString stringWithFormat:@"%@",key];
        }
        
        if ([obj isKindOfClass:[NSString class]]) {
            valueString = obj;
        }else{
            valueString = [NSString stringWithFormat:@"%@",obj];
        }
        
        [dict setObject:valueString forKey:keyString];
    }];
    jsonData = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:&error];
    if ([jsonData length] == 0 || error != nil) {
        return nil;
    }
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    NSMutableString *mutStr = [NSMutableString stringWithString:jsonString];
    NSRange range = {0,jsonString.length};
    //去掉字符串中的空格
    [mutStr replaceOccurrencesOfString:@" " withString:@"" options:NSLiteralSearch range:range];
    NSRange range2 = {0,mutStr.length};
    //去掉字符串中的换行符
    [mutStr replaceOccurrencesOfString:@"\n" withString:@"" options:NSLiteralSearch range:range2];
    return mutStr;
}

+ (NSString *)changeJsonStringToTrueJsonString:(NSString *)json
{
    // 将没有双引号的替换成有双引号的
    NSString *validString = [json stringByReplacingOccurrencesOfString:@"(\\w+)\\s*:([^A-Za-z0-9_])"
                                                            withString:@"\"$1\":$2"
                                                               options:NSRegularExpressionSearch
                                                                 range:NSMakeRange(0, [json length])];
    
    
    //把'单引号改为双引号"
    validString = [validString stringByReplacingOccurrencesOfString:@"([:\\[,\\{])'"
                                                         withString:@"$1\""
                                                            options:NSRegularExpressionSearch
                                                              range:NSMakeRange(0, [validString length])];
    validString = [validString stringByReplacingOccurrencesOfString:@"'([:\\],\\}])"
                                                         withString:@"\"$1"
                                                            options:NSRegularExpressionSearch
                                                              range:NSMakeRange(0, [validString length])];
    
    //再重复一次 将没有双引号的替换成有双引号的
    validString = [validString stringByReplacingOccurrencesOfString:@"([:\\[,\\{])(\\w+)\\s*:"
                                                         withString:@"$1\"$2\":"
                                                            options:NSRegularExpressionSearch
                                                              range:NSMakeRange(0, [validString length])];
    return validString;
}

#pragma mark ------> 手机隐蔽
+(NSString*)shoujibaomi:(NSString*)phone
{
    if (phone && phone.length>10) {
        return [phone stringByReplacingCharactersInRange:NSMakeRange(3, 4) withString:@"****"];
    }
    return phone;
}

+(NSArray *)arraySortASC:(NSArray *)arr
{
    NSArray *result = [arr sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        
        //        NSLog(@"%@~%@",obj1,obj2); //3~4 2~1 3~1 3~2
        
        return [obj1 compare:obj2]; //升序
        
    }];
    return result;
}

+(NSArray *)arraySortINV:(NSArray *)arr
{
    NSArray *result = [arr sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        
        
        return [obj2 compare:obj1]; //倒序
        
    }];
    return result;
}

+ (int)compareOneDay:(NSDate *)oneDay withAnotherDay:(NSDate *)anotherDay dateFormatter:(NSString *)df
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:df];
    NSString *oneDayStr = [dateFormatter stringFromDate:oneDay];
    NSString *anotherDayStr = [dateFormatter stringFromDate:anotherDay];
    NSDate *dateA = [dateFormatter dateFromString:oneDayStr];
    NSDate *dateB = [dateFormatter dateFromString:anotherDayStr];
    NSComparisonResult result = [dateA compare:dateB];
    //    NSLog(@"date1 : %@, date2 : %@", oneDay, anotherDay);
    if (result == NSOrderedDescending) {
        //NSLog(@"Date1  is in the future");
        return 1;
    }
    else if (result == NSOrderedAscending){
        //NSLog(@"Date1 is in the past");
        return -1;
    }
    //NSLog(@"Both dates are the same");
    return 0;
}

#pragma mark ------> 数字小写转大写
+(NSString *)getUperDigit:(NSString *)inputStr
{
    NSRange range = [inputStr rangeOfString:@"."];
    if (range.length != 0) {
        NSArray *tmpArray = [inputStr componentsSeparatedByString:@"."];
        int zhengShu = [[tmpArray objectAtIndex:0]intValue];
        NSString* xiaoShu = [tmpArray lastObject];
        NSString *zhengShuStr = [Utils getIntPartUper:zhengShu];
        if ([zhengShuStr isEqualToString:@"元"]) {   //整数部分为零，小数部分不为零的情况
            return [NSString stringWithFormat:@"%@",[Utils getPartAfterDot:xiaoShu]];
        }
        return [NSString stringWithFormat:@"%@%@",[Utils getIntPartUper:zhengShu],[Utils getPartAfterDot:xiaoShu]];
    }else
    {
        int zhengShu = [inputStr intValue];
        NSString *tmpStr = [Utils getIntPartUper:zhengShu];
        if ([tmpStr isEqualToString:@"元"]) {
            return [NSString stringWithFormat:@"零元整"];
        }
        else
        {
            return [NSString stringWithFormat:@"%@整",[Utils getIntPartUper:zhengShu]];
        }
    }
}

//得到整数部分
+(NSString *)getIntPartUper:(int)digit
{
    int geGrade = digit%10000;
    int wanGrade = digit/10000%10000;
    int yiGrade = digit/100000000;
    NSString *geGradeStr = [Utils dealWithDigit:geGrade grade:GradeTypeGe];
    NSString *wanGradeStr = [Utils dealWithDigit:wanGrade grade:GradeTypeWan];
    NSString *yiGradeStr = [Utils dealWithDigit:yiGrade grade:GradeTypeYi];
    NSMutableString *tmpStr = [NSMutableString stringWithFormat:@"%@%@%@元",yiGradeStr,wanGradeStr,geGradeStr];
    if ([[tmpStr substringToIndex:1]isEqualToString:@"零"]) {
        NSString *str1 = [tmpStr substringFromIndex:1];
        if ([[str1 substringToIndex:2]isEqualToString:@"壹拾"]) {
            return [str1 substringFromIndex:1];
        }
        else
        {
            return str1;
        }
    }
    else
    {
        return tmpStr;
    }
}

+(NSString *)getPartAfterDot:(NSString *)digitStr
{
    if (digitStr.length > 0) {
        NSArray *uperArray = @[@"零", @"壹", @"贰", @"叁", @"肆", @"伍", @"陆", @"柒", @"捌", @"玖"];
        NSString *digitStr1 = nil;
        if (digitStr.length == 1) {
            digitStr1 = [NSString stringWithFormat:@"%@0",digitStr];
            int digit = [[digitStr1 substringToIndex:2]intValue];
            int one = digit/10;
            int two = digit%10;
            if (one != 0 && two != 0) {
                return [NSString stringWithFormat:@"%@角%@分",[uperArray objectAtIndex:one],[uperArray objectAtIndex:two]];
            }
            else if(one == 0 && two != 0) {
                return [NSString stringWithFormat:@"%@分",[uperArray objectAtIndex:two]];
            }if(one != 0 && two == 0) {
                return [NSString stringWithFormat:@"%@角",[uperArray objectAtIndex:one]];
            }
            else
            {
                return @"";
            }
        }
        else
        {
            int digit = [[digitStr substringToIndex:2]intValue];
            int one = digit/10;
            int two = digit%10;
            if (one != 0 && two != 0) {
                return [NSString stringWithFormat:@"%@角%@分",[uperArray objectAtIndex:one],[uperArray objectAtIndex:two]];
            }
            else if(one == 0 && two != 0) {
                return [NSString stringWithFormat:@"%@分",[uperArray objectAtIndex:two]];
            }if(one != 0 && two == 0) {
                return [NSString stringWithFormat:@"%@角",[uperArray objectAtIndex:one]];
            }
            else
            {
                return @"";
            }
        }
    }
    else{
        return @"";
    }
}

+(NSString *)dealWithDigit:(int)digit grade:(GradeType)grade
{
    if (digit > 0) {
        NSArray *uperArray = @[@"零", @"壹", @"贰", @"叁", @"肆", @"伍", @"陆", @"柒", @"捌", @"玖"];
        NSArray *uperUnitArray = @[@"",@"拾",@"佰",@"仟"];
        
        NSString *ge = [NSString stringWithFormat:@"%d",digit%10];
        NSString *shi = [NSString stringWithFormat:@"%d",digit%100/10];
        NSString *bai = [NSString stringWithFormat:@"%d",digit%1000/100];
        NSString *qian = [NSString stringWithFormat:@"%d",digit/1000];
        NSArray *tmpArray = @[ge,shi,bai,qian];
        NSMutableArray *saveStrArray = [NSMutableArray array];
        BOOL lastIsZero = YES;
        for (int i = 0; i< tmpArray.count; i++) {
            int tmp = [[tmpArray objectAtIndex:i]intValue];
            if (tmp == 0) {
                if (lastIsZero == NO) {
                    [saveStrArray addObject:@""];
                    lastIsZero = YES;
                }
            }
            else
            {
                [saveStrArray addObject:[NSString stringWithFormat:@"%@%@",[uperArray objectAtIndex:tmp],[uperUnitArray objectAtIndex:i]]];
                lastIsZero = NO;
            }
        }
        
        NSMutableString *destStr = [[NSMutableString alloc]init];
        for (int i = (int)(saveStrArray.count - 1); i >= 0; i --) {
            [destStr appendString:[saveStrArray objectAtIndex:i]];
        }
        if (grade == GradeTypeGe)
        {
            return destStr;//个级
        }else if(grade == GradeTypeWan)
        {
            return [NSString stringWithFormat:@"%@万",destStr];//万级
        }
        else
        {
            return [NSString stringWithFormat:@"%@亿",destStr];//亿级
        }
    }
    else
    {
        return @"";//这个级别的数字都是“零”
    }
}

+(NSString *)digitUppercase:(NSString *)numstr
{
    double numberals=[numstr doubleValue];
    NSArray *numberchar = @[@"零",@"壹",@"贰",@"叁",@"肆",@"伍",@"陆",@"柒",@"捌",@"玖"];
    NSArray *inunitchar = @[@"",@"拾",@"佰",@"仟"];
    NSArray *unitname = @[@"",@"万",@"亿",@"万亿"];
    //金额乘以100转换成字符串（去除圆角分数值）
    NSString *valstr=[NSString stringWithFormat:@"%.2f",numberals];
    NSString *prefix;
    NSString *suffix;
    if (valstr.length<=2) {
        prefix=@"零元";
        if (valstr.length==0) {
            suffix=@"零角零分";
        }
        else if (valstr.length==1)
        {
            suffix=[NSString stringWithFormat:@"%@分",[numberchar objectAtIndex:[valstr intValue]]];
        }
        else
        {
            NSString *head=[valstr substringToIndex:1];
            NSString *foot=[valstr substringFromIndex:1];
            suffix = [NSString stringWithFormat:@"%@角%@分",[numberchar objectAtIndex:[head intValue]],[numberchar  objectAtIndex:[foot intValue]]];
        }
    }
    else
    {
        prefix=@"";
        suffix=@"";
        NSInteger flag = valstr.length - 2;
        NSString *head=[valstr substringToIndex:flag - 1];
        NSString *foot=[valstr substringFromIndex:flag];
        if (head.length>13) {
            return@"数值太大（最大支持13位整数），无法处理";
        }
        //处理整数部分
        NSMutableArray *ch=[[NSMutableArray alloc]init];
        for (int i = 0; i < head.length; i++) {
            NSString * str=[NSString stringWithFormat:@"%x",[head characterAtIndex:i]-'0'];
            [ch addObject:str];
        }
        int zeronum=0;
        
        for (int i=0; i<ch.count; i++) {
            int index=(ch.count -i-1)%4;//取段内位置
            NSInteger indexloc=(ch.count -i-1)/4;//取段位置
            if ([[ch objectAtIndex:i]isEqualToString:@"0"]) {
                zeronum++;
            }
            else
            {
                if (zeronum!=0) {
                    if (index!=3) {
                        prefix=[prefix stringByAppendingString:@"零"];
                    }
                    zeronum=0;
                }
                prefix=[prefix stringByAppendingString:[numberchar objectAtIndex:[[ch objectAtIndex:i]intValue]]];
                prefix=[prefix stringByAppendingString:[inunitchar objectAtIndex:index]];
            }
            if (index ==0 && zeronum<4) {
                prefix=[prefix stringByAppendingString:[unitname objectAtIndex:indexloc]];
            }
        }
        prefix =[prefix stringByAppendingString:@"元"];
        //处理小数位
        if ([foot isEqualToString:@"00"]) {
            suffix =[suffix stringByAppendingString:@"整"];
        }
        else if ([foot hasPrefix:@"0"])
        {
            NSString *footch=[NSString stringWithFormat:@"%x",[foot characterAtIndex:1]-'0'];
            suffix=[NSString stringWithFormat:@"%@分",[numberchar objectAtIndex:[footch intValue] ]];
        }
        else
        {
            NSString *headch=[NSString stringWithFormat:@"%x",[foot characterAtIndex:0]-'0'];
            NSString *footch=[NSString stringWithFormat:@"%x",[foot characterAtIndex:1]-'0'];
            suffix=[NSString stringWithFormat:@"%@角%@分",[numberchar objectAtIndex:[headch intValue]],[numberchar  objectAtIndex:[footch intValue]]];
        }
    }
    return [prefix stringByAppendingString:suffix];
}

#pragma mark ------> 查找某字符在字符串的位置
+ (NSArray *)rangeOfSubString:(NSString *)subStr inString:(NSString *)string
{
    
    NSMutableArray *rangeArray = [NSMutableArray array];
    
    NSString *string1 = [string stringByAppendingString:subStr];
    
    NSString *temp;
    
    for (int i = 0; i < string.length; i ++) {
        
        temp = [string1 substringWithRange:NSMakeRange(i, subStr.length)];
        
        if ([temp isEqualToString:subStr]) {
            
            NSRange range = {i,subStr.length};
            
            [rangeArray addObject:NSStringFromRange(range)];
        }
    }
    return rangeArray;
}

#pragma mark ------> DateAndTime
+(NSDate *)fewMonthLater:(NSInteger)month
                 fromNow:(NSDate *)thisTime
                timeType:(FewMonthLaterType)type
{
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *adcomps = [calendar components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay fromDate:thisTime];
    [adcomps setYear:0];
    switch (type) {
        case FewMonthLaterTypeNormal:
        {
            [adcomps setMonth:month];
            [adcomps setDay:0];
        }
            break;
        case FewMonthLaterTypeContract:
        {
            [adcomps setMonth:(month-1)];
            
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            [formatter setDateStyle:NSDateFormatterMediumStyle];
            [formatter setTimeStyle:NSDateFormatterShortStyle];
            [formatter setDateFormat:@"MM"];
            
            NSDateFormatter *formatterYear = [[NSDateFormatter alloc] init];
            [formatterYear setDateStyle:NSDateFormatterMediumStyle];
            [formatterYear setTimeStyle:NSDateFormatterShortStyle];
            [formatterYear setDateFormat:@"YYYY"];

            
            NSString *monthString = [formatter stringFromDate:[calendar dateByAddingComponents:adcomps toDate:thisTime options:0]];
            if ([monthString isEqualToString:@"01"] || [monthString isEqualToString:@"03"] || [monthString isEqualToString:@"05"] || [monthString isEqualToString:@"07"] || [monthString isEqualToString:@"08"] || [monthString isEqualToString:@"10"] || [monthString isEqualToString:@"12"])
            {
                [adcomps setDay:30];
            }
            else if ([monthString isEqualToString:@"04"] || [monthString isEqualToString:@"06"] || [monthString isEqualToString:@"09"] || [monthString isEqualToString:@"11"])
            {
                [adcomps setDay:29];
            }
            else
            {
                NSString *yearString = [formatterYear stringFromDate:[calendar dateByAddingComponents:adcomps toDate:thisTime options:0]];

                if([yearString integerValue]%4 == 0 && [yearString integerValue]%100 != 0)//普通年份，非100整数倍
                {
                    [adcomps setDay:28];
                }
                else if ([yearString integerValue]%400 == 0)
                {
                    [adcomps setDay:28];
                }
                else
                {
                    [adcomps setDay:27];
                }
            }
        }
            break;
        default:
            break;
    }
    
    return [calendar dateByAddingComponents:adcomps toDate:thisTime options:0];
}

#pragma mark ------> 生成二维码
+(UIImage *)createQRImageWithString:(NSString *)string withSize:(CGFloat)size
{
    CIFilter *filter = [CIFilter filterWithName:@"CIQRCodeGenerator"];
    // 滤镜恢复默认设置
    [filter setDefaults];
    
    // 2. 给滤镜添加数据
    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
    // 使用KVC的方式给filter赋值
    [filter setValue:data forKeyPath:@"inputMessage"];
    
    // 3. 生成二维码
    CIImage *image = [filter outputImage];
    return [Utils createNonInterpolatedUIImageFormCIImage:image withSize:size];
}

+ (UIImage *)createNonInterpolatedUIImageFormCIImage:(CIImage *)image withSize:(CGFloat) size {
    
    CGRect extent = CGRectIntegral(image.extent);
    CGFloat scale = MIN(size/CGRectGetWidth(extent), size/CGRectGetHeight(extent));
    
    // 1.创建bitmap;
    size_t width = CGRectGetWidth(extent) * scale;
    size_t height = CGRectGetHeight(extent) * scale;
    CGColorSpaceRef cs = CGColorSpaceCreateDeviceGray();
    CGContextRef bitmapRef = CGBitmapContextCreate(nil, width, height, 8, 0, cs, (CGBitmapInfo)kCGImageAlphaNone);
    //FIX:释放
    CFRelease(cs);
    CIContext *context = [CIContext contextWithOptions:nil];
    CGImageRef bitmapImage = [context createCGImage:image fromRect:extent];
    CGContextSetInterpolationQuality(bitmapRef, kCGInterpolationNone);
    CGContextScaleCTM(bitmapRef, scale, scale);
    CGContextDrawImage(bitmapRef, extent, bitmapImage);
    
    // 2.保存bitmap到图片
    CGImageRef scaledImage = CGBitmapContextCreateImage(bitmapRef);
    CGContextRelease(bitmapRef);
    CGImageRelease(bitmapImage);
    
    UIImage *newImage = [UIImage imageWithCGImage:scaledImage];
    //FIX:释放
    CFRelease(scaledImage);
    
    return newImage;
}

#pragma mark ------>华氏转摄氏/摄氏转华氏
+ (CGFloat)temperatureUnitExchangeValue:(CGFloat)value changeTo:(TemperatureUnit)unit
{ //温度单位转换方法
    if (unit == Fahrenheit)
    {
        return 32 + 1.8 * value; //华氏度
    }
    else
    {
        return (value - 32) / 1.8; //摄氏度
    }
}

#pragma mark ------>英文星期几转中文星期几
+(NSString *)engDayCoverToZHCN:(NSString *)str
{
    NSString *realStr;
    if ([str isEqualToString:@"Mon"]) {
        realStr = @"周一";
    }
    else if ([str isEqualToString:@"Tue"]) {
        realStr = @"周二";
    }
    else if ([str isEqualToString:@"Wed"]) {
        realStr = @"周三";
    }
    else if ([str isEqualToString:@"Thu"]) {
        realStr = @"周四";
    }
    else if ([str isEqualToString:@"Fri"]) {
        realStr = @"周五";
    }
    else if ([str isEqualToString:@"Sat"]) {
        realStr = @"周六";
    }
    else if ([str isEqualToString:@"Sun"]) {
        realStr = @"周日";
    }
    return realStr;
}

#pragma mark ------>判断是否白天
+(BOOL)isNowDayTime
{
    NSDate *date = [NSDate date];
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents *components = [cal components:NSCalendarUnitHour fromDate:date];
    if ([components hour] >= 19 || [components hour] < 6) {
        return NO;
    }else{
        return YES;
    }
}

#pragma mark ------>String
+(BOOL)stringContainsEmoji:(NSString *)string
{
    __block BOOL returnValue = NO;
    
    [string enumerateSubstringsInRange:NSMakeRange(0, [string length])
                               options:NSStringEnumerationByComposedCharacterSequences
                            usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
                                const unichar hs = [substring characterAtIndex:0];
                                if (0xd800 <= hs && hs <= 0xdbff) {
                                    if (substring.length > 1) {
                                        const unichar ls = [substring characterAtIndex:1];
                                        const int uc = ((hs - 0xd800) * 0x400) + (ls - 0xdc00) + 0x10000;
                                        if (0x1d000 <= uc && uc <= 0x1f77f) {
                                            returnValue = YES;
                                        }
                                    }
                                } else if (substring.length > 1) {
                                    const unichar ls = [substring characterAtIndex:1];
                                    if (ls == 0x20e3) {
                                        returnValue = YES;
                                    }
                                } else {
                                    if (0x2100 <= hs && hs <= 0x27ff) {
                                        returnValue = YES;
                                    } else if (0x2B05 <= hs && hs <= 0x2b07) {
                                        returnValue = YES;
                                    } else if (0x2934 <= hs && hs <= 0x2935) {
                                        returnValue = YES;
                                    } else if (0x3297 <= hs && hs <= 0x3299) {
                                        returnValue = YES;
                                    } else if (hs == 0xa9 || hs == 0xae || hs == 0x303d || hs == 0x3030 || hs == 0x2b55 || hs == 0x2b1c || hs == 0x2b1b || hs == 0x2b50) {
                                        returnValue = YES;
                                    }
                                }
                            }];
    
    return returnValue;
}

@end
