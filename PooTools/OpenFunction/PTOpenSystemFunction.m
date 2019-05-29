//
//  PTOpenSystemFunction.m
//  PooTools_Example
//
//  Created by 邓杰豪 on 2019/3/23.
//  Copyright © 2019年 crazypoo. All rights reserved.
//

#import "PTOpenSystemFunction.h"

#import "PMacros.h"
#import "Utils.h"

@implementation PTOpenSystemFunction
+(void)openSystemFunction:(SystemFunctionType)type functionEx:(NSString *)ex withScheme:(NSString *)scheme
{
    NSString  *urlString;
    switch (type) {
        case SystemFunctionTypeCall:
        {
            if (kStringIsEmpty(ex)) {
                [Utils alertVCOnlyShowWithTitle:nil andMessage:@"请填写电话号码"];
                return;
            }
            else
            {
                urlString = [NSString stringWithFormat:@"tel://%@",ex];
            }
        }
            break;
        case SystemFunctionTypeSMS:
        {
            if (kStringIsEmpty(ex)) {
                [Utils alertVCOnlyShowWithTitle:nil andMessage:@"请填写电话号码"];
                return;
            }
            else
            {
                urlString = [NSString stringWithFormat:@"sms://%@",ex];
            }
        }
            break;
        case SystemFunctionTypeMail:
        {
            if (kStringIsEmpty(ex)) {
                [Utils alertVCOnlyShowWithTitle:nil andMessage:@"请填写邮箱"];

                return;
            }
            else
            {
                urlString = [NSString stringWithFormat:@"mailto://%@",ex];
            }
        }
            break;
        case SystemFunctionTypeAppStore:
        {
            if (kStringIsEmpty(ex)) {
                [Utils alertVCOnlyShowWithTitle:nil andMessage:@"请填写AppID"];
                return;
            }
            else
            {
                urlString = [NSString stringWithFormat:@"itms-apps://itunes.apple.com/app/id%@",ex];
            }
        }
            break;
        case SystemFunctionTypeSafari:
        {
            if (kStringIsEmpty(ex)) {
                [Utils alertVCOnlyShowWithTitle:nil andMessage:@"请填写网址"];
                return;
            }
            else
            {
                urlString = [NSString stringWithFormat:@"%@",ex];
            }
        }
            break;
        case SystemFunctionTypeiBook:
        {
            urlString = [NSString stringWithFormat:@"itms-books://"];
        }
            break;
        case SystemFunctionTypeFaceTime:
        {
            if (kStringIsEmpty(ex)) {
                [Utils alertVCOnlyShowWithTitle:nil andMessage:@"请填写电话号码"];
                return;
            }
            else
            {
                urlString = [NSString stringWithFormat:@"facetime://%@",ex];
            }
        }
            break;
        case SystemFunctionTypeMap:
        {
            urlString = [NSString stringWithFormat:@"maps://"];
        }
            break;
        case SystemFunctionTypeMusic:
        {
            urlString = [NSString stringWithFormat:@"music://"];
        }
            break;
        case SystemFunctionTypeSetting:
        {
            if (kStringIsEmpty(scheme)) {
                [Utils alertVCOnlyShowWithTitle:nil andMessage:@"请在Xcode设置Scheme"];
                return;
            }
            else
            {
                urlString = [NSString stringWithFormat:@"%@",UIApplicationOpenSettingsURLString];
            }
        }
            break;
        case SystemFunctionTypeCastle:
        {
            if (kStringIsEmpty(scheme)) {
                [Utils alertVCOnlyShowWithTitle:nil andMessage:@"请在Xcode设置Scheme"];
                return;
            }
            else
            {
                urlString = [NSString stringWithFormat:@"%@:root=CASTLE",scheme];
            }
        }
            break;
        case SystemFunctionTypeWIFI:
        {
            if (kStringIsEmpty(scheme)) {
                [Utils alertVCOnlyShowWithTitle:nil andMessage:@"请在Xcode设置Scheme"];
                return;
            }
            else
            {
                urlString = [NSString stringWithFormat:@"%@:root=WIFI",scheme];
            }
        }
            break;
        case SystemFunctionTypeBluetooth:
        {
            if (kStringIsEmpty(scheme)) {
                [Utils alertVCOnlyShowWithTitle:nil andMessage:@"请在Xcode设置Scheme"];
                return;
            }
            else
            {
                urlString = [NSString stringWithFormat:@"%@:root=Bluetooth",scheme];
            }
        }
            break;
        case SystemFunctionTypeMobileData:
        {
            if (kStringIsEmpty(scheme)) {
                [Utils alertVCOnlyShowWithTitle:nil andMessage:@"请在Xcode设置Scheme"];
                return;
            }
            else
            {
                urlString = [NSString stringWithFormat:@"%@:root=MOBILE_DATA_SETTINGS_ID",scheme];
            }
        }
            break;
        case SystemFunctionTypeNotification:
        {
            if (kStringIsEmpty(scheme)) {
                [Utils alertVCOnlyShowWithTitle:nil andMessage:@"请在Xcode设置Scheme"];
                return;
            }
            else
            {
                urlString = [NSString stringWithFormat:@"%@:root=NOTIFICATIONS_ID",scheme];
            }
        }
            break;
        case SystemFunctionTypeGeneral:
        {
            if (kStringIsEmpty(scheme)) {
                [Utils alertVCOnlyShowWithTitle:nil andMessage:@"请在Xcode设置Scheme"];
                return;
            }
            else
            {
                urlString = [NSString stringWithFormat:@"%@:root=General",scheme];
            }
        }
            break;
        case SystemFunctionTypeAbout:
        {
            if (kStringIsEmpty(scheme)) {
                [Utils alertVCOnlyShowWithTitle:nil andMessage:@"请在Xcode设置Scheme"];
                return;
            }
            else
            {
                urlString = [NSString stringWithFormat:@"%@:root=General&path=About",scheme];
            }
        }
            break;
        case SystemFunctionTypeAccessibilly:
        {
            if (kStringIsEmpty(scheme)) {
                [Utils alertVCOnlyShowWithTitle:nil andMessage:@"请在Xcode设置Scheme"];
                return;
            }
            else
            {
                urlString = [NSString stringWithFormat:@"%@:root=General&path=ACCESSIBILITY",scheme];
            }
        }
            break;
        case SystemFunctionTypeDateAndTime:
        {
            if (kStringIsEmpty(scheme)) {
                [Utils alertVCOnlyShowWithTitle:nil andMessage:@"请在Xcode设置Scheme"];
                return;
            }
            else
            {
                urlString = [NSString stringWithFormat:@"%@:root=General&path=DATE_AND_TIME",scheme];
            }
        }
            break;
        case SystemFunctionTypeKeyboard:
        {
            if (kStringIsEmpty(scheme)) {
                [Utils alertVCOnlyShowWithTitle:nil andMessage:@"请在Xcode设置Scheme"];
                return;
            }
            else
            {
                urlString = [NSString stringWithFormat:@"%@:root=General&path=Keyboard",scheme];
            }
        }
            break;
        case SystemFunctionTypeDisplay:
        {
            if (kStringIsEmpty(scheme)) {
                [Utils alertVCOnlyShowWithTitle:nil andMessage:@"请在Xcode设置Scheme"];
                return;
            }
            else
            {
                urlString = [NSString stringWithFormat:@"%@:root=DISPLAY",scheme];
            }
        }
            break;
        case SystemFunctionTypeWallpaper:
        {
            if (kStringIsEmpty(scheme)) {
                [Utils alertVCOnlyShowWithTitle:nil andMessage:@"请在Xcode设置Scheme"];
                return;
            }
            else
            {
                urlString = [NSString stringWithFormat:@"%@:root=Wallpaper",scheme];
            }
        }
            break;
        case SystemFunctionTypeSounds:
        {
            if (kStringIsEmpty(scheme)) {
                [Utils alertVCOnlyShowWithTitle:nil andMessage:@"请在Xcode设置Scheme"];
                return;
            }
            else
            {
                urlString = [NSString stringWithFormat:@"%@:root=Sounds",scheme];
            }
        }
            break;
        case SystemFunctionTypeBattery:
        {
            if (kStringIsEmpty(scheme)) {
                [Utils alertVCOnlyShowWithTitle:nil andMessage:@"请在Xcode设置Scheme"];
                return;
            }
            else
            {
                urlString = [NSString stringWithFormat:@"%@:root=BATTERY_USAGE",scheme];
            }
        }
            break;
        case SystemFunctionTypeLocation:
        {
            if (kStringIsEmpty(scheme)) {
                [Utils alertVCOnlyShowWithTitle:nil andMessage:@"请在Xcode设置Scheme"];
                return;
            }
            else
            {
                urlString = [NSString stringWithFormat:@"%@:root=Privacy&path=LOCATION",scheme];
            }
        }
            break;
        case SystemFunctionTypePrivace:
        {
            if (kStringIsEmpty(scheme)) {
                [Utils alertVCOnlyShowWithTitle:nil andMessage:@"请在Xcode设置Scheme"];
                return;
            }
            else
            {
                urlString = [NSString stringWithFormat:@"%@:root=Privacy",scheme];
            }
        }
            break;
        case SystemFunctionTypeSiri:
        {
            if (kStringIsEmpty(scheme)) {
                [Utils alertVCOnlyShowWithTitle:nil andMessage:@"请在Xcode设置Scheme"];
                return;
            }
            else
            {
                urlString = [NSString stringWithFormat:@"%@:root=Siri",scheme];
            }
        }
            break;
        default:
            break;
    }
    if (@available(iOS 10.0, *)) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlString]
                                           options:@{}
                                 completionHandler:nil];
    }
    else
    {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlString]];
    }
}
@end
