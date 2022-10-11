//
//  UIAlertController+AMKLaunchTimeProfiler.m
//  AMKLaunchTimeProfiler
//
//  Created by mengxinxin on 2022/5/9.
//

#import "UIAlertController+AMKLaunchTimeProfiler.h"
#import <AMKLaunchTimeProfiler/AMKLaunchTimeProfiler.h>

@interface AMKLaunchTimeProfilerAlertController ()

@end

@implementation AMKLaunchTimeProfilerAlertController

#pragma mark - Dealloc

- (void)dealloc {
    
}

#pragma mark - Init Methods

#pragma mark - Life Circle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.tintColor = AMKLaunchTimeProfilerTintColor;
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

#pragma mark - Data & Networking

#pragma mark - Layout Subviews

#pragma mark - Public Methods

#pragma mark - Private Methods

#pragma mark - Notifications

#pragma mark - KVO

#pragma mark - Protocol

#pragma mark - Overrides

#pragma mark - Helper Methods

@end
