//
//  TBCBaseImageVideoMaker.m
//  ImgsToVideoMaker
//
//  Created by zf on 17/4/11.
//  Copyright © 2017年 baidu. All rights reserved.
//
#import <MediaPlayer/MediaPlayer.h>
#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>
#import <CoreVideo/CoreVideo.h>
#import <CoreGraphics/CoreGraphics.h>
#import <AVFoundation/AVFoundation.h>
#import <QuartzCore/QuartzCore.h>
#import "TBCBaseImageVideoMaker.h"

// 每个单独视频的长度默认值
#define kEachImageVideoDefaultDuration (2.5f)

// 最终生成的视频的宽高
#define kFinalVideoDefaultWidth (750.0f)
#define kFinalVideoDefaultHeight (1334.0f)

// 临时生成的视频文件名的头
#define kEachTempImageVideoHeader @"imgVideoTempFile"
// 最后混合的视频文件名
#define kFinalMixVideoFileName @"baseMixVideoFile.mp4"

@interface TBCBaseImageVideoMaker ()

// 当前是否正在创建中的标志位
@property (nonatomic, assign) BOOL isProcessVideo;

// 需要转换成视频的图片数组，可能是本地图片，也可能是网络图片
@property (nonatomic, strong) NSArray *imagesList;
// 图片数组类型
@property (nonatomic, assign) TBCVideoImageType sourceImgType;

// 每个生成的视频的设置
@property (nonatomic, strong) NSDictionary *videoSettings;

// 当前创建完成的临时视频的数量
@property (nonatomic, assign) NSInteger tempVideoCreateSum;
// 每个图片生成的临时视频的路径
@property (nonatomic, strong) NSMutableArray *tempVideosList;

// 视频转换完成的回调
@property (nonatomic, strong) TBCImageVideoMakerCompletion completionBlock;

@end

@implementation TBCBaseImageVideoMaker

#pragma mark - 初始化函数 && dealloc

- (void)dealloc
{
    
}

- (instancetype)initWithImages:(NSArray *)imgs andType:(TBCVideoImageType)type
{
    self = [super init];
    if (self)
    {
        self.isProcessVideo = NO;
        self.tempVideoCreateSum = 0;
        
        self.imagesList = imgs;
        self.sourceImgType = type;
        self.eachVideoDuration = kEachImageVideoDefaultDuration;
        
        self.tempVideosList = [[NSMutableArray alloc] init];
    }
    
    return self;
}

#pragma mark - 图片转换成视频的具体实现函数

// 设置生成视频的格式
- (void)createVideoMakeSetting
{
    if (self.videoSettings != nil)
    {
        return;
    }
    
    int videoWidth = kFinalVideoDefaultWidth;
    int videoHeigth = kFinalVideoDefaultHeight;
    if (self.sourceImgType == TBCVideoImageType_Local)
    {
        UIImage *firstImg = (UIImage *)[self.imagesList objectAtIndex:0];
        if (firstImg != nil && [firstImg isKindOfClass:[UIImage class]])
        {
            videoWidth = firstImg.size.width;
            videoHeigth = firstImg.size.height;
        }
    }
    
    self.videoSettings = @{AVVideoCodecKey : AVVideoCodecH264,
                           AVVideoWidthKey : [NSNumber numberWithInt:videoWidth],
                           AVVideoHeightKey : [NSNumber numberWithInt:videoHeigth]};
}

// 根据图片获取CVPixelBufferRef
- (CVPixelBufferRef)newPixelBufferFromCGImage:(CGImageRef)image
{
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey, [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey, nil];
    
    CVPixelBufferRef pxbuffer = NULL;
    
    CGFloat frameWidth = [[self.videoSettings objectForKey:AVVideoWidthKey] floatValue];
    CGFloat frameHeight = [[self.videoSettings objectForKey:AVVideoHeightKey] floatValue];
    
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault,
                                          frameWidth,
                                          frameHeight,
                                          kCVPixelFormatType_32ARGB,
                                          (__bridge CFDictionaryRef) options,
                                          &pxbuffer);
    
    if (status != kCVReturnSuccess || pxbuffer == NULL)
    {
        return NULL;
    }
    
    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    if (pxdata == NULL)
    {
        return NULL;
    }
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    
    CGContextRef context = CGBitmapContextCreate(pxdata,
                                                 frameWidth,
                                                 frameHeight,
                                                 8,
                                                 4 * frameWidth,
                                                 rgbColorSpace,
                                                 (CGBitmapInfo)kCGImageAlphaNoneSkipFirst);
    if (context == NULL)
    {
        return NULL;
    }
    
    CGContextConcatCTM(context, CGAffineTransformIdentity);
    CGContextDrawImage(context, CGRectMake(0, 0, CGImageGetWidth(image), CGImageGetHeight(image)), image);
    
    CGContextRelease(context);
    CGColorSpaceRelease(rgbColorSpace);
    
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    
    return pxbuffer;
}

