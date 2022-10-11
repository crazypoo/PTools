//
//  AMKLaunchTimeProfiler.m
//  AMKLaunchTimeProfiler
//
//  Created by mengxinxin on 2022/3/22.
//

#import "AMKLaunchTimeProfiler.h"
#import "AMKLaunchTimeProfiler+Private.h"
#import "AMKLaunchTimeProfilerLogModel.h"
#import <YYCache/YYCache.h>
#import <YYModel/YYModel.h>
#import <sys/sysctl.h>
#import <mach/mach.h>

@interface AMKLaunchTimeProfiler ()

// 全局设置
@property(nonatomic, assign, readwrite, class) BOOL logDisabled;
@property(atomic,    strong, readonly, nonnull, class) dispatch_queue_t logsCacheQueue; //!< log的持久化队列（串行）
@property(nonatomic, strong, readonly, nonnull, class) UISwipeGestureRecognizer *gestureRecognizer; //!< 添加 轻扫手势，以显示「启动耗时日志」页面，默认 不可用

// 组件信息
@property(nonatomic, strong, readwrite, nonnull) NSString *identifier;
@property(nonatomic, strong, readwrite, nonnull) NSString *version;
@property(nonatomic, strong, readwrite, nonnull) NSMutableArray<AMKLaunchTimeProfilerLogModel *> *logs;

// APP信息
@property(nonatomic, strong, readwrite, nonnull) NSString *bundleName;
@property(nonatomic, strong, readwrite, nonnull) NSString *bundleId;
@property(nonatomic, strong, readwrite, nonnull) NSString *bundleShortVersion;
@property(nonatomic, strong, readwrite, nonnull) NSString *bundleVersion;
@property(nonatomic, strong, readwrite, nonnull) NSString *clientVersion;
@property(nonatomic, strong, readwrite, nonnull) NSString *deviceVersion;
@property(nonatomic, strong, readwrite, nonnull) NSString *deviceName;

// 关键时间点
@property(nonatomic, assign, readwrite) NSTimeInterval processStartTime;
@property(nonatomic, assign, readwrite) NSTimeInterval mainTime;
@property(nonatomic, assign, readwrite) NSTimeInterval didFinishLaunchingTime;
@property(nonatomic, assign, readwrite) NSTimeInterval firstScreenTime;

// 各阶段耗时
@property(nonatomic, assign, readwrite) NSTimeInterval preMainTimeConsuming;
@property(nonatomic, assign, readwrite) NSTimeInterval mainTimeConsuming;
@property(nonatomic, assign, readwrite) NSTimeInterval firstScreenTimeConsuming;
@property(nonatomic, assign, readwrite) NSTimeInterval totalTimeConsuming;

@end

@implementation AMKLaunchTimeProfiler

void static __attribute__((constructor)) before_main() {
    if (AMKLaunchTimeProfiler.sharedInstance.mainTime == 0) {
        AMKLaunchTimeProfiler.sharedInstance.mainTime = CFAbsoluteTimeGetCurrent() + kCFAbsoluteTimeIntervalSince1970;
        AMKLaunchTimeProfilerInternalLog(@"main time: %@", @(AMKLaunchTimeProfiler.sharedInstance.mainTime).amkltp_formattedDateStringForSystemTimeZone);
    }
}

NSTimeInterval AMKLaunchTimeProfilerGetProcessStartTime(void) {
    if (AMKLaunchTimeProfiler.sharedInstance.processStartTime == 0) {
        struct kinfo_proc proc;
        int pid = NSProcessInfo.processInfo.processIdentifier;
        int cmd[4] = {CTL_KERN, KERN_PROC, KERN_PROC_PID, pid};
        size_t size = sizeof(proc);
        if (sysctl(cmd, sizeof(cmd)/sizeof(*cmd), &proc, &size, NULL, 0) == 0) {
            struct timeval starttime = proc.kp_proc.p_un.__p_starttime;
            AMKLaunchTimeProfiler.sharedInstance.processStartTime = [NSString stringWithFormat:@"%ld.%d", starttime.tv_sec /*(s)*/, starttime.tv_usec /*(ms)*/].doubleValue;
            AMKLaunchTimeProfilerInternalLog(@"process-start time: %@", @(AMKLaunchTimeProfiler.sharedInstance.processStartTime).amkltp_formattedDateStringForSystemTimeZone);
        }
    }
    return AMKLaunchTimeProfiler.sharedInstance.processStartTime;
}

