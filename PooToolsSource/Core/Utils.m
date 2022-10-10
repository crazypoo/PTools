//
//  Utils.m
//  login
//
//  Created by crazypoo on 14/7/10.
//  Copyright (c) 2014年 crazypoo. All rights reserved.
//

#import "Utils.h"
#import "PMacros.h"

#import <PooTools/PooTools-Swift.h>

#define HORIZONTAL_SPACE 30//水平间距
#define VERTICAL_SPACE 50//竖直间距
#define CG_TRANSFORM_ROTATION (M_PI_2 / 3)//旋转角度(正旋45度 || 反旋45度)

@implementation Utils

+(void)alertVCOnlyShowWithTitle:(NSString *)title
                     andMessage:(NSString *)message
{
    [PTUtils oc_alert_baseWithTitle:title msg:message okBtns:@[] cancelBtn:@"确定" showIn:kAppDelegateWindow.rootViewController cancel:^{
        
    } moreBtn:^(NSInteger selectIndex, NSString * selectTitle) {
        
    }];
}

+(void)alertVCWithTitle:(NSString *)title message:(NSString *)m cancelTitle:(NSString *)cT okTitle:(NSString *)okT shouIn:(UIViewController *)vC okAction:(void (^ _Nullable)(void))okBlock cancelAction:(void (^ _Nullable)(void))cancelBlock
{
    [PTUtils oc_alert_baseWithTitle:title msg:m okBtns:@[okT] cancelBtn:cT showIn:vC cancel:^{
        cancelBlock();
    } moreBtn:^(NSInteger index, NSString * value) {
        okBlock();
    }];
}

+(void)alertVCWithTitle:(NSString *)title message:(NSString *)m cancelTitle:(NSString *)cT shouIn:(UIViewController *)vC cancelAction:(void (^ _Nullable)(void))cancelBlock
{
    [PTUtils oc_alert_baseWithTitle:title msg:m okBtns:@[] cancelBtn:cT showIn:vC cancel:^{
        cancelBlock();
    } moreBtn:^(NSInteger index, NSString * value) {
    }];
}

