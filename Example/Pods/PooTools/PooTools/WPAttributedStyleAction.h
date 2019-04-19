//
//  WPAttributedStyleAction.h
//  WPAttributedMarkupDemo
//
//  Created by Nigel Grange on 20/10/2014.
//  Copyright (c) 2014 Nigel Grange. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WPAttributedStyleAction : NSObject

@property (readwrite, copy) void (^action) (void);

- (instancetype)initWithAction:(void (^)(void))action;
+(NSArray*)styledActionWithAction:(void (^)(void))action;
-(NSArray*)styledAction;


@end


