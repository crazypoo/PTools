//
//  SensitiveWordTools
//  此工具类用于对文本中的敏感词进行处理，以及判断文本中是否含有敏感词
//
//  Created by 谭德鹏 on 2017/3/16.
//  Copyright © 2017年 中泰荣科. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SensitiveWordTools : NSObject
/*
 通过单例的方式创建对象
 */
+ (instancetype)sharedInstance;

/*
 * 加载本地的敏感词库
 *
 * @params filepath 敏感词文件的路径
 *
 */
- (void)initFilter:(NSString *)filepath;

/*
 * 将文本中含有的敏感词进行替换
 *
 * @params str 文本字符串
 *
 * @return 过滤完敏感词之后的文本
 *
 */
- (NSString *)filter:(NSString *)str;

/*
 * 判断文本中是否含有敏感词
 *
 * @params str 文本字符串
 *
 * @return 是否含有敏感词
 *
 */
- (BOOL)hasSensitiveWord:(NSString *)str;

@end
