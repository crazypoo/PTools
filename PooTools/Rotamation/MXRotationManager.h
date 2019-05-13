//
//  MXRotationManager.h
//  Yunlu
//
//  Created by Michael on 2018/9/21.
//  Copyright © 2018 DCloud. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MXRotationManager : NSObject

@property (nonatomic, readonly) UIInterfaceOrientationMask interfaceOrientationMask;
@property (nonatomic) UIDeviceOrientation orientation;

/*! @brief 初始化
 * @see 在Appdelegate中加载此方法
 - (UIInterfaceOrientationMask)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window {
 return [MXRotationManager defaultManager].interfaceOrientationMask;
 }
 * @see 在须要变换状态的ViewController中使用此方法
 [MXRotationManager defaultManager].orientation = UIDeviceOrientationLandscapeRight;
 * @attention 不支持iPad
 */
+ (instancetype)defaultManager;

@end