#pragma mark - Init Methods

+ (void)initialize {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        AMKLaunchTimeProfilerGetProcessStartTime();
    });
}

#pragma mark - Getters & Setters

static BOOL _debugEnable;

+ (BOOL)debugEnable {
    return _debugEnable;
}

+ (void)setDebugEnable:(BOOL)debugEnable {
    _debugEnable = debugEnable;
    self.gestureRecognizer.enabled = _debugEnable;
}

static BOOL _logDisabled;

+ (BOOL)logDisabled {
    return _logDisabled;
}

+ (void)setLogDisabled:(BOOL)logDisabled {
    _logDisabled = logDisabled;
}

+ (dispatch_queue_t)logsCacheQueue {
    static dispatch_queue_t logsCacheQueue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *label = [AMKLaunchTimeProfilerBundleId stringByAppendingString:@".logs-cache"];
        logsCacheQueue = dispatch_queue_create(label.UTF8String, DISPATCH_QUEUE_SERIAL);
    });
    return logsCacheQueue;
}

+ (UISwipeGestureRecognizer *)gestureRecognizer {
    static UISwipeGestureRecognizer *gestureRecognizer;
    if (!gestureRecognizer && UIApplication.sharedApplication.delegate.window) {
        gestureRecognizer = [UISwipeGestureRecognizer.alloc initWithTarget:self action:@selector(gotoLaunchTimeProfilerLogsViewController:)];
        gestureRecognizer.direction = UISwipeGestureRecognizerDirectionLeft;
        gestureRecognizer.numberOfTouchesRequired = 2;
        gestureRecognizer.enabled = NO;
        [UIApplication.sharedApplication.delegate.window addGestureRecognizer:gestureRecognizer];
    }
    return gestureRecognizer;
}

static NSUInteger _maxCountOfProfilers = 30;

+ (NSUInteger)maxCountOfProfilers {
    return _maxCountOfProfilers;
}

+ (void)setMaxCountOfProfilers:(NSUInteger)maxCountOfProfilers {
    _maxCountOfProfilers = MAX(1, maxCountOfProfilers);
    
    dispatch_async(self.logsCacheQueue, ^{
        NSMutableArray<AMKLaunchTimeProfiler *> *profilers = [NSMutableArray arrayWithArray:(NSArray *)[YYCache.amkltp_sharedInstance objectForKey:AMKLaunchTimeProfilersCacheKey] ?: @[]];
        if (profilers.count > _maxCountOfProfilers) {
            [profilers removeObjectsInRange:NSMakeRange(0, profilers.count-_maxCountOfProfilers)];
            [YYCache.amkltp_sharedInstance setObject:profilers forKey:AMKLaunchTimeProfilersCacheKey];
        }
    });
}

static NSArray *_mailRecipients;

+ (NSArray<NSString *> *)mailRecipients {
    return _mailRecipients;
}

+ (void)setMailRecipients:(NSArray<NSString *> *)mailRecipients {
    _mailRecipients = mailRecipients.copy;
}

