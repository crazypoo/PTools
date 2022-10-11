//
//  AMKLaunchTimeProfilerLogsViewController.m
//  AMKLaunchTimeProfiler
//
//  Created by mengxinxin on 2022/3/23.
//

#import "AMKLaunchTimeProfilerLogsViewController.h"
#import "AMKLaunchTimeProfiler.h"
#import "AMKLaunchTimeProfiler+Private.h"
#import <WebKit/WebKit.h>
#import <YYCache/YYCache.h>
#import <YYModel/YYModel.h>
#import <MessageUI/MessageUI.h>
#if defined(WK_TARGET_DEV) || defined(WK_TARGET_QA) || defined(WK_TARGET_ONLINE_QA) || defined(WK_TARGET_BETA) || defined(WK_TARGET_ONLINE)
#import <ZipArchive/ZipArchive.h>
#else
#import <SSZipArchive/SSZipArchive.h>
#endif

@interface AMKLaunchTimeProfilerLogsViewController () <MFMailComposeViewControllerDelegate>
@property(nonatomic, strong, readwrite, nullable) UIBarButtonItem *closeBarButtonItem;
@property(nonatomic, strong, readwrite, nullable) UIBarButtonItem *filterBarButtonItem;
@property(nonatomic, strong, readwrite, nullable) UIBarButtonItem *moreBarButtonItem;
@property(nonatomic, strong, readwrite, nullable) UITextView *textView;
@property(nonatomic, strong, readwrite, nullable) UITextView *statisticsTextView;
@end

@implementation AMKLaunchTimeProfilerLogsViewController

#pragma mark - Dealloc

- (void)dealloc {
    
}

#pragma mark - Init Methods

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        self.title = @"冷启动耗时统计";
    }
    return self;
}

#pragma mark - Life Circle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.leftBarButtonItems = @[self.closeBarButtonItem];
    self.navigationItem.rightBarButtonItems = @[self.moreBarButtonItem/*, self.filterBarButtonItem*/];
    self.view.backgroundColor = self.view.backgroundColor?:[UIColor whiteColor];
    [self reloadLogs:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}

#pragma mark - Getters & Setters

- (UIBarButtonItem *)closeBarButtonItem {
    if (!_closeBarButtonItem) {
        _closeBarButtonItem = [UIBarButtonItem.alloc amkltp_initWithImageType:AMKLaunchTimeProfilerImageTypeNaviBarClose target:self action:@selector(closeBarButtonItemClicked:)];
    }
    return _closeBarButtonItem;
}

