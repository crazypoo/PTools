//
//  PVideoConfig.m
//  XMNaio_Client
//
//  Created by MYX on 2017/5/16.
//  Copyright © 2017年 E33QU5QCP3.com.xnmiao.customer.XMNiao-Customer. All rights reserved.
//

#import "PVideoConfig.h"
#import <AVFoundation/AVFoundation.h>
#import <Masonry/Masonry.h>

void kz_dispatch_after(float time, dispatch_block_t block)
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(time * NSEC_PER_SEC)), dispatch_get_main_queue(), block);
}

@implementation PVideoConfig

+ (CGRect)viewFrameWithType:(PVideoViewShowType)type video_W_H:(CGFloat)video_W_H withControViewHeight:(CGFloat)controViewHeight
{
    if (type == PVideoViewShowTypeSingle)
    {
        return [UIScreen mainScreen].bounds;
    }
    CGFloat viewHeight = kSCREEN_WIDTH/video_W_H + 20 + controViewHeight;
    return CGRectMake(0, kSCREEN_HEIGHT - viewHeight, kSCREEN_WIDTH, viewHeight);
}

+ (CGSize)videoViewDefaultSizeWithVideo_W_H:(CGFloat)video_W_H
{
    return CGSizeMake(kSCREEN_WIDTH, kSCREEN_WIDTH/video_W_H);
}

+ (CGSize)defualtVideoSizeWithVideo_W_H:(CGFloat)video_W_H withVideoWidthPX:(CGFloat)videoWidthPX
{
    return CGSizeMake(videoWidthPX, videoWidthPX/video_W_H);
}

+ (NSArray *)gradualColors
{
    return @[(__bridge id)[UIColor greenColor].CGColor,(__bridge id)[UIColor yellowColor].CGColor,];
}

+ (void)motionBlurView:(UIView *)superView
{
    superView.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.8];
    UIToolbar *bar = [UIToolbar new];
    [bar setBarStyle:UIBarStyleBlackTranslucent];
    bar.clipsToBounds = YES;
    [superView addSubview:bar];
    [bar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.top.bottom.equalTo(superView);
    }];
}

+ (void)showHinInfo:(NSString *)text inView:(UIView *)superView frame:(CGRect)frame timeLong:(NSTimeInterval)time
{
    __block UILabel *zoomLab = [[UILabel alloc] initWithFrame:frame];
    zoomLab.font = [UIFont boldSystemFontOfSize:15.0];
    zoomLab.text = text;
    zoomLab.textColor = [UIColor whiteColor];
    zoomLab.textAlignment = NSTextAlignmentCenter;
    [superView addSubview:zoomLab];
    [superView bringSubviewToFront:zoomLab];
    kz_dispatch_after(1.6, ^{
        [zoomLab removeFromSuperview];
    });
}

@end

@implementation PVideoModel

+ (instancetype)modelWithPath:(NSString *)videoPath thumPath:(NSString *)thumPath recordTime:(NSDate *)recordTime
{
    PVideoModel *model = [[PVideoModel alloc] init];
    model.videoAbsolutePath = videoPath;
    model.thumAbsolutePath = thumPath;
    model.recordTime = recordTime;
    return model;
}

@end



@implementation PVideoUtil

+ (BOOL)existVideo
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *nameList = [fileManager subpathsAtPath:[self getVideoPath]];
    return nameList.count > 0;
}

+ (NSMutableArray *)getVideoList
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSMutableArray *modelList = [NSMutableArray array];
    NSArray *nameList = [fileManager subpathsAtPath:[self getVideoPath]];
    for (NSString *name in nameList)
    {
        if ([name hasSuffix:@".JPG"])
        {
            PVideoModel *model = [[PVideoModel alloc] init];
            NSString *thumAbsolutePath = [[self getVideoPath] stringByAppendingPathComponent:name];
            model.thumAbsolutePath = thumAbsolutePath;
            
            NSString *totalVideoPath = [thumAbsolutePath stringByReplacingOccurrencesOfString:@"JPG" withString:@"MOV"];
            if ([fileManager fileExistsAtPath:totalVideoPath])
            {
                model.videoAbsolutePath = totalVideoPath;
            }
            NSString *timeString = [name substringToIndex:(name.length-4)];
            NSDateFormatter *dateformate = [[NSDateFormatter alloc]init];
            dateformate.dateFormat = @"yyyy-MM-dd_HH:mm:ss";
            NSDate *date = [dateformate dateFromString:timeString];
            model.recordTime = date;
            
            [modelList addObject:model];
        }
    }
    return modelList;
}

