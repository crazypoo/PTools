//
//  UIBarButtonItem+AMKLaunchTimeProfiler.h
//  AMKLaunchTimeProfiler
//
//  Created by mengxinxin on 2022/3/24.
//

#import <UIKit/UIKit.h>
#import <AMKLaunchTimeProfiler/UIImage+AMKLaunchTimeProfiler.h>

@interface UIBarButtonItem (AMKLaunchTimeProfiler)

- (instancetype _Nullable)amkltp_initWithImageType:(AMKLaunchTimeProfilerImageType)type target:(id _Nullable)target action:(SEL _Nullable)action;

@end
