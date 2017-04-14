//
//  CEMovieMakerViewController.m
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
#import "CEMovieMakerViewController.h"
#import "CEMovieMaker.h"

@interface CEMovieMakerViewController ()

@end

@implementation CEMovieMakerViewController

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
    [self createCenterBtn:@"开始图片转换视频" posY:200 func:@selector(startCreateMovie)];
}

#pragma mark - Gesture handler

- (void)closeViewController
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Base UI functions

- (void)createDescText
{
    UILabel *descLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 170)];
    descLabel.backgroundColor = [UIColor blackColor];
    descLabel.textAlignment = NSTextAlignmentLeft;
    descLabel.numberOfLines = 0;
    descLabel.textColor = [UIColor redColor];
    descLabel.text = @"cameronehrlich的CEMovieMaker的代码，整合到这里是方便参考，github地址:\nhttps://github.com/cameronehrlich/CEMovieMaker\n功能就是将若干张图片转换成一个视频，每一张图片占用一帧，然后这几张图片不停地切换。";
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

#pragma mark - 入口函数

- (void)startCreateMovie
{
    // 要生成视频的图片
    NSMutableArray *frames = [[NSMutableArray alloc] init];
    UIImage *icon1 = [UIImage imageNamed:@"image1.jpg"];
    UIImage *icon2 = [UIImage imageNamed:@"image2.jpg"];
    UIImage *icon3 = [UIImage imageNamed:@"image3.jpg"];
    for (NSInteger i = 0; i < 10; i++) {
        [frames addObject:icon1];
        [frames addObject:icon2];
        [frames addObject:icon3];
    }
    
    // 设置生成视频的格式
    NSDictionary *settings = [CEMovieMaker videoSettingsWithCodec:AVVideoCodecH264 withWidth:icon1.size.width andHeight:icon1.size.height];
    
    
    CEMovieMaker *movieMaker = [[CEMovieMaker alloc] initWithSettings:settings];
    
    [movieMaker createMovieFromImages:[frames copy] withCompletion:^(NSURL *fileURL){
        [self viewMovieAtUrl:fileURL];
    }];
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


