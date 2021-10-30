//
//  SensitiveWordTools
//  此工具类用于对文本中的敏感词进行处理，以及判断文本中是否含有敏感词
//
//  Created by 谭德鹏 on 2017/3/16.
//  Copyright © 2017年 中泰荣科. All rights reserved.
//

#import "SensitiveWordTools.h"
#define EXIST @"isExists"

@interface SensitiveWordTools()

@property (nonatomic,strong) NSMutableDictionary *root;

@property(nonatomic,strong)NSMutableArray *rootArray;

@property (nonatomic,assign) BOOL isFilterClose;

@end

@implementation SensitiveWordTools

static SensitiveWordTools *instance;

- (NSMutableArray *)rootArray{
    
    if (!_rootArray) {
        _rootArray = [NSMutableArray array];
    }
    return _rootArray;
}

+ (instancetype)sharedInstance{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc]init];
    });
    return instance;
}

//复写init方法
- (instancetype)init{
    
    if (self) {
        self = [super init];
        
        //加载本地文件
        NSBundle *bundlePath = [NSBundle bundleWithPath:[[NSBundle bundleForClass:[self class]] pathForResource:@"PooTools" ofType:@"bundle"]];
        
        NSString *filePath = [bundlePath pathForResource:@"minganci" ofType:@"txt"];
        [self initFilter:filePath];
        
    }
    return self;
}

#pragma mark-加载本地敏感词库
/*
 * 加载本地的敏感词库
 *
 * @params filepath 敏感词文件的路径
 *
 */
- (void)initFilter:(NSString *)filepath{
    
    self.root = [NSMutableDictionary dictionary];

    NSString *fileString = [[NSString alloc]initWithContentsOfFile:filepath encoding:NSUTF8StringEncoding error:nil];

    [self.rootArray removeAllObjects];
    [self.rootArray addObjectsFromArray:[fileString componentsSeparatedByString:@"|"]];

    for (NSString *str in self.rootArray) {
        //插入字符，构造节点
        [self insertWords:str];
    }
      

}

-(void)insertWords:(NSString *)words{
    NSMutableDictionary *node = self.root;
    
    for (int i = 0; i < words.length; i ++) {
        NSString *word = [words substringWithRange:NSMakeRange(i, 1)];
        
        if (node[word] == nil) {
            node[word] = [NSMutableDictionary dictionary];
        }
        
        node = node[word];
    }
    
    //敏感词最后一个字符标识
    node[EXIST] = [NSNumber numberWithInt:1];
}

#pragma mark-将文本中含有的敏感词进行替换
/*
 * 将文本中含有的敏感词进行替换
 *
 * @params str 文本字符串
 *
 * @return 过滤完敏感词之后的文本
 *
 */
- (NSString *)filter:(NSString *)str{
    
    if (self.isFilterClose || !self.root) {
        return str;
    }
    
    NSMutableString *result = result = [str mutableCopy];
    
    for (int i = 0; i < str.length; i ++) {
        NSString *subString = [str substringFromIndex:i];
        NSMutableDictionary *node = [self.root mutableCopy] ;
        int num = 0;
        
        for (int j = 0; j < subString.length; j ++) {
            NSString *word = [subString substringWithRange:NSMakeRange(j, 1)];
            
            if (node[word] == nil) {
                break;
            }else{
                num ++;
                node = node[word];
            }
            
            //敏感词匹配成功
            if ([node[EXIST]integerValue] == 1) {
                
                NSMutableString *symbolStr = [NSMutableString string];
                for (int k = 0; k < num; k ++) {
                    [symbolStr appendString:@"*"];
                }
                
                [result replaceCharactersInRange:NSMakeRange(i, num) withString:symbolStr];
                
                i += j;
                break;
            }
        }
    }
    
    return result;
}

- (void)freeFilter{
    self.root = nil;
}

- (void)stopFilter:(BOOL)b{
    self.isFilterClose = b;
}

#pragma mark-判断文本中是否含有敏感词
/*
 * 判断文本中是否含有敏感词
 *
 * @params str 文本字符串
 *
 * @return 是否含有敏感词
 *
 */
- (BOOL)hasSensitiveWord:(NSString *)str{
    
    if (self.isFilterClose || !self.root) {
        return NO;
    }
    
    NSMutableString *result = result = [str mutableCopy];
    
    for (int i = 0; i < str.length; i ++) {
        NSString *subString = [str substringFromIndex:i];
        NSMutableDictionary *node = [self.root mutableCopy] ;
        int num = 0;
        
        for (int j = 0; j < subString.length; j ++) {
            NSString *word = [subString substringWithRange:NSMakeRange(j, 1)];
            
            if (node[word] == nil) {
                break;
            }else{
                num ++;
                node = node[word];
            }
            
            //敏感词匹配成功
            if ([node[EXIST]integerValue] == 1) {
                return YES;
            }
        }
    }

    return NO;
}


@end
