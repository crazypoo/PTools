//
//  AMKLaunchTimeProfilerLogsViewController.h
//  AMKLaunchTimeProfiler
//
//  Created by mengxinxin on 2022/3/23.
//

#import <UIKit/UIKit.h>

/// APP启动耗时分析 - 日志列表
@interface AMKLaunchTimeProfilerLogsViewController : UIViewController

- (void)presentingWithAnimated:(BOOL)flag completion:(void (^_Nullable)(void))completion;

@end