+ (AMKLaunchTimeProfiler *)sharedInstance {
    static AMKLaunchTimeProfiler *sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
        sharedInstance.identifier = NSProcessInfo.processInfo.globallyUniqueString.amkltp_md5String;
        sharedInstance.version = AMKLaunchTimeProfilerVersion;
        sharedInstance.bundleName = NSBundle.mainBundle.infoDictionary[@"CFBundleName"];
        sharedInstance.bundleId = NSBundle.mainBundle.bundleIdentifier;
        sharedInstance.bundleShortVersion = NSBundle.mainBundle.infoDictionary[@"CFBundleShortVersionString"];
        sharedInstance.bundleVersion = NSBundle.mainBundle.infoDictionary[@"CFBundleVersion"];
        sharedInstance.clientVersion = NSBundle.mainBundle.infoDictionary[@"sys-clientVersion"];
        sharedInstance.deviceVersion = [NSString stringWithFormat:@"%@ with %@ %@", UIDevice.amkltp_platformString, UIDevice.currentDevice.systemName, UIDevice.currentDevice.systemVersion];
        sharedInstance.deviceName = UIDevice.currentDevice.name;
    
        dispatch_async(self.logsCacheQueue, ^{
            NSMutableArray<AMKLaunchTimeProfiler *> *profilers = [NSMutableArray arrayWithArray:(NSArray *)[YYCache.amkltp_sharedInstance objectForKey:AMKLaunchTimeProfilersCacheKey] ?: @[]];
            [profilers removeObject:sharedInstance];
            [profilers addObject:sharedInstance];
            [YYCache.amkltp_sharedInstance setObject:profilers forKey:AMKLaunchTimeProfilersCacheKey];
        });
    });
    return sharedInstance;
}

- (NSTimeInterval)preMainTimeConsuming {
    if (!_preMainTimeConsuming && _mainTime && _processStartTime) {
        _preMainTimeConsuming = _mainTime - _processStartTime;
    }
    return _preMainTimeConsuming;
}

- (NSTimeInterval)mainTimeConsuming {
    if (!_mainTimeConsuming && _didFinishLaunchingTime && _mainTime) {
        _mainTimeConsuming = _didFinishLaunchingTime - _mainTime;
    }
    return _mainTimeConsuming;
}

- (NSTimeInterval)firstScreenTimeConsuming {
    if (!_firstScreenTimeConsuming && _firstScreenTime && _didFinishLaunchingTime) {
        _firstScreenTimeConsuming = _firstScreenTime - _didFinishLaunchingTime;
    }
    return _firstScreenTimeConsuming;
}

- (NSTimeInterval)totalTimeConsuming {
    if (!_totalTimeConsuming && _firstScreenTime && _processStartTime) {
        _totalTimeConsuming = _firstScreenTime - _processStartTime;
    }
    return _totalTimeConsuming;
}

- (NSMutableArray<AMKLaunchTimeProfilerLogModel *> *)logs {
    if (!_logs) {
        _logs = @[].mutableCopy;
    }
    return _logs;
}

#pragma mark - Data & Networking

#pragma mark - Public Methods

+ (void)clearAllLogs {
    AMKLaunchTimeProfiler.logDisabled = YES;
#   pragma clang diagnostic push
#   pragma clang diagnostic ignored "-Wundeclared-selector"
    [AMKLaunchTimeProfiler performSelector:@selector(clearStatistics)];
#   pragma clang diagnostic pop
    [YYCache.amkltp_sharedInstance removeObjectForKey:AMKLaunchTimeProfilersCacheKey];
}

- (void)clearAllLogs {
    [self.logs removeAllObjects];
    
    dispatch_async(self.class.logsCacheQueue, ^{
        NSMutableArray<AMKLaunchTimeProfiler *> *profilers = [NSMutableArray arrayWithArray:(NSArray *)[YYCache.amkltp_sharedInstance objectForKey:AMKLaunchTimeProfilersCacheKey] ?: @[]];
        [profilers removeObject:self];
        [profilers addObject:self];
        [YYCache.amkltp_sharedInstance setObject:profilers forKey:AMKLaunchTimeProfilersCacheKey];
    });
}

