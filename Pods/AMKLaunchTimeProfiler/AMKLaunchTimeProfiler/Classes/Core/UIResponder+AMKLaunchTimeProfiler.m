//
//  UIResponder+AMKLaunchTimeProfiler.m
//  AMKLaunchTimeProfiler
//
//  Created by mengxinxin on 2022/5/5.
//

#import "UIResponder+AMKLaunchTimeProfiler.h"
#import "AMKLaunchTimeProfiler.h"
#import "AMKLaunchTimeProfiler+Private.h"
#import <Aspects/Aspects.h>

@interface AMKLaunchTimeProfiler ()
@property(nonatomic, assign, readwrite) NSTimeInterval processStartTime;
@property(nonatomic, assign, readwrite) NSTimeInterval mainTime;
@property(nonatomic, assign, readwrite) NSTimeInterval didFinishLaunchingTime;
@property(nonatomic, assign, readwrite) NSTimeInterval firstScreenTime;
@property(nonatomic, strong, readonly, nonnull, class) UISwipeGestureRecognizer *gestureRecognizer;
- (void)printAnalysis;
@end

@implementation UIResponder (AMKLaunchTimeProfiler)

+ (void)load {
    [self AMKLaunchTimeProfiler_UIResponder_hookInit];
}

// 通过 hook [UIResponder -init] 方法，找到 UIApplication.sharedApplication.delegate 实例
// 并 hook 它的 -application:didFinishLaunchingWithOptions: 方法
+ (void)AMKLaunchTimeProfiler_UIResponder_hookInit {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        static id<AspectToken> aspectToken;
        aspectToken = [UIResponder aspect_hookSelector:@selector(init) withOptions:AspectPositionAfter usingBlock:^(id<AspectInfo> aspectInfo) {
            if ([aspectInfo.instance conformsToProtocol:@protocol(UIApplicationDelegate)]) {
                if ([aspectInfo.instance respondsToSelector:@selector(application:didFinishLaunchingWithOptions:)]) {
                    [aspectInfo.instance AMKLaunchTimeProfiler_UIResponder_hookApplication$didFinishLaunchingWithOptions$];
                    [aspectInfo.instance AMKLaunchTimeProfiler_UIResponder_hookSetWindow$];
                    [aspectToken remove];
                    aspectToken = nil;
                }
            }
        } error:NULL];
    });
}

// 通过 hook UIApplication.sharedApplication.delegate 的 -application:didFinishLaunchingWithOptions: 方法
// 在其执行完之后，记录 didFinishLaunchingTime
- (void)AMKLaunchTimeProfiler_UIResponder_hookApplication$didFinishLaunchingWithOptions$ {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        static id<AspectToken> aspectToken;
        aspectToken = [self aspect_hookSelector:@selector(application:didFinishLaunchingWithOptions:) withOptions:AspectPositionAfter usingBlock:^(id<AspectInfo> aspectInfo, UIApplication *application, NSDictionary *launchOptions) {
            if (aspectInfo.instance == UIApplication.sharedApplication.delegate) {
                AMKLaunchTimeProfiler.gestureRecognizer.enabled = AMKLaunchTimeProfiler.debugEnable;
                AMKLaunchTimeProfiler.sharedInstance.didFinishLaunchingTime = (CFAbsoluteTimeGetCurrent() + kCFAbsoluteTimeIntervalSince1970);
                AMKLaunchTimeProfilerInternalLog(@"did finish launching time: %@", @(AMKLaunchTimeProfiler.sharedInstance.didFinishLaunchingTime).amkltp_formattedDateStringForSystemTimeZone);
                [NSNotificationCenter.defaultCenter postNotificationName:AMKLaunchTimeProfilerApplicationDidFinishLaunchingNotification object:AMKLaunchTimeProfiler.sharedInstance];
                [aspectToken remove];
                aspectToken = nil;
            }
        } error:NULL];
    });
}

- (void)AMKLaunchTimeProfiler_UIResponder_hookSetWindow$ {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        // 通过 hook UIApplication.sharedApplication.delegate 的 -setWindow: 方法，以便获取 keyWindoew
        [self aspect_hookSelector:@selector(setWindow:) withOptions:AspectPositionAfter|AspectOptionAutomaticRemoval usingBlock:^(id<AspectInfo> aspectInfo, UIWindow *window) {
            UIResponder<UIApplicationDelegate> *appDelegate = aspectInfo.instance;
            UIWindow *keyWindow = appDelegate.window;
            if (keyWindow) {
                
                // 通过 hook keyWindoew 的 -setRootViewController: 方法，以便获取 rootViewController
                [keyWindow aspect_hookSelector:@selector(setRootViewController:) withOptions:AspectPositionAfter|AspectOptionAutomaticRemoval usingBlock:^(id<AspectInfo> aspectInfo, UIViewController *viewController) {
                    UIWindow *keyWindow = aspectInfo.instance;
                    UIViewController *rootViewController = keyWindow.rootViewController;
                    if (rootViewController) {
                        
                        // 通过 hook rootViewController 的 -viewDidAppear: 方法，以便在其执行完该方法之后，记录 firstScreenTime
                        [rootViewController aspect_hookSelector:@selector(viewDidAppear:) withOptions:AspectPositionAfter|AspectOptionAutomaticRemoval usingBlock:^(id<AspectInfo> aspectInfo, BOOL animated) {
                            AMKLaunchTimeProfiler.sharedInstance.firstScreenTime = CFAbsoluteTimeGetCurrent() + kCFAbsoluteTimeIntervalSince1970;
                            AMKLaunchTimeProfilerInternalLog(@"first screen time: %@", @(AMKLaunchTimeProfiler.sharedInstance.firstScreenTime).amkltp_formattedDateStringForSystemTimeZone);
                            [AMKLaunchTimeProfiler.sharedInstance printAnalysis];
                            [NSNotificationCenter.defaultCenter postNotificationName:AMKLaunchTimeProfilerFirstScreenDidDisplayNotification object:AMKLaunchTimeProfiler.sharedInstance];
                        } error:NULL];
                    }
                } error:NULL];
            }
        } error:NULL];
    });
}

@end
