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
/*! @brief 代理
 */
@property (nonatomic, weak) id<PSpeechDelegate> delegate;
/*! @brief 创建单例
 */
+ (instancetype)sharedManager;
/*! @brief 运行识别
 */
- (void)startRecognizeWithSuccess:(void(^)(BOOL success))success;
/*! @brief 停止识别
 */
- (void)stopRecognize;
@end