- (void)logWithFunction:(const char *)function line:(NSInteger)line string:(NSString *)format, ... {
    static NSTimeInterval lastLogTimeInterval = 0;
    if (AMKLaunchTimeProfiler.logDisabled) return;
    
    va_list arguments;
    va_start(arguments, format);
    NSString *string = [NSString.alloc initWithFormat:format arguments:arguments];
    va_end(arguments);
    
    // 构建日志
    AMKLaunchTimeProfilerLogModel *logModel = [AMKLaunchTimeProfilerLogModel.alloc init];
    logModel.timeInterval = CFAbsoluteTimeGetCurrent() + kCFAbsoluteTimeIntervalSince1970 - self.processStartTime;
    logModel.timeDelta = logModel.timeInterval - lastLogTimeInterval;
    logModel.function = [NSString stringWithCString:function ?: "__INTERNAL__" encoding:NSUTF8StringEncoding];
    logModel.line = line;
    logModel.string = string;
    lastLogTimeInterval = logModel.timeInterval;
    
    // 打印日志
    [self debugLog:@"%@", logModel.description];
    
    // 缓存日志
    [self.logs addObject:logModel];
    dispatch_async(self.class.logsCacheQueue, ^{
        NSMutableArray<AMKLaunchTimeProfiler *> *profilers = [NSMutableArray arrayWithArray:(NSArray *)[YYCache.amkltp_sharedInstance objectForKey:AMKLaunchTimeProfilersCacheKey] ?: @[]];
        [profilers removeObject:self];
        [profilers addObject:self];
        if (!profilers) printf("❌❌❌❌❌❌❌❌❌❌");
        [YYCache.amkltp_sharedInstance setObject:profilers?:@[] forKey:AMKLaunchTimeProfilersCacheKey];
    });
}

#pragma mark - Private Methods

+ (void)gotoLaunchTimeProfilerLogsViewController:(id)sender {
    [AMKLaunchTimeProfilerLogsViewController.new presentingWithAnimated:YES completion:nil];
}

- (void)printAnalysis {
    AMKLaunchTimeProfilerInternalLog(@"----------------------------------------------------------------------");
    AMKLaunchTimeProfilerInternalLog(@"total time consuming: %.3f s", self.totalTimeConsuming);
    AMKLaunchTimeProfilerInternalLog(@"pre-main time consuming: %.3f s (%.2f%%)", self.preMainTimeConsuming, self.preMainTimeConsuming/self.totalTimeConsuming*100);
    AMKLaunchTimeProfilerInternalLog(@"main time consuming: %.3f s (%.2f%%)", self.mainTimeConsuming, self.mainTimeConsuming/self.totalTimeConsuming*100);
    AMKLaunchTimeProfilerInternalLog(@"first screen time consuming: %.3f s (%.2f%%)", self.firstScreenTimeConsuming, self.firstScreenTimeConsuming/self.totalTimeConsuming*100);
    AMKLaunchTimeProfilerInternalLog(@"----------------------------------------------------------------------");
}

#pragma mark - Notifications

#pragma mark - KVO

#pragma mark - Protocol

#pragma mark NSCoding

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [self yy_modelEncodeWithCoder:aCoder];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super init]; return [self yy_modelInitWithCoder:aDecoder];
}

#pragma mark NSCopying

- (id)copyWithZone:(NSZone *)zone {
    return [self yy_modelCopy];
}

#pragma mark - Overrides

- (NSUInteger)hash {
    return [self yy_modelHash];
}

- (BOOL)isEqual:(id)object {
    return [object isKindOfClass:AMKLaunchTimeProfiler.class] && [self.identifier isEqualToString:[object identifier]];
}

- (NSString *)description {
    return [self attributedDescription:NO].string;
}

- (NSMutableAttributedString *)attributedDescription {
    return [self attributedDescription:YES];
}

