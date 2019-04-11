//
//  PTAppDelegate.h
//  PooTools
//
//  Created by crazypoo on 05/01/2018.
//  Copyright (c) 2018 crazypoo. All rights reserved.
//

@import UIKit;

#import "PTCheckAppStatus.h"
#import "RCDraggableButton.h"
#import <Masonry/Masonry.h>

@interface PTAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) RCDraggableButton *floatBtn;
+ (PTAppDelegate *)appDelegate;

@end