- (NSURL *)getTempVideoFullPathByIndex:(NSInteger)index forceDel:(BOOL)delete
{
    NSString *tempVideoFileName = [NSString stringWithFormat:@"%@%ld.mp4", kEachTempImageVideoHeader, (long)index];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths firstObject];
    NSString *tempPath = [documentsDirectory stringByAppendingFormat:@"/%@", tempVideoFileName];
    
    if (delete && [[NSFileManager defaultManager] fileExistsAtPath:tempPath])
    {
        NSError *error;
        [[NSFileManager defaultManager] removeItemAtPath:tempPath error:&error];
        if (error)
        {
            return nil;
        }
    }
    
    NSURL *tempFileURL = [NSURL fileURLWithPath:tempPath];

    return tempFileURL;
}

- (UIImage *)getCurrentImageByIndex:(NSInteger)index
{
    if (index < 0 || index > [self.imagesList count])
    {
        return nil;
    }
    
    UIImage *img = [self.imagesList objectAtIndex:index];
    if (self.sourceImgType == TBCVideoImageType_Network)
    {
        img = [UIImage imageWithData: [NSData dataWithContentsOfURL:((NSURL*)img)]];
    }

    if (![img isKindOfClass:[UIImage class]])
    {
        return nil;
    }
    
    return img;
}

// 生成的视频每秒的帧数
- (NSInteger)getVideoFrameNumPerSecond
{
    return 30;
}

// 每个生成临时视频的总帧数
- (NSInteger)getTempVideoTotalFrame
{
    // 总数 = 时长 * 每秒的帧数
    NSInteger fps = [self getVideoFrameNumPerSecond];
    NSInteger totalFrames = fps * self.eachVideoDuration;
    
    return totalFrames;
}

// 根据当前的输入生成序号生成视频
- (BOOL)createVideoFromImageByIndex:(NSInteger)index
{
    UIImage *srcImg = [self getCurrentImageByIndex:index];
    if (srcImg == nil)
    {
        return NO;
    }
    
    NSURL *tempVideoFileUrl = [self getTempVideoFullPathByIndex:index forceDel:YES];
    if (tempVideoFileUrl == nil)
    {
        return NO;
    }
    
    // 初始化 AVAssetWriter
    NSError *error;
    AVAssetWriter *assetWriter = [[AVAssetWriter alloc] initWithURL:tempVideoFileUrl fileType:AVFileTypeQuickTimeMovie error:&error];
    if (error || assetWriter == nil)
    {
        return NO;
    }

    // 初始化 AVAssetWriterInput
    AVAssetWriterInput *writerInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:self.videoSettings];
    if (writerInput == nil)
    {
        return NO;
    }

    if (![assetWriter canAddInput:writerInput])
    {
        return NO;
    }
    [assetWriter addInput:writerInput];

    // 初始化 AVAssetWriterInputPixelBufferAdaptor
    AVAssetWriterInputPixelBufferAdaptor *bufferAdapter = [[AVAssetWriterInputPixelBufferAdaptor alloc] initWithAssetWriterInput:writerInput sourcePixelBufferAttributes:nil];
    
    // 开始创建
    [assetWriter startWriting];
    [assetWriter startSessionAtSourceTime:kCMTimeZero];
    
    // 生成视频的fps
    NSInteger fps = [self getVideoFrameNumPerSecond];
    // 当前视频的总帧数
    NSInteger totalFrames = [self getTempVideoTotalFrame];
    
    dispatch_queue_t mediaInputQueue = dispatch_queue_create("mediaInputQueue", NULL);
    [writerInput requestMediaDataWhenReadyOnQueue:mediaInputQueue usingBlock:^{
        
        // 每一个视频需要添加两帧，第一帧和最后一帧
        NSInteger maxFrameCount = 2;
        NSInteger currentFrameCount = 0;
        while (currentFrameCount < maxFrameCount)
        {
            if ([writerInput isReadyForMoreMediaData])
            {
                CVPixelBufferRef sampleBuffer;
                @autoreleasepool
                {
                    sampleBuffer = [self newPixelBufferFromCGImage:[srcImg CGImage]];
                }

                if (sampleBuffer)
                {
                    // CMTimeMake(a,b)    a当前第几帧, b每秒钟多少帧.当前播放时间a/b
                    CMTime frameTime = CMTimeMake(currentFrameCount * totalFrames / 2, (int32_t)fps);
                    [bufferAdapter appendPixelBuffer:sampleBuffer withPresentationTime:frameTime];
                    
                    CFRelease(sampleBuffer);
                }
                
                currentFrameCount++;
            }
        }
        
        // 创建结束
        [writerInput markAsFinished];
        [assetWriter finishWritingWithCompletionHandler:^{
            self.tempVideoCreateSum++;
            [self startMixAllVideosIfFinish];
        }];
        
        CVPixelBufferPoolRelease(bufferAdapter.pixelBufferPool);
    }];
    
    [self.tempVideosList addObject:tempVideoFileUrl];
    
    return YES;
}

