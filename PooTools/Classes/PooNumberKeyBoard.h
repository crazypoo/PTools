//
//  PooNumberKeyBoard.h
//  numKeyBoard
//
//  Created by crazypoo on 14-4-3.
//  Copyright (c) 2014年 crazypoo. All rights reserved.
//

#import <UIKit/UIKit.h>
@class PooNumberKeyBoard;

@protocol PooNumberKeyBoardDelegate <NSObject>
- (void)numberKeyboard:(PooNumberKeyBoard *)keyboard input:(NSString *)number;
- (void)numberKeyboardBackspace:(PooNumberKeyBoard *)keyboard;
@end

@interface PooNumberKeyBoard : UIView
@property (nonatomic, assign)BOOL haveDog;
@property (nonatomic, assign)id<PooNumberKeyBoardDelegate> delegate;
+(instancetype)pooNumberKeyBoardWithDog:(BOOL)dogpoint;
@end