- (UIBarButtonItem *)filterBarButtonItem {
    if (!_filterBarButtonItem) {
        _filterBarButtonItem = [UIBarButtonItem.alloc amkltp_initWithImageType:AMKLaunchTimeProfilerImageTypeNaviBarFilter target:self action:@selector(filterBarButtonItemClicked:)];
        [(UIButton *)_filterBarButtonItem.customView setImage:[[UIImage amkltp_imageWithType:AMKLaunchTimeProfilerImageTypeNaviBarFilterSelected] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateSelected];
    }
    return _filterBarButtonItem;
}

- (UIBarButtonItem *)moreBarButtonItem {
    if (!_moreBarButtonItem) {
        _moreBarButtonItem = [UIBarButtonItem.alloc amkltp_initWithImageType:AMKLaunchTimeProfilerImageTypeNaviBarMore target:self action:@selector(moreBarButtonItemClicked:)];
    }
    return _moreBarButtonItem;
}

- (UITextView *)textView {
    if (!_textView) {
        _textView = [UITextView.alloc init];
        _textView.font = [UIFont systemFontOfSize:6];
        _textView.minimumZoomScale = 4 / _textView.font.pointSize;
        _textView.maximumZoomScale = 25 / _textView.font.pointSize;
        _textView.zoomScale = 1;
        _textView.editable = NO;
        _textView.selectable = YES;
        [self.view addSubview:_textView];
    }
    return _textView;
}

- (UITextView *)statisticsTextView {
    if (!_statisticsTextView) {
        _statisticsTextView = [UITextView.alloc init];
        _statisticsTextView.font = [UIFont systemFontOfSize:13];
        _statisticsTextView.minimumZoomScale = 4 / _textView.font.pointSize;
        _statisticsTextView.maximumZoomScale = 25 / _textView.font.pointSize;
        _statisticsTextView.zoomScale = 1;
        _statisticsTextView.editable = NO;
        _statisticsTextView.selectable = YES;
        _statisticsTextView.backgroundColor = [UIColor colorWithRed:243/255.0 green:243/255.0 blue:243/255.0 alpha:1.0];
        [self.view addSubview:_statisticsTextView];
    }
    return _statisticsTextView;
}

#pragma mark - Data & Networking

- (void)reloadLogs:(id)sender {
    NSArray<AMKLaunchTimeProfiler *> *profilers = (id)[YYCache.amkltp_sharedInstance objectForKey:AMKLaunchTimeProfilersCacheKey];
    if (![profilers isKindOfClass:NSArray.class]) {
        self.textView.text = AMKLaunchTimeProfiler.logDisabled ? @"⚠️ 已禁用日志" : [NSString stringWithFormat:@"❌ 日志加载异常：%@", profilers];
        self.statisticsTextView.text = AMKLaunchTimeProfiler.description;
        return;
    }

    __block NSMutableAttributedString *attributedText = [NSMutableAttributedString.alloc init];
    [profilers enumerateObjectsUsingBlock:^(AMKLaunchTimeProfiler * _Nonnull profiler, NSUInteger idx, BOOL * _Nonnull stop) {
        [attributedText appendAttributedString:profiler.attributedDescription];
        [attributedText appendAttributedString:[NSAttributedString.alloc initWithString:@"\n\n\n\n\n\n\n\n\n\n"]];
    }];
    [attributedText addAttributes:@{NSFontAttributeName: self.textView.font} range:NSMakeRange(0, attributedText.length)];
    
    self.textView.attributedText = attributedText.length ? attributedText : [NSAttributedString.alloc initWithString:@"暂无"];
    self.statisticsTextView.text = AMKLaunchTimeProfiler.description;
    [self scrollToBottomAfterDelay:0.1 animated:YES];
}

- (void)copyLogs:(id)sender {
    UIPasteboard.generalPasteboard.string = [NSString stringWithFormat:@"%@\n\n\n\n\n%@", self.textView.text, self.statisticsTextView.text];
}

- (void)clearLogs:(id)sender {
    UIAlertController *alertController = [AMKLaunchTimeProfilerAlertController alertControllerWithTitle:AMKLaunchTimeProfilerAlertControllerTitle message:@"确认清空所有日志吗？\n（此次启动时的相关日志也将被丢弃，并停止记录）" preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:@"清空" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        [AMKLaunchTimeProfiler clearAllLogs];
        [self reloadLogs:sender];
    }]];
    [alertController addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)sendLogs:(id)sender {
    UIAlertController *alertController = [AMKLaunchTimeProfilerAlertController alertControllerWithTitle:AMKLaunchTimeProfilerAlertControllerTitle message:@"请选择发送的方式" preferredStyle:UIAlertControllerStyleActionSheet];
    [alertController addAction:[UIAlertAction actionWithTitle:@"邮件" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self sendLogsWithMail:sender];
    }]];
    [alertController addAction:[UIAlertAction actionWithTitle:@"其他" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self sendLogsWithThirdApp:sender];
    }]];
    [alertController addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)sendLogsWithThirdApp:(id)sender {
    NSError *error = nil;
    
    // 创建临时目录
    NSMutableString *tempDirPath = NSTemporaryDirectory().mutableCopy;
    [tempDirPath appendFormat:@"/%@", NSProcessInfo.processInfo.globallyUniqueString];
    [tempDirPath appendFormat:@"/%@", AMKLaunchTimeProfiler.sharedInstance.bundleName];
    [tempDirPath appendFormat:@" v%@", AMKLaunchTimeProfiler.sharedInstance.bundleShortVersion];
    [tempDirPath appendFormat:@" (%@)", AMKLaunchTimeProfiler.sharedInstance.bundleVersion];
    [tempDirPath appendFormat:@" && %@", AMKLaunchTimeProfiler.sharedInstance.deviceVersion];
    [tempDirPath appendFormat:@" && C %ld", (long)AMKLaunchTimeProfiler.profilerCount];
    [tempDirPath appendFormat:@" - T %.3f s", AMKLaunchTimeProfiler.sharedInstance.totalTimeConsuming];
    [tempDirPath appendFormat:@" - P %.3f s", AMKLaunchTimeProfiler.sharedInstance.preMainTimeConsuming];
    [tempDirPath appendFormat:@" - M %.3f s", AMKLaunchTimeProfiler.sharedInstance.mainTimeConsuming];
    [tempDirPath appendFormat:@" - F %.3f s", AMKLaunchTimeProfiler.sharedInstance.firstScreenTimeConsuming];
    [tempDirPath appendFormat:@" && %@", AMKLaunchTimeProfiler.sharedInstance.identifier];
    NSURL *tempDirURL = [NSURL fileURLWithPath:tempDirPath isDirectory:YES];
    [NSFileManager.defaultManager createDirectoryAtURL:tempDirURL withIntermediateDirectories:YES attributes:nil error:&error];
    
    // 导出到文件
    if (!error) {
        NSString *txtFile = [tempDirPath stringByAppendingFormat:@"/AMKLaunchTimeProfiler_%@.txt", AMKLaunchTimeProfiler.sharedInstance.identifier];
        [self.statisticsTextView.text writeToFile:txtFile atomically:YES encoding:NSUTF8StringEncoding error:&error];
    }
    if (!error) {
        NSString *logsFile = [tempDirPath stringByAppendingFormat:@"/AMKLaunchTimeProfiler_%@.log", AMKLaunchTimeProfiler.sharedInstance.identifier];
        [self.textView.text writeToFile:logsFile atomically:YES encoding:NSUTF8StringEncoding error:&error];
    }
    if (!error) {
        NSArray<AMKLaunchTimeProfiler *> *profilers = (id)[YYCache.amkltp_sharedInstance objectForKey:AMKLaunchTimeProfilersCacheKey];
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:[profilers yy_modelToJSONObject]?:@[] options:NSJSONWritingPrettyPrinted error:nil];
        NSString *jsonString = [NSString.alloc initWithData:jsonData encoding:NSUTF8StringEncoding];
        NSString *jsonFile = [tempDirPath stringByAppendingFormat:@"/AMKLaunchTimeProfiler_%@.json", AMKLaunchTimeProfiler.sharedInstance.identifier];
        [jsonString?:@"" writeToFile:jsonFile atomically:YES encoding:NSUTF8StringEncoding error:&error];
    }
    
    // 压缩文件
    NSString *zipFilePath = [tempDirPath stringByAppendingFormat:@".zip"];
    BOOL zipSuccess = [SSZipArchive createZipFileAtPath:zipFilePath withContentsOfDirectory:tempDirPath];
    if (!zipSuccess) error = [NSError errorWithDomain:AMKLaunchTimeProfilerErrorDomain code:-1 userInfo:@{NSLocalizedDescriptionKey:@"文件压缩失败"}];
    
    // 异常处理
    if (error) {
        UIAlertController *alertController = [AMKLaunchTimeProfilerAlertController alertControllerWithTitle:AMKLaunchTimeProfilerAlertControllerTitle message:[NSString stringWithFormat:@"日志导出失败\n%@", error.localizedDescription] preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
        [self presentViewController:alertController animated:YES completion:nil];
        return;
    }
    
    // 发送
    NSURL *URL = [NSURL fileURLWithPath:zipFilePath];
    UIActivityViewController *activityViewController = [UIActivityViewController.alloc initWithActivityItems:@[URL] applicationActivities:nil];
    [self presentViewController:activityViewController animated:YES completion:nil];
}