#pragma mark - 混合视频相关函数

- (NSURL *)checkFinalMixVideoPath
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths firstObject];
    NSString *videoOutputPath = [documentsDirectory stringByAppendingFormat:@"/%@", kFinalMixVideoFileName];
    
    NSURL *videoOutputURL = [NSURL fileURLWithPath:videoOutputPath];
    
    return videoOutputURL;
}

// 混合所有视频，生成不同效果的视频，子类可以根据自己的要求重载
- (BOOL)mixVideosAndAudio
{
    if ([self.tempVideosList count] <= 0)
    {
        // 没有输入的视频文件，直接退出
        return NO;
    }
    
    // 获取视频的size
    CGFloat frameWidth = [[self.videoSettings objectForKey:AVVideoWidthKey] floatValue];
    CGFloat frameHeight = [[self.videoSettings objectForKey:AVVideoHeightKey] floatValue];
    
    // 创建混合视频和音频的 AVMutableComposition
    AVMutableComposition *mixComposition = [AVMutableComposition composition];
    
    // 所有的视频都插入到一个轨道中
    AVMutableCompositionTrack *compositionVideoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    
    // 视频操作指令集合
    NSMutableArray *videoInstructions = [NSMutableArray new];
    // 记录当前视频的起始时间
    CMTime nextClipStartTime = kCMTimeZero;
    
    // ######################## 依次混合每个视频 ########################
    for (int i = 0; i < [self.tempVideosList count]; i++)
    {
        // ****************** 1. 获取视频资源 ******************
        NSURL *tempVideoURL = (NSURL *)[self.tempVideosList objectAtIndex:i];
        AVURLAsset* videoAsset = [[AVURLAsset alloc] initWithURL:tempVideoURL options:nil];
        // 获取视频的时间范围
        CMTimeRange timeRangeInAsset = CMTimeRangeMake(kCMTimeZero, [videoAsset duration]);
        
        // ****************** 2. 将每个视频插入到轨道中 ******************
        AVAssetTrack *videoAssetTrack = [[videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
        // 将当前视频插入到混合的视频的轨道中
        [compositionVideoTrack insertTimeRange:timeRangeInAsset ofTrack:videoAssetTrack atTime:nextClipStartTime error:nil];
        
        // ****************** 3. 为当前视频创建视频轨道操作指令 ******************
        AVMutableVideoCompositionLayerInstruction *videoCompositionLayerIns = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:compositionVideoTrack];
        
        // 计算当前视频的时间跨度
        CMTimeRange currentVideoTimeRange = CMTimeRangeMake(nextClipStartTime, timeRangeInAsset.duration);
        
        // 设置透明度动画
        [videoCompositionLayerIns setOpacityRampFromStartOpacity:1.0 toEndOpacity:0.6 timeRange:currentVideoTimeRange];

        // 设置尺寸动画
//        CGAffineTransform startTransform = CGAffineTransformScale(videoAssetTrack.preferredTransform, 1.5, 1.5);
//        CGAffineTransform endTransform = CGAffineTransformScale(videoAssetTrack.preferredTransform, 1.0, 1.0);
        
        CMTime moveEndDuration = CMTimeMake(videoAsset.duration.value / 2, videoAsset.duration.timescale);
        CMTimeRange moveVideoTimeRange = CMTimeRangeMake(nextClipStartTime, moveEndDuration);
        CGAffineTransform startTransform = CGAffineTransformTranslate(videoAssetTrack.preferredTransform, -frameWidth, 0.0);
        CGAffineTransform endTransform = CGAffineTransformTranslate(videoAssetTrack.preferredTransform, 0.0, 0.0);
        [videoCompositionLayerIns setTransformRampFromStartTransform:startTransform toEndTransform:endTransform timeRange:moveVideoTimeRange];
        
        
        // ****************** 4. 将视频轨道操作指令放到视频指令中去 ******************
        AVMutableVideoCompositionInstruction *videoCompositionInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
        videoCompositionInstruction.timeRange = currentVideoTimeRange;
        videoCompositionInstruction.layerInstructions = [NSArray arrayWithObjects:videoCompositionLayerIns, nil];

        // ****************** 5. 将新的视频指令添加到指令集合中去 ******************
        [videoInstructions addObject:videoCompositionInstruction];
        
        // ****************** 6. 最后，增加起始时间，为下次插入做准备 ******************
        nextClipStartTime = CMTimeAdd(nextClipStartTime, videoAsset.duration);
        
    }
    
    // 创建 AVMutableVideoComposition
    AVMutableVideoComposition *videoComposition = [AVMutableVideoComposition videoComposition];
    videoComposition.instructions = videoInstructions;
    videoComposition.renderSize = CGSizeMake(frameWidth, frameHeight);
    videoComposition.frameDuration = CMTimeMake(1, 30);
    
    // 获取混合后的输出URL
    NSURL *outputFileUrl = [self checkFinalMixVideoPath];
    if (outputFileUrl == nil)
    {
        return NO;
    }
    // 如果原有文件，则删除
    [[NSFileManager defaultManager] removeItemAtURL:outputFileUrl error:nil];
    
    // 输出混合视频到文件
    AVAssetExportSession* assetExport = [[AVAssetExportSession alloc] initWithAsset:mixComposition presetName:AVAssetExportPresetHighestQuality];
    assetExport.outputFileType = AVFileTypeQuickTimeMovie;
    assetExport.outputURL = outputFileUrl;
    assetExport.videoComposition = videoComposition;
    
    [assetExport exportAsynchronouslyWithCompletionHandler:^{
        
        // 混合完成，执行后续操作
        [self finishMixVideo];
        
    }];
    
    return YES;
}

- (void)deleteAllTempVideoFiles
{
    for (NSURL *tempVideoUrl in self.tempVideosList)
    {
        if (tempVideoUrl == nil || ![tempVideoUrl isKindOfClass:[NSURL class]])
        {
            continue;
        }
        
        [[NSFileManager defaultManager] removeItemAtURL:tempVideoUrl error:nil];
    }
    [self.tempVideosList removeAllObjects];
}

- (void)finishMixVideo
{
    // 删除临时生成的视频文件
    [self deleteAllTempVideoFiles];
    
    // 最终的视频生成完毕，执行回调
    NSURL *mixVideoUrl = [self checkFinalMixVideoPath];
    if (self.completionBlock)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.completionBlock(mixVideoUrl);
        });
    }
    
    self.isProcessVideo = NO;
}