- (NSMutableAttributedString *)attributedDescription:(BOOL)attributed {
    NSMutableAttributedString *attributedDescription = [NSMutableAttributedString.alloc init];
    [attributedDescription appendAttributedString:[NSAttributedString.alloc initWithString:[NSString stringWithFormat:@"======================================================================"]]];
    [attributedDescription appendAttributedString:[NSAttributedString.alloc initWithString:[NSString stringWithFormat:@"\nAMKLaunchTimeProfiler id: %@", self.identifier]]];
    [attributedDescription appendAttributedString:[NSAttributedString.alloc initWithString:[NSString stringWithFormat:@"\nAMKLaunchTimeProfiler version: %@", self.version]]];
    [attributedDescription appendAttributedString:[NSAttributedString.alloc initWithString:[NSString stringWithFormat:@"\nBundle id: %@", self.bundleId]]];
    [attributedDescription appendAttributedString:[NSAttributedString.alloc initWithString:[NSString stringWithFormat:@"\nBundle short Version: %@", self.bundleShortVersion]]];
    [attributedDescription appendAttributedString:[NSAttributedString.alloc initWithString:[NSString stringWithFormat:@"\nBundle version: %@", self.bundleVersion]]];
    [attributedDescription appendAttributedString:[NSAttributedString.alloc initWithString:[NSString stringWithFormat:@"\nClient Version: %@", self.clientVersion]]];
    [attributedDescription appendAttributedString:[NSAttributedString.alloc initWithString:[NSString stringWithFormat:@"\nDevice Version: %@", self.deviceVersion]]];
    [attributedDescription appendAttributedString:[NSAttributedString.alloc initWithString:[NSString stringWithFormat:@"\nDevice Name: %@", self.deviceName]]];
    [attributedDescription appendAttributedString:[NSAttributedString.alloc initWithString:[NSString stringWithFormat:@"\n"]]];
    [attributedDescription appendAttributedString:[NSAttributedString.alloc initWithString:[NSString stringWithFormat:@"\n----------------------------------------------------------------------"]]];
    [attributedDescription appendAttributedString:[NSAttributedString.alloc initWithString:[NSString stringWithFormat:@"\n%30s: %@", "process-start time", @(self.processStartTime).amkltp_formattedDateStringForSystemTimeZone]]];
    [attributedDescription appendAttributedString:[NSAttributedString.alloc initWithString:[NSString stringWithFormat:@"\n%30s: %.3f s ", "total time consuming", self.totalTimeConsuming]]];
    [attributedDescription appendAttributedString:[NSAttributedString.alloc initWithString:[NSString stringWithFormat:@"\n%30s: %.3f s (%.2f%%)", "pre-main time consuming", self.preMainTimeConsuming, self.preMainTimeConsuming/self.totalTimeConsuming*100]]];
    [attributedDescription appendAttributedString:[NSAttributedString.alloc initWithString:[NSString stringWithFormat:@"\n%30s: %.3f s (%.2f%%)", "main time consuming", self.mainTimeConsuming, self.mainTimeConsuming/self.totalTimeConsuming*100]]];
    [attributedDescription appendAttributedString:[NSAttributedString.alloc initWithString:[NSString stringWithFormat:@"\n%30s: %.3f s (%.2f%%)", "first screen time consuming", self.firstScreenTimeConsuming, self.firstScreenTimeConsuming/self.totalTimeConsuming*100]]];
    [attributedDescription appendAttributedString:[NSAttributedString.alloc initWithString:[NSString stringWithFormat:@"\n"]]];
    [attributedDescription appendAttributedString:[NSAttributedString.alloc initWithString:[NSString stringWithFormat:@"\n----------------------------------------------------------------------"]]];
    [self.logs enumerateObjectsUsingBlock:^(AMKLaunchTimeProfilerLogModel * _Nonnull log, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *string = [NSString stringWithFormat:@"\n%@", log.description];
        NSDictionary *attributes = (log.timeInterval<self.totalTimeConsuming && log.timeDelta>=0.05 && ![log.function isEqualToString:@"__INTERNAL__"]) ? @{NSForegroundColorAttributeName: UIColor.redColor} : nil;
        NSAttributedString *attributedString = [NSAttributedString.alloc initWithString:string attributes:attributes];
        [attributedDescription appendAttributedString:attributedString];
    }];
    return attributedDescription;
}

- (NSString *)debugDescription {
    return [self yy_modelDescription];
}

#pragma mark - Helper Methods

- (void)debugLog:(NSString *)format, ... {
#   if defined(DEBUG)
    va_list arguments;
    va_start(arguments, format);
    NSString *string = [NSString.alloc initWithFormat:format arguments:arguments];
    va_end(arguments);
    fprintf(stderr, "%s\n", string.UTF8String);
#   endif
}

