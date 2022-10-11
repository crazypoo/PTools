//
//  AMKLaunchTimeProfilerLogModel.h
//  AMKLaunchTimeProfiler
//
//  Created by mengxinxin on 2022/5/9.
//

#import <Foundation/Foundation.h>

/// Log 的相关信息
@interface AMKLaunchTimeProfilerLogModel : NSObject <NSCoding, NSCopying>
@property (nonatomic, assign, readwrite) NSTimeInterval timeDelta; //!< 与前一条log的时间差，便于查看具体耗时
@property (nonatomic, assign, readwrite) NSTimeInterval timeInterval; //!< 相对时间
@property (nonatomic, strong, readwrite) NSString *function; //!< 所在方法
@property (nonatomic, assign, readwrite) NSInteger line; //!< 对应行数
@property (nonatomic, strong, readwrite) NSString *string; //!< 内容
@end
