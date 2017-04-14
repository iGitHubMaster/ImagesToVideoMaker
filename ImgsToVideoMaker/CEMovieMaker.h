//
//  CEMovieMaker.h
//  ImgsToVideoMaker
//
//  Created by zf on 17/4/10.
//  Copyright © 2017年 baidu. All rights reserved.
//

@import AVFoundation;
@import Foundation;
@import UIKit;

typedef void(^CEMovieMakerCompletion)(NSURL *fileURL);

@interface CEMovieMaker : NSObject

- (instancetype)initWithSettings:(NSDictionary *)videoSettings;
- (void)createMovieFromImageURLs:(NSArray *)urls withCompletion:(CEMovieMakerCompletion)completion;
- (void)createMovieFromImages:(NSArray *)images withCompletion:(CEMovieMakerCompletion)completion;

+ (NSDictionary *)videoSettingsWithCodec:(NSString *)codec withWidth:(CGFloat)width andHeight:(CGFloat)height;

@end