@end


#pragma mark - 启动耗时统计信息

@implementation AMKLaunchTimeProfiler (Statistics)
static NSInteger profilerCount = 0;
static NSTimeInterval preMainTimeConsuming = 0;
static NSTimeInterval mainTimeConsuming = 0;
static NSTimeInterval firstScreenTimeConsuming = 0;
static NSTimeInterval totalTimeConsuming = 0;

+ (void)statistics {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSArray<AMKLaunchTimeProfiler *> *profilers = [NSArray arrayWithArray:(NSArray *)[YYCache.amkltp_sharedInstance objectForKey:AMKLaunchTimeProfilersCacheKey] ?: @[]];
        profilers = [profilers objectsAtIndexes:[profilers indexesOfObjectsPassingTest:^BOOL(AMKLaunchTimeProfiler * _Nonnull profiler, NSUInteger idx, BOOL * _Nonnull stop) {
            if (profiler.preMainTimeConsuming <= 0) return NO;
            if (profiler.mainTimeConsuming <= 0) return NO;
            if (profiler.firstScreenTimeConsuming <= 0) return NO;
            if (profiler.totalTimeConsuming <= 0) return NO;
            return YES;
        }]];
        if (!profilers.count) return;
        
        [profilers enumerateObjectsUsingBlock:^(AMKLaunchTimeProfiler * _Nonnull profiler, NSUInteger idx, BOOL * _Nonnull stop) {
            preMainTimeConsuming += profiler.preMainTimeConsuming;
            mainTimeConsuming += profiler.mainTimeConsuming;
            firstScreenTimeConsuming += profiler.firstScreenTimeConsuming;
            totalTimeConsuming += profiler.totalTimeConsuming;
        }];
        profilerCount = profilers.count;
        preMainTimeConsuming = preMainTimeConsuming / profilerCount;
        mainTimeConsuming = mainTimeConsuming / profilerCount;
        firstScreenTimeConsuming = firstScreenTimeConsuming / profilerCount;
        totalTimeConsuming = totalTimeConsuming / profilerCount;
    });
}

+ (void)clearStatistics {
    profilerCount = 0;
    preMainTimeConsuming = 0;
    mainTimeConsuming = 0;
    firstScreenTimeConsuming = 0;
    totalTimeConsuming = 0;
}

+ (NSInteger)profilerCount {
    [self statistics];
    return profilerCount;
}

+ (NSTimeInterval)preMainTimeConsuming {
    [self statistics];
    return preMainTimeConsuming;
}

+ (NSTimeInterval)mainTimeConsuming {
    [self statistics];
    return mainTimeConsuming;
}

+ (NSTimeInterval)firstScreenTimeConsuming {
    [self statistics];
    return firstScreenTimeConsuming;
}

+ (NSTimeInterval)totalTimeConsuming {
    [self statistics];
    return totalTimeConsuming;
}

+ (NSString *)description {
    if (!self.profilerCount) return @"暂无有效数据";
    
    NSMutableString *description = [NSMutableString.alloc initWithFormat:@"%ld 次有效数据的平均数：", (long)self.profilerCount];
    [description appendFormat:@"\n--------------------------------------------------"];
    [description appendFormat:@"\n%30s: %.3f s ", "total time consuming", self.totalTimeConsuming];
    [description appendFormat:@"\n%30s: %.3f s (%.2f%%)", "pre-main time consuming", self.preMainTimeConsuming, self.preMainTimeConsuming/self.totalTimeConsuming*100];
    [description appendFormat:@"\n%30s: %.3f s (%.2f%%)", "main time consuming", self.mainTimeConsuming, self.mainTimeConsuming/self.totalTimeConsuming*100];
    [description appendFormat:@"\n%30s: %.3f s (%.2f%%)", "first screen time consuming", self.firstScreenTimeConsuming, self.firstScreenTimeConsuming/self.totalTimeConsuming*100];
    return description;
}

@end