- (void)sendLogsWithMail:(id)sender {
    // 功能验证
    if (!MFMailComposeViewController.canSendMail) {
        NSString *message = @"无法发送邮件，请在系统邮件应用中设置邮箱账号";
        UIAlertController *alertController = [AMKLaunchTimeProfilerAlertController alertControllerWithTitle:AMKLaunchTimeProfilerAlertControllerTitle message:message preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
        [self presentViewController:alertController animated:YES completion:nil];
        return;
    }
    
    // 邮件主题
    NSMutableString *subject = [NSMutableString stringWithFormat:@"【APP冷启动耗时统计反馈】"];
    [subject appendFormat:@"来自：%@", AMKLaunchTimeProfiler.sharedInstance.bundleName];
    [subject appendFormat:@" v%@", AMKLaunchTimeProfiler.sharedInstance.bundleShortVersion];
    [subject appendFormat:@" (%@)", AMKLaunchTimeProfiler.sharedInstance.bundleVersion];
    [subject appendFormat:@" && %@", AMKLaunchTimeProfiler.sharedInstance.deviceVersion];

    // 邮件内容
    NSMutableString *messageBody = @"Hi：".mutableCopy;
    [messageBody appendFormat:@"\n\n我正在使用「AMKLaunchTimeProfiler」来统计APP冷启动耗时情况，数据信息如下，详见附件。"];
    [messageBody appendFormat:@"\n\n"];
    [messageBody appendFormat:@"\nAMKLaunchTimeProfiler 信息："];
    [messageBody appendFormat:@"\n--------------------------------------------------"];
    [messageBody appendFormat:@"\n• AMKLaunchTimeProfiler Version: %@", AMKLaunchTimeProfiler.sharedInstance.version];
    [messageBody appendFormat:@"\n• AMKLaunchTimeProfiler Identifier: %@", AMKLaunchTimeProfiler.sharedInstance.identifier];
    [messageBody appendFormat:@"\n\n"];
    [messageBody appendFormat:@"\nAPP 信息："];
    [messageBody appendFormat:@"\n--------------------------------------------------"];
    [messageBody appendFormat:@"\n• BundleId: %@", AMKLaunchTimeProfiler.sharedInstance.bundleId];
    [messageBody appendFormat:@"\n• ShortVersion: %@", AMKLaunchTimeProfiler.sharedInstance.bundleShortVersion];
    [messageBody appendFormat:@"\n• BundleVersion: %@", AMKLaunchTimeProfiler.sharedInstance.bundleVersion];
    [messageBody appendFormat:@"\n• ClientVersion: %@", AMKLaunchTimeProfiler.sharedInstance.clientVersion];
    [messageBody appendFormat:@"\n• DeviceVersion: %@", AMKLaunchTimeProfiler.sharedInstance.deviceVersion];
    [messageBody appendFormat:@"\n• DeviceName: %@", AMKLaunchTimeProfiler.sharedInstance.deviceName];
#   if defined(WK_TARGET_ONLINE)
    [messageBody appendFormat:@"\n• WK_TARGET_ONLINE: %@", @(WK_TARGET_ONLINE)];
#   endif
#   if defined(WK_TARGET_ONLINE_QA)
    [messageBody appendFormat:@"\n• WK_TARGET_ONLINE_QA: %@", @(WK_TARGET_ONLINE_QA)];
#   endif
#   if defined(WK_TARGET_BETA)
    [messageBody appendFormat:@"\n• WK_TARGET_BETA: %@", @(WK_TARGET_BETA)];
#   endif
#   if defined(WK_TARGET_QA)
    [messageBody appendFormat:@"\n• WK_TARGET_QA: %@", @(WK_TARGET_QA)];
#   endif
#   if defined(WK_TARGET_DEV)
    [messageBody appendFormat:@"\n• WK_TARGET_DEV: %@", @(WK_TARGET_DEV)];
#   endif
#   if defined(DEBUG)
    [messageBody appendFormat:@"\n• DEBUG: %@", @(DEBUG)];
#   else
    [messageBody appendFormat:@"\n• DEBUG: %@", @(0)];
#   endif
    [messageBody appendFormat:@"\n\n\n"];
    [messageBody appendFormat:@"%@", AMKLaunchTimeProfiler.description];

    
    // 邮件附件
    NSString *txtFileName = [NSString stringWithFormat:@"AMKLaunchTimeProfiler_%@.txt", AMKLaunchTimeProfiler.sharedInstance.identifier];
    NSData *txtFileData = [self.statisticsTextView.text dataUsingEncoding:NSUTF8StringEncoding];

    NSString *logFileName = [NSString stringWithFormat:@"AMKLaunchTimeProfiler_%@.log", AMKLaunchTimeProfiler.sharedInstance.identifier];
    NSData *logFileData = [self.textView.text dataUsingEncoding:NSUTF8StringEncoding];
    
    NSString *jsonFileName = [NSString stringWithFormat:@"AMKLaunchTimeProfiler_%@.json", AMKLaunchTimeProfiler.sharedInstance.identifier];
    NSArray<AMKLaunchTimeProfiler *> *profilers = (id)[YYCache.amkltp_sharedInstance objectForKey:AMKLaunchTimeProfilersCacheKey];
    if (![profilers isKindOfClass:NSArray.class]) profilers = nil;
    NSData *jsonFileData = [NSJSONSerialization dataWithJSONObject:[profilers yy_modelToJSONObject]?:@[] options:NSJSONWritingPrettyPrinted error:nil];
    
    // 新建邮件
    MFMailComposeViewController *viewController = [MFMailComposeViewController.alloc init];
    [viewController.navigationBar setTintColor:AMKLaunchTimeProfilerTintColor];
    [viewController setMailComposeDelegate:(id<MFMailComposeViewControllerDelegate>)self];
    [viewController setToRecipients:AMKLaunchTimeProfiler.mailRecipients];
    [viewController setSubject:subject];
    [viewController setMessageBody:messageBody isHTML:NO];
    [viewController addAttachmentData:txtFileData?:NSData.new mimeType:@"text/plain" fileName:txtFileName];
    [viewController addAttachmentData:logFileData?:NSData.new mimeType:@"text/plain" fileName:logFileName];
    [viewController addAttachmentData:jsonFileData?:NSData.new mimeType:@"text/plain" fileName:jsonFileName];
    [self presentViewController:viewController animated:YES completion:nil];
}

#pragma mark - Layout Subviews

#pragma mark - Public Methods

- (void)presentingWithAnimated:(BOOL)flag completion:(void (^)(void))completion {
    UINavigationController *navigationController = [AMKLaunchTimeProfilerNavigationController.alloc initWithRootViewController:self];
    navigationController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    navigationController.modalPresentationStyle = UIModalPresentationFullScreen;
    [UIApplication.sharedApplication.delegate.window.rootViewController presentViewController:navigationController animated:flag completion:completion];
}

#pragma mark - Private Methods

- (void)closeBarButtonItemClicked:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)filterBarButtonItemClicked:(id)sender {
    NSLog(@"");
    
    UIButton *filterBarButton = (UIButton *)self.filterBarButtonItem.customView;
    filterBarButton.selected = !filterBarButton.selected;
}

