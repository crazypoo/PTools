//
//  UIDevice+AMKLaunchTimeProfiler.h
//  AMKLaunchTimeProfiler
//
//  Created by mengxinxin on 2022/3/23.
//

#import <UIKit/UIKit.h>

/// fetching model descriptions from an iOS device
/// @see https://github.com/squarefrog/UIDeviceIdentifier/blob/master/UIDeviceIdentifier
@interface UIDevice (AMKLaunchTimeProfiler)

/// The model name of the device. For example, `iPhone5,3`, `iPad3,1`, `iPod5,1`.
/// @return The current devices model name as a string.
+ (NSString *)amkltp_platform;

/// The full human readable platform string. For example, `iPhone 5C (GSM)`, `iPad 3 (WiFi)`, `iPod Touch 5G`.
/// @return The current devices platform string in a human readable format.
+ (NSString *)amkltp_platformString;

/// The simplified human readable platform string. For example, `iPhone 5C`, `iPad 3`, `iPod Touch 5G`.
/// @return The current devices platform string in a simplified human readable format.
+ (NSString *)amkltp_platformStringSimple;

/// Get a platform string for a specified type. For example: `[UIDeviceHardware platformStringForType:@"iPhone5,3"];  Returns "iPhone 5C (GSM)"
/// @return The platform string for the specified device type.
+ (NSString *)amkltp_platformStringForType:(NSString *)type;

@end
