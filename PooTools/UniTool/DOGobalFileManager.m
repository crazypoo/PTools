//
//  DOGobalFileManager.m
//  Diou
//
//  Created by ken lam on 2021/6/29.
//  Copyright © 2021 DO. All rights reserved.
//

#import "DOGobalFileManager.h"

@implementation DOGobalFileManager

+(NSString *)gobalCacheFileURL
{
    NSString *pathDocuments = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *fileMainPath = [NSString stringWithFormat:@"%@/APPCache/", pathDocuments];
    return fileMainPath;
}

+(void)createCacheFilePath
{
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    if (![[NSFileManager defaultManager] fileExistsAtPath:[DOGobalFileManager gobalCacheFileURL]])
    {
        [fileManager createDirectoryAtPath:[DOGobalFileManager gobalCacheFileURL] withIntermediateDirectories:YES attributes:nil error:nil];
    }
}

+(NSString *)gobalShareFileURL
{
    NSString *pathDocuments = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *fileMainPath = [NSString stringWithFormat:@"%@/Excel/", pathDocuments];
    return fileMainPath;
}

+(NSString *)gobalLogFileURL
{
    NSString *pathDocuments = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *fileMainPath = [NSString stringWithFormat:@"%@/Log/", pathDocuments];
    return fileMainPath;
}

+(BOOL)isFileExist:(NSString *)fileName withFilePath:(NSString *)filePaths
{
    NSString *filePath = [filePaths stringByAppendingPathComponent:fileName];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL result = [fileManager fileExistsAtPath:filePath];
    return result;
}

+(void)createExcelFilePath
{
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    if (![[NSFileManager defaultManager] fileExistsAtPath:[DOGobalFileManager gobalShareFileURL]])
    {
        [fileManager createDirectoryAtPath:[DOGobalFileManager gobalShareFileURL] withIntermediateDirectories:YES attributes:nil error:nil];
    }
}

+(void)createLogFilePath
{
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    if (![[NSFileManager defaultManager] fileExistsAtPath:[DOGobalFileManager gobalLogFileURL]])
    {
        [fileManager createDirectoryAtPath:[DOGobalFileManager gobalLogFileURL] withIntermediateDirectories:YES attributes:nil error:nil];
    }
}

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

/**
 对文件重命名

 @param filePath 旧路径
 @return 新路径
 */
+ (NSString *)p_setupFileRename:(NSString *)filePath
{
    //获取文件名： 视频.MP4
    NSString *lastPathComponent = [filePath lastPathComponent];
    //获取后缀：MP4
    NSString *pathExtension = [filePath pathExtension];
    //用传过来的路径创建新路径 首先去除文件名
    NSString *pathNew = [filePath stringByReplacingOccurrencesOfString:lastPathComponent withString:@""];
    //然后拼接新文件名：新文件名为当前的：年月日时分秒 yyyyMMddHHmmss
    NSString *moveToPath = [NSString stringWithFormat:@"%@%@.%@",pathNew,[DOGobalFileManager htmi_getCurrentTime],pathExtension];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    //通过移动该文件对文件重命名
    BOOL isSuccess = [fileManager moveItemAtPath:filePath toPath:moveToPath error:nil];
    if (isSuccess) {
        NSLog(@"rename success");
    }else{
        NSLog(@"rename fail");
    }
    
    return moveToPath;
}

/**
 获取当地时间
 
 @return 获取当地时间
 */
+ (NSString *)htmi_getCurrentTime {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyyMMddHHmmss"];
    NSString *dateTime = [formatter stringFromDate:[NSDate date]];
    return dateTime;
}

+(void)test:(NSURL *)url
{
    NSString *fileNameStr = [url lastPathComponent];
    NSString *Doc = [[NSHomeDirectory() stringByAppendingPathComponent:@"Documents/localFile"] stringByAppendingPathComponent:fileNameStr];
    NSData *data = [NSData dataWithContentsOfURL:url];
    [data writeToFile:Doc atomically:YES];
}

@end
