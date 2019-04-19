//
//  PSpeech.m
//  adasdasdadadasdasdadadadad
//
//  Created by MYX on 2017/4/28.
//  Copyright © 2017年 邓杰豪. All rights reserved.
//

#import "PSpeech.h"
#import <Speech/Speech.h>
#import <AVFoundation/AVFoundation.h>

typedef NS_ENUM(NSUInteger, PSpeechError) {
    PSpeechErrorUnsupportedLocale,
    PSpeechErrorSpeechRecognitionDenied,
    PSpeechErrorManagerIsBusy,
};

static NSString *const PSpeechRequestIdentifier = @"com.crazykidhao.PSpeechRequestIdentifier";
static NSUInteger const bus = 0;

API_AVAILABLE(ios(10.0))
@interface PSpeech () <SFSpeechRecognitionTaskDelegate>
@property (nonatomic, strong) SFSpeechRecognizer *recognizer;
@property (nonatomic, strong) AVAudioEngine *audioEngine;
@property (nonatomic, strong) SFSpeechAudioBufferRecognitionRequest *request;
@property (nonatomic, strong) SFSpeechRecognitionTask *currentTask;
@property (nonatomic, copy) NSString *buffer;
@end

@implementation PSpeech

+ (instancetype)sharedManager {
    static PSpeech *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[self alloc] init];
    });
    return manager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self requestAuthorization];
        [self setup];
    }
    return self;
}

- (void)startRecognizeWithSuccess:(void(^)(BOOL success))success {
    BOOL isRunning = [self isTaskInProgress];
    (isRunning) ? [self informDelegateErrorType:PSpeechErrorManagerIsBusy] : [self performRecognition];
    
    if (success != nil) {
        success(!isRunning);
    }
}

- (void)stopRecognize {
    if ([self isTaskInProgress]) {
        [self.currentTask finish];
        [self.audioEngine stop];
    }
}

- (void)setup {
    if (@available(iOS 10.0, *)) {
        _recognizer = [[SFSpeechRecognizer alloc] initWithLocale:[NSLocale currentLocale]];
        if (!_recognizer) {
            [self informDelegateErrorType:(PSpeechErrorUnsupportedLocale)];
        } else {
            _recognizer.defaultTaskHint = SFSpeechRecognitionTaskHintDictation;
            
            self.request = [[SFSpeechAudioBufferRecognitionRequest alloc] init];
            self.request.interactionIdentifier = PSpeechRequestIdentifier;
            
            self.audioEngine = [[AVAudioEngine alloc] init];
            AVAudioInputNode *node = self.audioEngine.inputNode;
            AVAudioFormat *recordingFormat = [node outputFormatForBus:bus];
            [node installTapOnBus:bus
                       bufferSize:1024
                           format:recordingFormat
                            block:^(AVAudioPCMBuffer * _Nonnull buffer, AVAudioTime * _Nonnull when) {
                                [self.request appendAudioPCMBuffer:buffer];
                            }];
        }
    }
}

- (void)handleAuthorizationStatus:(SFSpeechRecognizerAuthorizationStatus)s  API_AVAILABLE(ios(10.0)){
    switch (s) {
        case SFSpeechRecognizerAuthorizationStatusNotDetermined:
            [self requestAuthorization];
            break;
        case SFSpeechRecognizerAuthorizationStatusDenied:
            [self informDelegateErrorType:(PSpeechErrorSpeechRecognitionDenied)];
            break;
        case SFSpeechRecognizerAuthorizationStatusRestricted:
            break;
        case SFSpeechRecognizerAuthorizationStatusAuthorized: {
        }
            break;
    }
}

- (void)requestAuthorization {
    __weak typeof(self) weakSelf = self;
    if (@available(iOS 10.0, *)) {
        [SFSpeechRecognizer requestAuthorization:^(SFSpeechRecognizerAuthorizationStatus status) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            [strongSelf handleAuthorizationStatus:status];
        }];
    } else {
        // Fallback on earlier versions
    }
}

- (void)performRecognition {
    [self.audioEngine prepare];
    NSError *error = nil;
    if ([self.audioEngine startAndReturnError:&error]) {
        self.currentTask = [self.recognizer recognitionTaskWithRequest:self.request
                                                              delegate:self];
    }
    else
    {
        [self informDelegateError:error];
    }
}

- (BOOL)isTaskInProgress {
    if (@available(iOS 10.0, *)) {
        return (self.currentTask.state == SFSpeechRecognitionTaskStateRunning);
    }
    return NO;
}

- (NSError *)errorWithCode:(NSInteger)code description:(NSString *)description {
    return [NSError errorWithDomain:NSStringFromClass([self class]) code:code userInfo:@{ NSLocalizedDescriptionKey: description }];
}

- (NSError *)errorByType:(PSpeechError)errorType {
    switch (errorType) {
        case PSpeechErrorUnsupportedLocale:
            return [self errorWithCode:-999 description:@"不支持当前语言环境"];
        case PSpeechErrorSpeechRecognitionDenied:
            return [self errorWithCode:100 description:@"识别不出用户语音"];
        case PSpeechErrorManagerIsBusy:
            return [self errorWithCode:500 description:@"识别中"];
    }
}

- (void)informDelegateError:(NSError *)error {
    if ([self.delegate respondsToSelector:@selector(manager:didFailWithError:)]) {
        [self.delegate manager:self didFailWithError:error];
    }
}

- (void)informDelegateErrorType:(PSpeechError)errorType {
    [self informDelegateError:[self errorByType:errorType]];
}

#pragma mark ---------------> SFSpeechRecognitionTaskDelegate
- (void)speechRecognitionTask:(SFSpeechRecognitionTask *)task didFinishRecognition:(SFSpeechRecognitionResult *)recognitionResult  API_AVAILABLE(ios(10.0)){
    self.buffer = recognitionResult.bestTranscription.formattedString;
}

- (void)speechRecognitionTask:(SFSpeechRecognitionTask *)task didFinishSuccessfully:(BOOL)successfully  API_AVAILABLE(ios(10.0)){
    if (!successfully)
    {
        [self informDelegateError:task.error];
    }
    else
    {
        [self.delegate manager:self didRecognizeText:[self.buffer copy]];
    }
}

@end
