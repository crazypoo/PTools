//
//  MFMailComposeViewController+AMKLaunchTimeProfiler.m
//  AMKLaunchTimeProfiler
//
//  Created by mengxinxin on 2022/3/24.
//

#import "MFMailComposeViewController+AMKLaunchTimeProfiler.h"

NSString *AMKLaunchTimeProfilerStringFromMFMailComposeResult(MFMailComposeResult result) {
    switch (result) {
        case MFMailComposeResultCancelled: return @"邮件已取消发送";
        case MFMailComposeResultSaved: return @"邮件已保存至草稿箱";
        case MFMailComposeResultSent: return @"邮件已发送";
        case MFMailComposeResultFailed: return @"邮件发送失败";
        default: return nil;
    }
}

@implementation MFMailComposeViewController (AMKLaunchTimeProfiler)

@end
