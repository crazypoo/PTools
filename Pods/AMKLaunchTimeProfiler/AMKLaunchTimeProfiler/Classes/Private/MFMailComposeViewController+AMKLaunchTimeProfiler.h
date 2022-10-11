//
//  MFMailComposeViewController+AMKLaunchTimeProfiler.h
//  AMKLaunchTimeProfiler
//
//  Created by mengxinxin on 2022/3/24.
//

#import <MessageUI/MessageUI.h>

UIKIT_EXTERN NSString *AMKLaunchTimeProfilerStringFromMFMailComposeResult(MFMailComposeResult result);

@interface MFMailComposeViewController (AMKLaunchTimeProfiler)

@end
