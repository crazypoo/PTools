//
//  UIImage+AMKLaunchTimeProfiler.h
//  AMKLaunchTimeProfiler
//
//  Created by mengxinxin on 2022/3/24.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, AMKLaunchTimeProfilerImageType) {
    AMKLaunchTimeProfilerImageTypeNone = 0,
    AMKLaunchTimeProfilerImageTypeNaviBarClose,             //!< 导航栏 - 关闭
    AMKLaunchTimeProfilerImageTypeNaviBarFilter,            //!< 导航栏 - 过滤
    AMKLaunchTimeProfilerImageTypeNaviBarFilterSelected,    //!< 导航栏 - 过滤 - 选中
    AMKLaunchTimeProfilerImageTypeNaviBarMore,              //!< 导航栏 - 更多
};

@interface UIImage (AMKLaunchTimeProfiler)

+ (UIImage *)amkltp_imageWithType:(AMKLaunchTimeProfilerImageType)type;

@end