- (void)moreBarButtonItemClicked:(id)sender {
    UIAlertController *alertController = [AMKLaunchTimeProfilerAlertController alertControllerWithTitle:AMKLaunchTimeProfilerAlertControllerTitle message:@"更多操作" preferredStyle:UIAlertControllerStyleActionSheet];
    [alertController addAction:[UIAlertAction actionWithTitle:@"刷新" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self reloadLogs:sender];
    }]];
    [alertController addAction:[UIAlertAction actionWithTitle:@"复制" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self copyLogs:sender];
    }]];
    [alertController addAction:[UIAlertAction actionWithTitle:@"发送" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self sendLogs:sender];
    }]];
    [alertController addAction:[UIAlertAction actionWithTitle:@"清空" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        [self clearLogs:sender];
    }]];
    [alertController addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)scrollToBottomAfterDelay:(NSTimeInterval)afterDelay animated:(BOOL)animated {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(afterDelay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (self.textView.contentOffset.y + self.textView.frame.size.height < self.textView.contentSize.height) {
            [self.textView scrollRectToVisible:CGRectMake(0, self.textView.contentSize.height-1, self.textView.frame.size.width, 1) animated:animated];
            [self scrollToBottomAfterDelay:afterDelay animated:animated];
        }
    });
}

#pragma mark - Notifications

