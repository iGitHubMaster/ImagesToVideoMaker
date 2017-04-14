//
//  ViewController.m
//  ImgsToVideoMaker
//
//  Created by zf on 17/4/7.
//  Copyright © 2017年 baidu. All rights reserved.
//

#import "ViewController.h"
#import "ImgToVideoViewController.h"
#import "CEMovieMakerViewController.h"
#import "TBCVideoMakerViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self createCenterBtn:@"图片转成视频并且混合音频" posY:40 func:@selector(showImgToVideoViewController)];
    
    [self createCenterBtn:@"仅图片转视频" posY:140 func:@selector(showMoiveMakeViewController)];
    
    [self createCenterBtn:@"自定义的图片转视频，带动画切换" posY:240 func:@selector(showTBCMoiveMakeViewController)];
}

#pragma mark - Buttons

- (UIButton *)createCenterBtn:(NSString *)title posY:(NSInteger)y func:(SEL)selFunc
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.frame = CGRectMake(0, y, self.view.frame.size.width, 20);
    [button setTitle:title forState:UIControlStateNormal];
    [self.view addSubview:button];
    
    [button addTarget:self action:selFunc forControlEvents:UIControlEventTouchUpInside];
    
    return button;
}

#pragma mark - Show viewController

- (void)showImgToVideoViewController
{
    ImgToVideoViewController *vc = [ImgToVideoViewController new];
    [self presentViewController:vc animated:YES completion:nil];
}

- (void)showMoiveMakeViewController
{
    CEMovieMakerViewController *vc = [CEMovieMakerViewController new];
    [self presentViewController:vc animated:YES completion:nil];
}

- (void)showTBCMoiveMakeViewController
{
    TBCVideoMakerViewController *vc = [TBCVideoMakerViewController new];
    [self presentViewController:vc animated:YES completion:nil];
}

@end
