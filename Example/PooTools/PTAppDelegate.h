//
//  PTAppDelegate.h
//  PooTools
//
//  Created by crazypoo on 05/01/2018.
//  Copyright (c) 2018 crazypoo. All rights reserved.
//

@import UIKit;

#import <Masonry/Masonry.h>
#import <PooTools/PooTools-Swift.h>

@interface PTAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) PFloatingButton *floatBtn;
@property (strong, nonatomic) LocalConsole *localConsoles;
+ (PTAppDelegate *)appDelegate;

@end