#pragma mark - KVO

#pragma mark - Protocol

#pragma mark MFMailComposeViewControllerDelegate

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(nullable NSError *)error {
    [controller dismissViewControllerAnimated:YES completion:^{
        if (result != MFMailComposeResultFailed) return;
        
        NSString *message = AMKLaunchTimeProfilerStringFromMFMailComposeResult(result);
        message = [NSString stringWithFormat:@"%@\n%@", message?:@"", error.localizedDescription];
        
        UIAlertController *alertController = [AMKLaunchTimeProfilerAlertController alertControllerWithTitle:AMKLaunchTimeProfilerAlertControllerTitle message:message preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:@"好的" style:UIAlertActionStyleCancel handler:nil]];
        [self presentViewController:alertController animated:YES completion:nil];
    }];
}

#pragma mark - Overrides

static CGFloat statisticsTextViewHeight = 130;
- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGRect textViewFrame = self.view.frame;
    textViewFrame.size.height -= statisticsTextViewHeight;
    self.textView.frame = textViewFrame;

    CGRect statisticsTextViewFrame = self.view.frame;
    statisticsTextViewFrame.origin.y = textViewFrame.size.height;
    statisticsTextViewFrame.size.height = statisticsTextViewHeight;
    self.statisticsTextView.frame = statisticsTextViewFrame;
}

#pragma mark - Helper Methods

@end