+(void)alertVCWithTitle:(NSString *_Nullable)title
                message:(NSString *_Nullable)m
            cancelTitle:(NSString *_Nullable)cT
                okTitle:(NSString *_Nullable)okT
       destructiveTitle:(NSString *_Nullable)dT
       otherButtonArray:(NSArray *_Nullable)titleArr
                 shouIn:(UIViewController *_Nonnull)vC
      sourceViewForiPad:(UIView *_Nullable)sView
             alertStyle:(UIAlertControllerStyle)style
               okAction:(void (^ _Nullable)(void))okBlock
           cancelAction:(void (^ _Nullable)(void))cancelBlock
      destructiveAction:(void (^ _Nullable)(void))destructiveBlock
      otherButtonAction:(void (^_Nullable)(NSInteger index))buttonIndexPath
{    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title
                                                                             message:m
                                                                      preferredStyle:style];
    
    if (!kStringIsEmpty(okT)) {
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:okT style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            okBlock();
        }];
        [alertController addAction:okAction];
    }
    
    if (!kStringIsEmpty(cT)) {
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:cT style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            cancelBlock();
        }];
        [alertController addAction:cancelAction];
    }
    
    if (!kStringIsEmpty(dT)) {
        UIAlertAction *destructiveAction = [UIAlertAction actionWithTitle:dT style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            destructiveBlock();
        }];
        [alertController addAction:destructiveAction];
    }
    
    for (int i = 0; i < titleArr.count; i++) {
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:titleArr[i] style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            buttonIndexPath(i);
        }];
        [alertController addAction:cancelAction];
    }
    
    if (style == UIAlertControllerStyleActionSheet)
    {
        if (IS_IPAD) {
            if (!sView)
            {
                [Utils alertVCOnlyShowWithTitle:@"提示" andMessage:@"在iPad上使用UIAlertControllerStyleActionSheet,须要填入popover的数据源"];
            }
            else
            {
                UIPopoverPresentationController *popover = alertController.popoverPresentationController;
                if (popover)
                {
                    popover.sourceView = sView;
                    popover.sourceRect = sView.frame;
                    popover.permittedArrowDirections = UIPopoverArrowDirectionAny;
                }
            }
        }
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

+(CheckNowTimeAndPastTimeRelationships)checkContractDateExpireContractDate:(NSString *)contractDate expTimeStamp:(int)timeStamp
{
    NSDateFormatter *formater = [[NSDateFormatter alloc] init];
    [formater setDateFormat:@"yyyy-MM-dd"];
    NSDate *create = [formater dateFromString:contractDate];
    NSDate *now = [NSDate date];
    NSTimeInterval timeDifference = [create timeIntervalSinceDate:now];
    double thirty = [[NSNumber numberWithInt: timeStamp] doubleValue];
    double result = timeDifference - thirty;
    if (result > (-thirty) && result < thirty) {
        return CheckNowTimeAndPastTimeRelationshipsReadyExpire;
    }
    else if (result < (-thirty))
    {
        return CheckNowTimeAndPastTimeRelationshipsExpire;
    }
    else if (result > 0)
    {
        return CheckNowTimeAndPastTimeRelationshipsNormal;
    }
    else
    {
        return CheckNowTimeAndPastTimeRelationshipsError;
    }
}

+(CheckNowTimeAndPastTimeRelationships)checkStartDateExpireEndDataWithStartDate:(NSString *)sD withEndDate:(NSString *)eD expTimeStamp:(int)timeStamp
{
    NSDateFormatter *formater = [[NSDateFormatter alloc] init];
    [formater setDateFormat:@"yyyy-MM-dd"];
    NSDate *startDate = [formater dateFromString:sD];
    NSDate *endDate = [formater dateFromString:eD];
    
    NSTimeInterval timeDifference = [endDate timeIntervalSinceDate:startDate];
    double thirty = [[NSNumber numberWithInt:timeStamp] floatValue];
    double result = timeDifference - thirty;

    if (result > (-thirty) && result < thirty) {
        return CheckNowTimeAndPastTimeRelationshipsReadyExpire;
    }
    else if (result < (-thirty))
    {
        return CheckNowTimeAndPastTimeRelationshipsExpire;
    }
    else if (result > 0)
    {
        return CheckNowTimeAndPastTimeRelationshipsNormal;
    }
    else
    {
        return CheckNowTimeAndPastTimeRelationshipsError;
    }
}

+(void)changeAPPIcon:(NSString *)IconName
{
    if (@available(iOS 10.3, *)) {
        if ([UIApplication sharedApplication].supportsAlternateIcons) {
            NSLog(@"you can change this app's icon");
        }else{
            [Utils alertVCOnlyShowWithTitle:nil andMessage:@"你不能更换此APP的Icon"];
            return;
        }
        
        NSString *iconName = [[UIApplication sharedApplication] alternateIconName];
        
        if (iconName) {
            // change to primary icon
            [[UIApplication sharedApplication] setAlternateIconName:nil completionHandler:^(NSError * _Nullable error) {
                if (error) {
                    [Utils alertVCOnlyShowWithTitle:nil andMessage:[NSString stringWithFormat:@"set icon error: %@",error]];
                }
                NSLog(@"The alternate icon's name is %@",iconName);
            }];
        }
        else
        {
            // change to alterante icon
            [[UIApplication sharedApplication] setAlternateIconName:IconName completionHandler:^(NSError * _Nullable error) {
                if (error) {
                    [Utils alertVCOnlyShowWithTitle:nil andMessage:[NSString stringWithFormat:@"set icon error: %@",error]];
                }
                NSLog(@"The alternate icon's name is %@",iconName);
            }];
        }
    }
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

+ (UIImage *)getWaterMarkImage:(UIImage *)originalImage andTitle:(NSString *)title andMarkFont:(UIFont *)markFont andMarkColor:(UIColor *)markColor{
    return [originalImage watermarkWithTitle:title font:markFont color:markColor];
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

+ (BOOL)isRolling:(UIView * _Nonnull)view
{
    
    if ([view isKindOfClass:[UIScrollView class]]) {
        UIScrollView *scrollView = (UIScrollView *)view;
        
        if (scrollView.dragging || scrollView.decelerating) return YES;
        // 如果UIPickerView正在拖拽或者是正在减速，返回YES
        
    }
    
    for (UIView *subView in view.subviews) {
        
        if ([self isRolling:subView]) {
            return YES;
            
        }
        
    }
    return NO;
}

+(UIViewController *)getCurrentVCFrom:(UIViewController *)rootVC
{
    return [PTUtils getCurrentVCFromRootVC:rootVC];
}

+(UIViewController *)getCurrentVC
{
    UIViewController *currentVC = [Utils getCurrentVCFrom:kAppDelegateWindow.rootViewController];
    return currentVC;
}
@end
