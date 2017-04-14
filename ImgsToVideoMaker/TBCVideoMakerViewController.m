//
//  TBCVideoMakerViewController.m
//  ImgsToVideoMaker
//
//  Created by zf on 17/4/11.
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
#import "TBCVideoMakerViewController.h"
#import "TBCBaseImageVideoMaker.h"

@interface TBCVideoMakerViewController ()

@end

@implementation TBCVideoMakerViewController

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
    [self createCenterBtn:@"图片转成基础动画视频" posY:200 func:@selector(startCreateBaseMovie)];
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
    descLabel.text = @"使用TBCBaseImageVideoMaker类，实现图片转成视频的功能。\n比起前面的第三方库，这里每一张图片生成一个单独的视频，然后多个视频进行混合的时候，增加了过场动画！动画可以各种修改，也可以进行个各种自定义动画，可以在子类中重载进行修改！";
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

- (void)startCreateBaseMovie
{
    // 要生成视频的图片
    NSMutableArray *frames = [[NSMutableArray alloc] init];
    UIImage *icon1 = [UIImage imageNamed:@"image1.jpg"];
    [frames addObject:icon1];
    UIImage *icon2 = [UIImage imageNamed:@"image2.jpg"];
    [frames addObject:icon2];
    UIImage *icon3 = [UIImage imageNamed:@"image3.jpg"];
    [frames addObject:icon3];

    TBCBaseImageVideoMaker *movieMaker = [[TBCBaseImageVideoMaker alloc] initWithImages:frames andType:TBCVideoImageType_Local];
    [movieMaker startCreateVideo:^(NSURL *fileURL) {
        [self viewMovieAtUrl:fileURL];
    }];
}

#pragma mark - 视频播放函数

- (void)viewMovieAtUrl:(NSURL *)fileURL
{
    MPMoviePlayerViewController *playerController = [[MPMoviePlayerViewController alloc] initWithContentURL:fileURL];
    [playerController.view setFrame:self.view.bounds];
    
    [self presentMoviePlayerViewControllerAnimated:playerController];
    [playerController.moviePlayer prepareToPlay];
    [playerController.moviePlayer play];
}



@end
