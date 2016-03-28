//
//  PooNumberKeyBoard.h
//  numKeyBoard
//
//  Created by crazypoo on 14-4-3.
//  Copyright (c) 2014年 crazypoo. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol PooNumberKeyBoardDelegate <NSObject>
- (void) numberKeyboardInput:(NSInteger) number;
- (void) numberKeyboardBackspace;
- (void) dismissKeyBoard;
@end

@interface PooNumberKeyBoard : UIView
@property (nonatomic, assign)id<PooNumberKeyBoardDelegate> delegate;
+(instancetype)pooNumberKeyBoard;
@end
