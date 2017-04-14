//
//  ImgToVideoViewController.m
//  ImgsToVideoMaker
//
//  Created by zf on 17/4/7.
//  Copyright © 2017年 baidu. All rights reserved.
//

#import <MediaPlayer/MPMoviePlayerViewController.h>
#import <MediaPlayer/MediaPlayer.h>
#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>
#import <CoreVideo/CoreVideo.h>
#import <CoreGraphics/CoreGraphics.h>
#import <AVFoundation/AVFoundation.h>
#import <QuartzCore/QuartzCore.h>
#import "ImgToVideoViewController.h"

#define TEMP_IMAGES_VIDEO_FILENAME @"test_output.mp4"
#define FINAL_MIX_VIDEO_FILENAME @"final_video.mp4"

@interface ImgToVideoViewController ()

@end

@implementation ImgToVideoViewController

- (void)dealloc
{
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UITapGestureRecognizer *tapGes = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(closeViewController)];
    [self.view addGestureRecognizer:tapGes];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self createDescText];
    [self createCenterBtn:@"开始图片转视频" posY:200 func:@selector(startCreateMovie)];
}

#pragma mark - Base UI functions

- (void)createDescText
{
    UILabel *descLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 150)];
    descLabel.backgroundColor = [UIColor blackColor];
    descLabel.textAlignment = NSTextAlignmentLeft;
    descLabel.numberOfLines = 0;
    descLabel.textColor = [UIColor redColor];
    descLabel.text = @"caferrara的代码，整合到这里是方便参考，github地址:\nhttps://github.com/caferrara/img-to-video\n功能就是将若干张图片转换成一个视频，每一张图片占用一段时间。";
    [self.view addSubview:descLabel];
}

- (UIButton *)createCenterBtn:(NSString *)title posY:(NSInteger)y func:(SEL)selFunc
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.frame = CGRectMake(0, y, self.view.frame.size.width, 20);
    [button setTitle:title forState:UIControlStateNormal];
    [self.view addSubview:button];
    
    [button addTarget:self action:selFunc forControlEvents:UIControlEventTouchUpInside];
    
    return button;
}


#pragma mark - Gesture handler

- (void)closeViewController
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - 基础函数

// CGImage to CVPixelBufferRef
- (CVPixelBufferRef)pixelBufferFromCGImage:(CGImageRef)image
{
    CGSize size = CGSizeMake(400, 200);
    
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey, [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey, nil];
    
    // Create CVPixelBufferRef
    CVPixelBufferRef pxbuffer = NULL;
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault,
                                          size.width,
                                          size.height,
                                          kCVPixelFormatType_32ARGB,
                                          (__bridge CFDictionaryRef) options,
                                          &pxbuffer);
    
    if (status != kCVReturnSuccess)
    {
        NSLog(@"Failed to create pixel buffer");
    }
    
    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pxdata, size.width, size.height, 8, 4*size.width, rgbColorSpace, kCGImageAlphaPremultipliedFirst);
    
    CGContextConcatCTM(context, CGAffineTransformMakeRotation(0));
    CGContextDrawImage(context, CGRectMake(0, 0, CGImageGetWidth(image), CGImageGetHeight(image)), image);
    
    CGContextRelease(context);
    CGColorSpaceRelease(rgbColorSpace);
    
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    
    return pxbuffer;
}

- (NSString *)getFileFullPathByFileName:(NSString *)name
{
    NSString *documentsDirectory = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
    NSString *videoOutputPath = [documentsDirectory stringByAppendingPathComponent:name];
    
    NSError *error = nil;
    
    return videoOutputPath;
}

- (NSString *)getTempImagesVideoPath
{
    NSString *videoOutputPath = [self getFileFullPathByFileName:TEMP_IMAGES_VIDEO_FILENAME];
    
    return videoOutputPath;
}

- (NSString *)getFinalMixVideoPath
{
    NSString *videoOutputPath = [self getFileFullPathByFileName:FINAL_MIX_VIDEO_FILENAME];
    
    return videoOutputPath;
}

#pragma mark - Movie Maker abouts

