//
//  PSpeech.h
//  adasdasdadadasdasdadadadad
//
//  Created by MYX on 2017/4/28.
//  Copyright © 2017年 邓杰豪. All rights reserved.
//

#import <Foundation/Foundation.h>
@class PSpeech;
@protocol PSpeechDelegate <NSObject>
- (void)manager:(PSpeech *)manager didRecognizeText:(NSString *)text;
@optional
- (void)manager:(PSpeech *)manager didFailWithError:(NSError *)error;
@end

@interface PSpeech : NSObject
@property (nonatomic, weak) id<PSpeechDelegate> delegate;
+ (instancetype)sharedManager;
- (void)startRecognizeWithSuccess:(void(^)(BOOL success))success;
- (void)stopRecognize;
@end
