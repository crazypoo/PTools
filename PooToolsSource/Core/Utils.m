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