// 图片组转成视频
- (void)startCreateMovie
{
    // 获取文件保存位置
    NSString *videoOutputPath = [self getTempImagesVideoPath];
    [[NSFileManager defaultManager] removeItemAtPath:videoOutputPath error:nil];
    
    // 读取所有图片
    NSArray* imagePaths = [[NSBundle mainBundle] pathsForResourcesOfType:@"jpg" inDirectory:nil];
    NSMutableArray *imageArray = [[NSMutableArray alloc] initWithCapacity:imagePaths.count];
    for (NSString* path in imagePaths)
    {
        [imageArray addObject:[UIImage imageWithContentsOfFile:path]];
        break;
    }
    
    // 设置video的输出格式相关
    CGSize imageSize = CGSizeMake(400, 200);
    
    NSDictionary *videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:AVVideoCodecH264, AVVideoCodecKey, [NSNumber numberWithInt:imageSize.width], AVVideoWidthKey, [NSNumber numberWithInt:imageSize.height],  AVVideoHeightKey, nil];
    
    AVAssetWriterInput* videoWriterInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoSettings];
    
    AVAssetWriterInputPixelBufferAdaptor *adaptor =  [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:videoWriterInput sourcePixelBufferAttributes:nil];
    
    NSParameterAssert(videoWriterInput);
    videoWriterInput.expectsMediaDataInRealTime = YES;
    
    // 生成video writer
    NSError *error = nil;
    AVAssetWriter *videoWriter = [[AVAssetWriter alloc] initWithURL:[NSURL fileURLWithPath:videoOutputPath] fileType:AVFileTypeQuickTimeMovie error:&error];
    NSParameterAssert(videoWriter);
    
    // 将video的设置绑定到video writer中
    NSParameterAssert([videoWriter canAddInput:videoWriterInput]);
    [videoWriter addInput:videoWriterInput];
    
    //Start a session:
    NSLog(@"======== Write Start!!!");
    [videoWriter startWriting];
    [videoWriter startSessionAtSourceTime:kCMTimeZero];
    
    // 计算帧数
    NSUInteger fps = 30;
    int frameCount = 0;
    double numberOfSecondsPerFrame = 6;
    double frameDuration = fps * numberOfSecondsPerFrame;
    
    CVPixelBufferRef buffer = NULL;
    
    // Convert uiimage to CGImage.
    NSLog(@"**************************************************");
    for(UIImage * img in imageArray)
    {
        buffer = [self pixelBufferFromCGImage:[img CGImage]];

        BOOL append_ok = NO;
        int j = 0;
        while (!append_ok && j < 30)
        {
            if (adaptor.assetWriterInput.readyForMoreMediaData)
            {
                // 将每一帧图片生成的buffer添加到视频相应的位置
                
                //print out status:
                NSLog(@"Processing video frame (%d, %lu)", frameCount, (unsigned long)[imageArray count]);

                // CMTimeMake(a,b)    a当前第几帧, b每秒钟多少帧.当前播放时间a/b
                CMTime frameTime = CMTimeMake(frameCount * frameDuration, (int32_t) fps);
                append_ok = [adaptor appendPixelBuffer:buffer withPresentationTime:frameTime];
                if(!append_ok)
                {
                    NSError *error = videoWriter.error;
                    if (error!=nil)
                    {
                        NSLog(@"Unresolved error %@,%@.", error, [error userInfo]);
                    }
                }
            }
            else
            {
                // 现在还不能添加，进行等待
                printf("adaptor not ready %d, %d\n", frameCount, j);
                [NSThread sleepForTimeInterval:0.1];
            }
            j++;
        }
        
        if (!append_ok)
        {
            // 添加失败，记录log
            printf("error appending image %d times %d\n, with error.", frameCount, j);
        }
      
        // 增加frame计数
        frameCount++;
    }
    NSLog(@"**************************************************");

    //Finish the session:
    [videoWriterInput markAsFinished];
    [videoWriter finishWritingWithCompletionHandler:^{
        [self mixVideoAndAudio];
    }];
}

// 视频和音频混合
- (void)mixVideoAndAudio
{
    NSString *bundleDirectory = [[NSBundle mainBundle] bundlePath];
    
    // 获取音频URL
    NSString *audio_inputFilePath = [bundleDirectory stringByAppendingPathComponent:@"30secs.mp3"];
    NSURL *audio_inputFileUrl = [NSURL fileURLWithPath:audio_inputFilePath];
    
    // 获取视频URL
    NSURL *video_inputFileUrl = [NSURL fileURLWithPath:[self getTempImagesVideoPath]];
    
    // 混合视频和音频
    AVMutableComposition* mixComposition = [AVMutableComposition composition];
    
    // 获取混合后的输出路径
    NSString *outputFilePath = [self getFinalMixVideoPath];
    [[NSFileManager defaultManager] removeItemAtPath:outputFilePath error:nil];
    
    NSURL *outputFileUrl = [NSURL fileURLWithPath:outputFilePath];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:outputFilePath])
    {
        [[NSFileManager defaultManager] removeItemAtPath:outputFilePath error:nil];
    }
    
    CMTime nextClipStartTime = kCMTimeZero;
    
    AVURLAsset* videoAsset = [[AVURLAsset alloc]initWithURL:video_inputFileUrl options:nil];
    CMTimeRange video_timeRange = CMTimeRangeMake(kCMTimeZero, videoAsset.duration);
    AVMutableCompositionTrack *a_compositionVideoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    [a_compositionVideoTrack insertTimeRange:video_timeRange ofTrack:[[videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] atTime:nextClipStartTime error:nil];
    
    AVURLAsset* audioAsset = [[AVURLAsset alloc]initWithURL:audio_inputFileUrl options:nil];
    CMTimeRange audio_timeRange = CMTimeRangeMake(kCMTimeZero, audioAsset.duration);
    AVMutableCompositionTrack *b_compositionAudioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    [b_compositionAudioTrack insertTimeRange:audio_timeRange ofTrack:[[audioAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0] atTime:nextClipStartTime error:nil];
    
    AVAssetExportSession* _assetExport = [[AVAssetExportSession alloc] initWithAsset:mixComposition presetName:AVAssetExportPresetHighestQuality];
    _assetExport.outputFileType = @"public.mpeg-4";
    _assetExport.outputURL = outputFileUrl;
    
    [_assetExport exportAsynchronouslyWithCompletionHandler:^{
        NSLog(@"###### 合并完成!!!!");
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self viewMovieAtUrl:outputFileUrl];
        });
    }];
    
    ///// THAT IS IT DONE... the final video file will be written here...
    NSLog(@"------------ DONE ------------");
    NSLog(@"%@", outputFilePath);
}

- (void)viewMovieAtUrl:(NSURL *)fileURL
{
    MPMoviePlayerViewController *playerController = [[MPMoviePlayerViewController alloc] initWithContentURL:fileURL];
    [playerController.view setFrame:self.view.bounds];
    
    [self presentMoviePlayerViewControllerAnimated:playerController];
    [playerController.moviePlayer prepareToPlay];
    [playerController.moviePlayer play];
}

@end