+ (NSArray *)getSortVideoList
{
    NSArray *oldList = [self getVideoList];
    NSArray *sortList = [oldList sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        PVideoModel *model1 = obj1;
        PVideoModel *model2 = obj2;
        NSComparisonResult compare = [model1.recordTime compare:model2.recordTime];
        switch (compare)
        {
            case NSOrderedDescending:
                return NSOrderedAscending;
            case NSOrderedAscending:
                return NSOrderedDescending;
            default:
                return compare;
        }
    }];
    return sortList;
}

+ (void)saveThumImageWithVideoURL:(NSURL *)videoUrl second:(int64_t)second
{
    AVURLAsset *urlSet = [AVURLAsset assetWithURL:videoUrl];
    AVAssetImageGenerator *imageGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:urlSet];
    
    CMTime time = CMTimeMake(second, 10);
    NSError *error = nil;
    CGImageRef cgimage = [imageGenerator copyCGImageAtTime:time actualTime:nil error:&error];
    if (error) {
        NSLog(@"缩略图获取失败!:%@",error);
        return;
    }
    UIImage *image = [UIImage imageWithCGImage:cgimage scale:0.6 orientation:UIImageOrientationRight];
    NSData *imgData = UIImageJPEGRepresentation(image, 1.0);
    NSString *videoPath = [videoUrl.absoluteString stringByReplacingOccurrencesOfString:@"file://" withString: @""];
    NSString *thumPath = [videoPath stringByReplacingOccurrencesOfString:@"MOV" withString: @"JPG"];
    BOOL isok = [imgData writeToFile:thumPath atomically: YES];
    NSLog(@"缩略图获取结果:%d",isok);
    CGImageRelease(cgimage);
}

+ (PVideoModel *)createNewVideo
{
    NSDate *currentDate = [NSDate date];
    NSDateFormatter *formate = [[NSDateFormatter alloc] init];
    formate.dateFormat = @"yyyy-MM-dd_HH:mm:ss";
    NSString *videoName = [formate stringFromDate:currentDate];
    NSString *videoPath = [self getVideoPath];
    
    PVideoModel *model = [[PVideoModel alloc] init];
    model.videoAbsolutePath = [videoPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.MOV",videoName]];
    model.thumAbsolutePath = [videoPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.JPG",videoName]];
    model.recordTime = currentDate;
    return model;
}

+ (void)deleteVideo:(NSString *)videoPath
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;
    [fileManager removeItemAtPath:videoPath error:&error];
    if (error)
    {
        NSLog(@"删除视频失败:%@",error);
    }
    NSString *thumPath = [videoPath stringByReplacingOccurrencesOfString:@"MOV" withString:@"JPG"];
    NSError *error2 = nil;
    [fileManager removeItemAtPath:thumPath error:&error2];
    if (error2)
    {
        NSLog(@"删除缩略图失败:%@",error);
    }
}

+ (NSString *)getVideoPath
{
    return [self getDocumentSubPath:kVideoDicName];
}

+ (NSString *)getDocumentSubPath:(NSString *)dirName
{
    NSString *documentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentationDirectory, NSUserDomainMask, YES) firstObject];
    return [documentPath stringByAppendingPathComponent:dirName];
}

+ (void)initialize
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *dirPath = [self getVideoPath];
    
    NSError *error = nil;
    [fileManager createDirectoryAtPath:dirPath withIntermediateDirectories:YES attributes:nil error:&error];
    if (error)
    {
        NSLog(@"创建文件夹失败:%@",error);
    }
}

@end
