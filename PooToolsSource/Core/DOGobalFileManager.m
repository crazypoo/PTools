//
//  DOGobalFileManager.m
//  Diou
//
//  Created by ken lam on 2021/6/29.
//  Copyright © 2021 DO. All rights reserved.
//

#import "DOGobalFileManager.h"

@implementation DOGobalFileManager

- (NSString *)examineTheFilePathStr:(NSString *)str{
    NSStringEncoding *useEncodeing = nil;     //带编码头的如utf-8等，这里会识别出来
    NSString *body = [NSString stringWithContentsOfFile:str usedEncoding:useEncodeing error:nil];     //识别不到，按GBK编码再解码一次.这里不能先按GB18030解码，否则会出现整个文档无换行bug
    if (!body) {
        body = [NSString stringWithContentsOfFile:str encoding:0x80000632 error:nil];
    }     //还是识别不到，按GB18030编码再解码一次.
    if (!body) {
        body = [NSString stringWithContentsOfFile:str encoding:0x80000631 error:nil];
    }
    return body;
//    //有值代表需要转换  为空表示不需要转换 }
//    if(body){
//        [self.webView loadHTMLString:body baseURL: nil];
//
//    }else{
//        NSURL *filePathUrl = [NSURL fileURLWithPath:self.filePathStr];
//        //  NSLog(@"%@",self.filePathStr);
//        NSURLRequest *request = [NSURLRequest requestWithURL:filePathUrl];
//        [self.webView loadRequest:request];
//
}

- (void)transformEncodingFromFilePath:(NSString *)filePath{
    //调用上述转码方法获取正常字符串
    NSString *body = [self examineTheFilePathStr:filePath];
    //转换为二进制
    NSData *data = [body dataUsingEncoding:NSUTF16StringEncoding];
    //覆盖原来的文件
    [data writeToFile:filePath atomically:YES];
    //此时在读取该文件，就是正常格式啦
}
@end
