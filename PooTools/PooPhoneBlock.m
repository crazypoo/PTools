//
//  PooPhoneBlock.m
//  OMCN
//
//  Created by crazypoo on 15-1-20.
//  Copyright (c) 2015年 doudou. All rights reserved.
//

#import "PooPhoneBlock.h"
#import <UIKit/UIKit.h>

#define kCallSetupTime      3.0

@interface PooPhoneBlock ()
@property (nonatomic, strong) NSDate *callStartTime;

@property (nonatomic, copy) PooCallBlock callBlock;
@property (nonatomic, copy) PooCancelBlock cancelBlock;
@end

@implementation PooPhoneBlock

+ (instancetype)sharedInstance
{
    static PooPhoneBlock *_instance = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        _instance = [[self alloc] init];
    });
    return _instance;
}

+ (BOOL)callPhoneNumber:(NSString *)phoneNumber
                   call:(PooCallBlock)callBlock
                 cancel:(PooCancelBlock)cancelBlock
{
    if ([self validPhone:phoneNumber]) {
        
        PooPhoneBlock *telPrompt = [PooPhoneBlock sharedInstance];
        [telPrompt setNotifications];
        telPrompt.callBlock = callBlock;
        telPrompt.cancelBlock = cancelBlock;
        
        NSString *simplePhoneNumber =
        [[phoneNumber componentsSeparatedByCharactersInSet:
          [[NSCharacterSet decimalDigitCharacterSet] invertedSet]] componentsJoinedByString:@""];
        
        NSString *stringURL = [@"telprompt://" stringByAppendingString:simplePhoneNumber];
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:stringURL]];
        
        return YES;
    }
    return NO;
}

+ (BOOL)validPhone:(NSString*) phoneString
{
    NSTextCheckingType type = [[NSTextCheckingResult phoneNumberCheckingResultWithRange:NSMakeRange(0, phoneString.length)
                                                                            phoneNumber:phoneString] resultType];
    return type == NSTextCheckingTypePhoneNumber;
}


#pragma mark - Notifications

- (void)setNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidEnterBackground:)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidBecomeActive:)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
    
}


#pragma mark - Events

- (void)applicationDidEnterBackground:(NSNotification *)notification
{
    self.callStartTime = [NSDate date];
}

- (void)applicationDidBecomeActive:(NSNotification *)notification
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    if (self.callStartTime != nil) {
        
        if (self.callBlock != nil) {
            self.callBlock(-([self.callStartTime timeIntervalSinceNow]) - kCallSetupTime);
        }
        self.callStartTime = nil;
        
    } else if (self.cancelBlock != nil) {
        
        self.cancelBlock();
    }
}

@end