#pragma mark - 视频转换的辅助函数

- (void)createAllVideoByImages
{
    self.tempVideoCreateSum = 0;
    
    // 设置生成视频的格式
    [self createVideoMakeSetting];
    
    // 遍历图片数组，每个生成单独的视频
    for (int i = 0; i < [self.imagesList count]; i++)
    {
        [self createVideoFromImageByIndex:i];
    }
}

- (void)startCreateVideo:(TBCImageVideoMakerCompletion)completeBlock
{
//    [self mixTest];
//    return;
    
    if (self.isProcessVideo)
    {
        return;
    }
    
    if ([self.imagesList count] <= 0)
    {
        return;
    }
    
    self.isProcessVideo = YES;
    
    self.completionBlock = completeBlock;
    
    // 将每张图片都转换成单独的视频
    [self createAllVideoByImages];
}

// 混合各个视频
- (void)startMixAllVideosIfFinish
{
    if (self.tempVideoCreateSum < [self.tempVideosList count])
    {
        // 根据图片生成的视频还有未完成，返回
        return;
    }
    
    // 所有根据图片生成的视频已经完成，开始混合各个视频
    BOOL mixResult = [self mixVideosAndAudio];
    if (!mixResult)
    {
        // 如果混合失败，退出前删除临时文件
        [self deleteAllTempVideoFiles];
        
        self.isProcessVideo = NO;
    }
}

@end
